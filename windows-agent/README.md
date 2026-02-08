# LLMBridge Windows Agent

Windows agent for the LLMBridge-PC remote control system. This agent runs as a Windows service and provides HTTP API endpoints for remote command execution and system management.

## Features

- **Remote Command Execution**: Execute arbitrary commands via HTTP API
- **System Information**: Query system details (hostname, OS, CPU, memory, IP, MAC)
- **Power Management**: Shutdown, restart, and sleep operations
- **Security**: Token-based authentication and command blacklist
- **Logging**: Rotating log files with configurable levels
- **Windows Service**: Auto-start on boot using NSSM

## Installation

### Prerequisites

- Windows 7 or later
- [NSSM (Non-Sucking Service Manager)](https://nssm.cc/download)

### Quick Install

1. Build the agent:
   ```bash
   make build-windows
   ```

2. Copy files to Windows PC:
   - `bin/windows-agent.exe`
   - `config.yaml`
   - `install/install.bat`

3. Edit `config.yaml` and change the auth token:
   ```yaml
   auth:
     token: "your-strong-random-token-here"
   ```

4. Run `install.bat` as Administrator

### Manual Installation

```batch
# Create directory
mkdir C:\LLMBridge
copy windows-agent.exe C:\LLMBridge\
copy config.yaml C:\LLMBridge\

# Install service
nssm install LLMBridgeAgent "C:\LLMBridge\windows-agent.exe"
nssm set LLMBridgeAgent Start SERVICE_AUTO_START
nssm start LLMBridgeAgent

# Configure firewall
netsh advfirewall firewall add rule name="LLMBridge Agent" dir=in action=allow protocol=TCP localport=8888
```

## Configuration

Edit `config.yaml`:

```yaml
server:
  port: 8888              # HTTP server port
  host: "0.0.0.0"         # Listen on all interfaces
  read_timeout: 30        # Request read timeout (seconds)
  write_timeout: 30       # Response write timeout (seconds)

auth:
  token: "change-me"      # IMPORTANT: Change this!

executor:
  default_timeout: 30     # Default command timeout (seconds)
  max_timeout: 300        # Maximum allowed timeout (seconds)
  allowed_shells:
    - cmd                 # Windows Command Prompt
    - powershell          # PowerShell
  blocked_commands:       # Regex patterns for dangerous commands
    - "^format\\s+"
    - "^del\\s+/[sS]"
    - "^rd\\s+/[sS]"
    # ... more patterns

logging:
  level: "info"           # Log level: debug, info, warn, error
  file: "agent.log"       # Log file path
  max_size: 10            # Max log file size (MB)
  max_backups: 3          # Number of old log files to keep
  max_age: 7              # Max age of log files (days)
```

## API Endpoints

### Health Check
```
GET /health
Response: {"status": "ok", "hostname": "PC-NAME", "version": "1.0.0"}
```

### Execute Command
```
POST /api/v1/execute
Headers: X-Auth-Token: <your-token>
Body: {
  "command": "ipconfig /all",
  "timeout": 30,
  "shell": "cmd"
}
Response: {
  "success": true,
  "stdout": "...",
  "stderr": "",
  "exit_code": 0,
  "execution_time": 1.23
}
```

### System Information
```
GET /api/v1/info
Headers: X-Auth-Token: <your-token>
Response: {
  "hostname": "PC-NAME",
  "os": "Windows 11 Pro",
  "cpu_count": 8,
  "memory_total": 16384,
  "ip_addresses": ["192.168.1.100"],
  "mac_address": "AA:BB:CC:DD:EE:FF"
}
```

### Power Operations
```
POST /api/v1/power
Headers: X-Auth-Token: <your-token>
Body: {
  "action": "shutdown",  # shutdown, restart, or sleep
  "delay": 0
}
Response: {"success": true, "message": "System will shutdown now"}
```

## Testing

Test the agent locally:

```bash
# Start agent
go run main.go

# Test health endpoint
curl http://localhost:8888/health

# Test command execution
curl -X POST http://localhost:8888/api/v1/execute \
  -H "X-Auth-Token: your-token" \
  -H "Content-Type: application/json" \
  -d '{"command":"echo hello","shell":"cmd"}'

# Test system info
curl http://localhost:8888/api/v1/info \
  -H "X-Auth-Token: your-token"
```

## Service Management

```batch
# Start service
nssm start LLMBridgeAgent

# Stop service
nssm stop LLMBridgeAgent

# Restart service
nssm restart LLMBridgeAgent

# Check status
sc query LLMBridgeAgent

# View logs
type C:\LLMBridge\agent.log
```

## Security

- **Change the default token** in `config.yaml`
- Agent runs with the privileges of the user who installed it
- Dangerous commands are blocked by regex patterns
- All commands are logged
- Firewall rule limits access to port 8888
- Consider adding IP whitelist for additional security

## Troubleshooting

### Service won't start
- Check `agent.log` for errors
- Verify `config.yaml` syntax
- Ensure port 8888 is not in use
- Check Windows Event Viewer

### Authentication fails
- Verify token matches in both config and client
- Check for extra spaces or newlines in token
- Ensure `X-Auth-Token` header is set correctly

### Commands fail to execute
- Check if command is blocked by security rules
- Verify timeout is sufficient
- Check command syntax for the specified shell
- Review logs for detailed error messages

## Building from Source

```bash
# Install dependencies
make deps

# Build for Windows
make build-windows

# Build for all platforms
make build-all

# Run tests
make test
```

## License

MIT License
