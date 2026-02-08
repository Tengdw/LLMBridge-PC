#!/bin/bash
# HTTP client for communicating with Windows agents

# Make HTTP request to agent
http_request() {
    local method="$1"
    local url="$2"
    local token="$3"
    local data="$4"
    local timeout="${5:-30}"

    local curl_opts=(
        -s
        -X "$method"
        -H "X-Auth-Token: $token"
        -H "Content-Type: application/json"
        --max-time "$timeout"
        --connect-timeout 5
    )

    if [ -n "$data" ]; then
        curl_opts+=(-d "$data")
    fi

    local response=$(curl "${curl_opts[@]}" "$url" 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "HTTP request failed (curl exit code: $exit_code)"
        return 1
    fi

    echo "$response"
    return 0
}

# Check if agent is reachable
check_agent() {
    local ip="$1"
    local port="$2"

    local url="http://${ip}:${port}/health"

    local response=$(curl -s --max-time 5 --connect-timeout 2 "$url" 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | jq -e '.status == "ok"' >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Execute command on remote PC
execute_command() {
    local alias="$1"
    local command="$2"
    local shell="${3:-cmd}"
    local timeout="${4:-30}"
    local config_file="$5"

    if ! parse_pc_config "$alias" "$config_file"; then
        return 1
    fi

    log_info "Executing command on $alias: $command"

    # Check if agent is reachable
    if ! check_agent "$PC_IP" "$AGENT_PORT"; then
        log_error "Agent not reachable at ${PC_IP}:${AGENT_PORT}"
        log_info "Try waking the PC first: /pc-control wake $alias"
        return 1
    fi

    local url="http://${PC_IP}:${AGENT_PORT}/api/v1/execute"
    local data=$(jq -n \
        --arg cmd "$command" \
        --arg sh "$shell" \
        --argjson to "$timeout" \
        '{command: $cmd, shell: $sh, timeout: $to}')

    local response=$(http_request "POST" "$url" "$AUTH_TOKEN" "$data" "$((timeout + 5))")

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Parse response
    local success=$(echo "$response" | jq -r '.success')

    if [ "$success" == "true" ]; then
        log_success "Command executed successfully"
        echo ""
        echo "=== Output ==="
        echo "$response" | jq -r '.stdout'

        local stderr=$(echo "$response" | jq -r '.stderr')
        if [ -n "$stderr" ] && [ "$stderr" != "null" ]; then
            echo ""
            echo "=== Errors ==="
            echo "$stderr"
        fi

        local exec_time=$(echo "$response" | jq -r '.execution_time')
        echo ""
        echo "Execution time: ${exec_time}s"
        return 0
    else
        log_error "Command execution failed"
        local error=$(echo "$response" | jq -r '.error // "Unknown error"')
        echo "Error: $error"
        return 1
    fi
}

# Get system information
get_system_info() {
    local alias="$1"
    local config_file="$2"

    if ! parse_pc_config "$alias" "$config_file"; then
        return 1
    fi

    log_info "Getting system info from $alias"

    if ! check_agent "$PC_IP" "$AGENT_PORT"; then
        log_error "Agent not reachable at ${PC_IP}:${AGENT_PORT}"
        return 1
    fi

    local url="http://${PC_IP}:${AGENT_PORT}/api/v1/info"
    local response=$(http_request "GET" "$url" "$AUTH_TOKEN" "" 10)

    if [ $? -ne 0 ]; then
        return 1
    fi

    echo ""
    echo "=== System Information for $alias ==="
    echo "Hostname:     $(echo "$response" | jq -r '.hostname')"
    echo "OS:           $(echo "$response" | jq -r '.os')"
    echo "CPU Count:    $(echo "$response" | jq -r '.cpu_count')"
    echo "Memory (MB):  $(echo "$response" | jq -r '.memory_total')"
    echo "IP Addresses: $(echo "$response" | jq -r '.ip_addresses | join(", ")')"
    echo "MAC Address:  $(echo "$response" | jq -r '.mac_address')"
    echo ""

    return 0
}

# Power operation
power_operation() {
    local alias="$1"
    local action="$2"
    local config_file="$3"

    if ! parse_pc_config "$alias" "$config_file"; then
        return 1
    fi

    log_info "Performing power operation on $alias: $action"

    if ! check_agent "$PC_IP" "$AGENT_PORT"; then
        log_error "Agent not reachable at ${PC_IP}:${AGENT_PORT}"
        return 1
    fi

    local url="http://${PC_IP}:${AGENT_PORT}/api/v1/power"
    local data=$(jq -n --arg act "$action" '{action: $act, delay: 0}')

    local response=$(http_request "POST" "$url" "$AUTH_TOKEN" "$data" 10)

    if [ $? -ne 0 ]; then
        return 1
    fi

    local success=$(echo "$response" | jq -r '.success')

    if [ "$success" == "true" ]; then
        log_success "Power operation initiated: $action"
        local message=$(echo "$response" | jq -r '.message')
        echo "$message"
        return 0
    else
        log_error "Power operation failed"
        return 1
    fi
}
