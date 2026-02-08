#!/bin/bash
# Wake-on-LAN implementation

# Send WOL magic packet
send_wol() {
    local mac_address="$1"
    local broadcast_ip="${2:-255.255.255.255}"
    local port="${3:-9}"

    # Validate MAC address
    if ! validate_mac "$mac_address"; then
        log_error "Invalid MAC address: $mac_address"
        return 1
    fi

    log_info "Sending WOL packet to $mac_address"

    # Remove colons and convert to uppercase
    local mac_hex=$(echo "$mac_address" | tr -d ':' | tr '[:lower:]' '[:upper:]')

    # Build magic packet: 6 bytes of FF + 16 repetitions of MAC
    local magic_packet="FFFFFFFFFFFF"
    for i in {1..16}; do
        magic_packet="${magic_packet}${mac_hex}"
    done

    # Send packet using netcat
    if command_exists nc; then
        echo "$magic_packet" | xxd -r -p | nc -u -b -w1 "$broadcast_ip" "$port" 2>/dev/null

        if [ $? -eq 0 ]; then
            log_success "WOL packet sent successfully"
            return 0
        else
            log_error "Failed to send WOL packet"
            return 1
        fi
    else
        log_error "netcat (nc) not found. Install with: sudo apt-get install netcat-openbsd"
        return 1
    fi
}

# Wake PC by alias
wake_pc() {
    local alias="$1"
    local config_file="$2"

    if ! parse_pc_config "$alias" "$config_file"; then
        return 1
    fi

    log_info "Waking up PC: $alias ($PC_IP)"

    if send_wol "$PC_MAC" "255.255.255.255" "$WOL_PORT"; then
        log_success "Wake-on-LAN packet sent to $alias"
        log_info "Please wait 30-60 seconds for the PC to boot"
        return 0
    else
        return 1
    fi
}
