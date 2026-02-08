# PC Control Skill

Claude Code skill for remotely controlling Windows PCs in your LAN via Wake-on-LAN and HTTP API.

## Features

- **Wake-on-LAN**: Wake up sleeping/shutdown PCs
- **Remote Command Execution**: Run commands on Windows PCs
- **System Information**: Query PC details (hostname, OS, CPU, memory, IP, MAC)
- **Power Management**: Shutdown, restart, and sleep operations
- **Multi-PC Support**: Manage multiple PCs from a single configuration file

## Installation

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y netcat-openbsd curl jq
```

### 2. Install Skill

```bash
# Copy skill to Claude skills directory
cp -r pc-control ~/.claude/skills/

# Make scripts executable
chmod +x ~/.claude/skills/pc-control/skill.sh
chmod +x ~/.claude/skills/pc-control/lib/*.sh
```

### 3. Configure PCs

Edit `~/.claude/skills/pc-control/config/pcs.md`:

```bash
nano ~/.claude/skills/pc-control/config/pcs.md
```

**Important**: Change the auth token and add your PCs!

### 4. Install Windows Agent

On each Windows PC:

1. Build the agent (from macOS/Linux):
   ```bash
   cd /Users/tengdw/VSCProject/LLMBridge-PC/windows-agent
   make build-windows
   ```

2. Copy to Windows PC:
   - `bin/windows-agent.exe`
   - `config.yaml`
   - `install/install.bat`

3. Edit `config.yaml` and set the same auth token

4. Run `install.bat` as Administrator

5. Enable Wake-on-LAN in BIOS and Windows (see config guide)

## Usage

### From Claude Code

```bash
# List all configured PCs
/pc-control list

# Wake up a PC
/pc-control wake office-pc

# Execute a command
/pc-control exec office-pc "ipconfig /all"
/pc-control exec gaming-pc "powershell Get-Process" powershell

# Get system information
/pc-control info laptop

# Power operations
/pc-control shutdown office-pc
/pc-control restart gaming-pc
/pc-control sleep laptop

# Show help
/pc-control help
```

### Natural Language with Claude

You can also use natural language:

- "Wake up my office PC"
- "Run ipconfig on the gaming PC"
- "Shutdown the laptop"
- "What's the IP address of my office PC?"

Claude will translate these to the appropriate skill commands.

## Configuration

### PC Configuration Format

Edit `config/pcs.md`:

```markdown
### pc-alias
- **Alias**: pc-alias
- **IP**: 192.168.1.100
- **MAC**: AA:BB:CC:DD:EE:FF
- **Description**: Description of the PC
- **Status**: active
```

### Global Settings

```markdown
## Global Settings

- **Auth Token**: your-strong-random-token
- **Agent Port**: 8888
- **Default Timeout**: 30
- **WOL Port**: 9
```

### Generate Auth Token

```bash
openssl rand -hex 32
```

Use the same token in:
- `~/.claude/skills/pc-control/config/pcs.md`
- `C:\LLMBridge\config.yaml` (on each Windows PC)

## Troubleshooting

### Wake-on-LAN Not Working

1. Check BIOS/UEFI settings - WOL must be enabled
2. Check Windows network adapter settings
3. Disable Windows Fast Startup
4. Use wired Ethernet connection (not WiFi)
5. Verify MAC address is correct

### Agent Not Reachable

1. Check if agent service is running:
   ```cmd
   sc query LLMBridgeAgent
   ```

2. Check Windows Firewall allows port 8888

3. Verify IP address is correct and PC is on network

4. Test from Windows PC itself:
   ```cmd
   curl http://localhost:8888/health
   ```

### Authentication Fails

1. Verify token matches in both config files
2. Check for extra spaces or newlines in token
3. Ensure token is not the default value

### Command Execution Fails

1. Check if command is blocked by security rules
2. Verify timeout is sufficient for long-running commands
3. Check command syntax for the specified shell (cmd vs powershell)
4. Review agent logs: `C:\LLMBridge\agent.log`

## Security

- **LAN Only**: This system is designed for local network use only
- **Change Default Token**: Always use a strong random token
- **Static IPs**: Use static IP addresses for reliability
- **Firewall**: Windows Firewall limits access to port 8888
- **Command Blacklist**: Dangerous commands are blocked by the agent
- **Logging**: All commands are logged on the Windows agent

## Architecture

```
┌─────────────────────────────────────┐
│     Debian (Claude Code)            │
│  ┌──────────────────────────────┐   │
│  │   pc-control skill           │   │
│  │   - WOL sender               │   │
│  │   - HTTP client              │   │
│  └──────────────────────────────┘   │
└─────────────────┬───────────────────┘
                  │ LAN
        ┌─────────┼─────────┐
        │         │         │
┌───────▼──┐ ┌───▼─────┐ ┌─▼────────┐
│Windows 1 │ │Windows 2│ │Windows N │
│ Agent    │ │ Agent   │ │ Agent    │
│ :8888    │ │ :8888   │ │ :8888    │
└──────────┘ └─────────┘ └──────────┘
```

## License

MIT License
