#!/bin/bash
# Configuration parser for pcs.md

# Parse PC configuration from MD file
parse_pc_config() {
    local alias="$1"
    local config_file="$2"

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Extract PC section (exact heading match; supports Chinese/special chars in alias)
    local section=$(awk -v alias="$alias" '
        $0 == "### " alias { in_section=1; next }
        in_section && /^### / { in_section=0 }
        in_section { print }
    ' "$config_file")

    if [ -z "$section" ]; then
        log_error "PC '$alias' not found in config"
        return 1
    fi

    # Parse fields
    PC_IP=$(echo "$section" | grep -i "IP:" | sed 's/.*IP[^:]*:[[:space:]]*\([0-9.]*\).*/\1/')
    PC_MAC=$(echo "$section" | grep -i "MAC:" | sed 's/.*MAC[^:]*:[[:space:]]*\([0-9A-Fa-f:]*\).*/\1/')
    PC_STATUS=$(echo "$section" | grep -i "Status:" | sed 's/.*Status[^:]*:[[:space:]]*\([a-z]*\).*/\1/')
    PC_DESC=$(echo "$section" | grep -i "Description:" | sed 's/.*Description[^:]*:[[:space:]]*\(.*\)/\1/')

    # Parse global settings
    AUTH_TOKEN=$(grep -i "Auth Token:" "$config_file" | sed 's/.*:[[:space:]]*\(.*\)/\1/')
    AGENT_PORT=$(grep -i "Agent Port:" "$config_file" | sed 's/.*:[[:space:]]*\([0-9]*\).*/\1/')
    DEFAULT_TIMEOUT=$(grep -i "Default Timeout:" "$config_file" | sed 's/.*:[[:space:]]*\([0-9]*\).*/\1/')
    WOL_PORT=$(grep -i "WOL Port:" "$config_file" | sed 's/.*:[[:space:]]*\([0-9]*\).*/\1/')

    # Set defaults
    AGENT_PORT=${AGENT_PORT:-8888}
    DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-30}
    WOL_PORT=${WOL_PORT:-9}

    # Validate required fields
    if [ -z "$PC_IP" ] || [ -z "$PC_MAC" ]; then
        log_error "Missing required fields (IP or MAC) for PC '$alias'"
        return 1
    fi

    if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" == "your-secret-token-here-change-me" ]; then
        log_error "Auth token not configured or still using default"
        return 1
    fi

    return 0
}

# List all PCs from config
list_all_pcs() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    echo "Available PCs:"
    echo "=============="

    # Extract all PC sections
    grep "^### " "$config_file" | sed 's/^### //' | while read -r alias; do
        if parse_pc_config "$alias" "$config_file" 2>/dev/null; then
            printf "%-20s IP: %-15s MAC: %-17s Status: %s\n" \
                "$alias" "$PC_IP" "$PC_MAC" "${PC_STATUS:-unknown}"
        fi
    done
}
