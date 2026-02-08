# PC 控制 Skill

通过 Wake-on-LAN 和 HTTP API 远程控制局域网内 Windows PC 的 Claude Code skill。

## 功能特性

- **Wake-on-LAN**：唤醒休眠/关机的 PC
- **远程命令执行**：在 Windows PC 上运行命令
- **系统信息查询**：查询 PC 详细信息（主机名、操作系统、CPU、内存、IP、MAC）
- **电源管理**：关机、重启和休眠操作
- **多 PC 支持**：通过单个配置文件管理多台 PC

## 安装

### 1. 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y netcat-openbsd curl jq
```

### 2. 安装 Skill

```bash
# 复制 skill 到 Claude skills 目录
cp -r pc-control ~/.claude/skills/

# 设置脚本可执行权限
chmod +x ~/.claude/skills/pc-control/skill.sh
chmod +x ~/.claude/skills/pc-control/lib/*.sh
```

### 3. 配置 PC

编辑 `~/.claude/skills/pc-control/config/pcs.md`：

```bash
nano ~/.claude/skills/pc-control/config/pcs.md
```

**重要**：更改认证令牌并添加您的 PC！

### 4. 安装 Windows Agent

在每台 Windows PC 上：

1. 构建 agent（从 macOS/Linux）：
   ```bash
   cd /Users/tengdw/VSCProject/LLMBridge-PC/windows-agent
   make build-windows
   ```

2. 复制到 Windows PC：
   - `bin/windows-agent.exe`
   - `llmbridge-agent.yaml`
   - `install/install.bat`

3. 编辑 `llmbridge-agent.yaml` 并设置相同的认证令牌

4. 以管理员身份运行 `install.bat`

5. 在 BIOS 和 Windows 中启用 Wake-on-LAN（参见配置指南）

## 使用方法

### 从 Claude Code 使用

```bash
# 列出所有配置的 PC
/pc-control list

# 唤醒 PC
/pc-control wake office-pc

# 执行命令
/pc-control exec office-pc "ipconfig /all"
/pc-control exec gaming-pc "powershell Get-Process" powershell

# 获取系统信息
/pc-control info laptop

# 电源操作
/pc-control shutdown office-pc
/pc-control restart gaming-pc
/pc-control sleep laptop

# 显示帮助
/pc-control help
```

### 使用自然语言与 Claude 交互

您也可以使用自然语言：

- "唤醒我的办公室 PC"
- "在游戏 PC 上运行 ipconfig"
- "关闭笔记本电脑"
- "我的办公室 PC 的 IP 地址是什么？"

Claude 会将这些转换为相应的 skill 命令。

## 配置

### PC 配置格式

编辑 `config/pcs.md`：

```markdown
### pc-alias
- **别名**: pc-alias
- **IP**: 192.168.1.100
- **MAC**: AA:BB:CC:DD:EE:FF
- **描述**: PC 的描述信息
- **状态**: active
```

### 全局设置

```markdown
## 全局设置

- **认证令牌**: your-strong-random-token
- **Agent 端口**: 8888
- **默认超时**: 30
- **WOL 端口**: 9
```

### 生成认证令牌

```bash
openssl rand -hex 32
```

在以下两处使用相同的令牌：
- `~/.claude/skills/pc-control/config/pcs.md`
- `C:\LLMBridge\llmbridge-agent.yaml`（在每台 Windows PC 上）

## 故障排查

### Wake-on-LAN 不工作

1. 检查 BIOS/UEFI 设置 - 必须启用 WOL
2. 检查 Windows 网络适配器设置
3. 禁用 Windows 快速启动
4. 使用有线以太网连接（非 WiFi）
5. 验证 MAC 地址正确

### Agent 无法访问

1. 检查 agent 服务是否运行：
   ```cmd
   sc query LLMBridgeAgent
   ```

2. 检查 Windows 防火墙是否允许端口 8888

3. 验证 IP 地址正确且 PC 在网络上

4. 从 Windows PC 本身测试：
   ```cmd
   curl http://localhost:8888/health
   ```

### 认证失败

1. 验证两个配置文件中的令牌匹配
2. 检查令牌中是否有额外的空格或换行符
3. 确保令牌不是默认值

### 命令执行失败

1. 检查命令是否被安全规则阻止
2. 验证超时时间是否足够长
3. 检查指定 shell（cmd vs powershell）的命令语法
4. 查看 agent 日志：`C:\LLMBridge\agent.log`

## 安全

- **仅限局域网**：此系统仅设计用于本地网络使用
- **更改默认令牌**：始终使用强随机令牌
- **静态 IP**：使用静态 IP 地址以确保可靠性
- **防火墙**：Windows 防火墙限制对端口 8888 的访问
- **命令黑名单**：agent 会阻止危险命令
- **日志记录**：所有命令都记录在 Windows agent 上

## 架构

```
┌─────────────────────────────────────┐
│     Debian (Claude Code)            │
│  ┌──────────────────────────────┐   │
│  │   pc-control skill           │   │
│  │   - WOL 发送器               │   │
│  │   - HTTP 客户端              │   │
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

## 许可证

MIT License
