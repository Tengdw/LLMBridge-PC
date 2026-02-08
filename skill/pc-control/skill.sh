#!/bin/bash
# PC Control Skill - Main entry point
# Remote control Windows PCs via Wake-on-LAN and HTTP API

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SKILL_DIR/config/pcs.md"

# Source libraries
source "$SKILL_DIR/lib/utils.sh"
source "$SKILL_DIR/lib/config_parser.sh"
source "$SKILL_DIR/lib/wol.sh"
source "$SKILL_DIR/lib/http_client.sh"

# Show help
show_help() {
    cat << EOF
PC Control Skill - Remote Windows PC Management

Usage:
  /pc-control <command> [arguments]

Commands:
  wake <alias>                    Wake up a PC using Wake-on-LAN
  exec <alias> <command>          Execute a command on a PC
  info <alias>                    Get system information from a PC
  list                            List all configured PCs
  shutdown <alias>                Shutdown a PC
  restart <alias>                 Restart a PC
  sleep <alias>                   Put a PC to sleep
  help                            Show this help message

Examples:
  /pc-control wake office-pc
  /pc-control exec office-pc "ipconfig /all"
  /pc-control exec gaming-pc "powershell Get-Process" powershell
  /pc-control info laptop
  /pc-control list
  /pc-control shutdown office-pc

Configuration:
  Edit $CONFIG_FILE to add/modify PCs

Requirements:
  - netcat-openbsd, curl, jq
  - Windows agent running on target PCs
  - Wake-on-LAN enabled in BIOS and Windows

EOF
}

# Main command dispatcher
main() {
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file not found: $CONFIG_FILE"
        log_info "Please create the config file. See README.md for format."
        exit 1
    fi

    local command="${1:-help}"
    shift || true

    case "$command" in
        wake)
            if [ -z "$1" ]; then
                log_error "Usage: /pc-control wake <alias>"
                exit 1
            fi
            wake_pc "$1" "$CONFIG_FILE"
            ;;

        exec|execute)
            if [ -z "$1" ] || [ -z "$2" ]; then
                log_error "Usage: /pc-control exec <alias> <command> [shell]"
                exit 1
            fi
            local alias="$1"
            local cmd="$2"
            local shell="${3:-cmd}"
            execute_command "$alias" "$cmd" "$shell" "$DEFAULT_TIMEOUT" "$CONFIG_FILE"
            ;;

        info)
            if [ -z "$1" ]; then
                log_error "Usage: /pc-control info <alias>"
                exit 1
            fi
            get_system_info "$1" "$CONFIG_FILE"
            ;;

        list|ls)
            list_all_pcs "$CONFIG_FILE"
            ;;

        shutdown|poweroff)
            if [ -z "$1" ]; then
                log_error "Usage: /pc-control shutdown <alias>"
                exit 1
            fi
            power_operation "$1" "shutdown" "$CONFIG_FILE"
            ;;

        restart|reboot)
            if [ -z "$1" ]; then
                log_error "Usage: /pc-control restart <alias>"
                exit 1
            fi
            power_operation "$1" "restart" "$CONFIG_FILE"
            ;;

        sleep|suspend)
            if [ -z "$1" ]; then
                log_error "Usage: /pc-control sleep <alias>"
                exit 1
            fi
            power_operation "$1" "sleep" "$CONFIG_FILE"
            ;;

        help|--help|-h)
            show_help
            ;;

        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
