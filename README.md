# LLMBridge-PC

通过 LLM（Claude Code）从 Debian 软路由远程控制局域网内 Windows 电脑的完整解决方案。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)](https://golang.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue)](https://github.com)

## ✨ 功能特性

- 🌐 **远程唤醒（Wake-on-LAN）** - 通过魔术包唤醒关机的 Windows 电脑
- 💻 **远程命令执行** - 在 Windows 上执行任意命令（cmd/powershell）
- 📊 **系统信息查询** - 获取主机名、OS、CPU、内存、IP、MAC 等信息
- ⚡ **电源管理** - 远程关机、重启、休眠
- 🔐 **安全机制** - Token 认证、命令黑名单、超时限制
- 🤖 **LLM 集成** - Claude Code skill，支持自然语言控制
- 🔧 **灵活配置** - 支持多位置配置文件，用户级和系统级部署

## 📋 目录

- [系统架构](#系统架构)
- [快速开始](#快速开始)
- [使用方法](#使用方法)
- [配置说明](#配置说明)
- [API 文档](#api-文档)
- [安全特性](#安全特性)
- [故障排查](#故障排查)
- [开发指南](#开发指南)

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Debian 12 (软路由)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Claude Code Skill: pc-control                 │  │
│  │  - 读取 PC 配置（MD 文件）                             │  │
│  │  - 发送 WOL 魔术包                                     │  │
│  │  - HTTP 客户端调用 Windows agents                     │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────────┬──────────────────────────────────┘
                            │ LAN
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌──────▼─────────┐
│  Windows PC 1  │  │  Windows PC 2  │  │  Windows PC N  │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │Go Agent  │  │  │  │Go Agent  │  │  │  │Go Agent  │  │
│  │HTTP:8888 │  │  │  │HTTP:8888 │  │  │  │HTTP:8888 │  │
│  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │
└────────────────┘  └────────────────┘  └────────────────┘
```

## 🚀 快速开始

### 前置要求

- **Debian 端**: Debian 12+, Claude Code, netcat, curl, jq
- **Windows 端**: Windows 7+, 管理员权限, 支持 WOL 的网卡

### 1. 安装 Debian Controller Skill

```bash
# 安装依赖
sudo apt-get update
sudo apt-get install -y netcat-openbsd curl jq

# Skill 已安装在 ~/.claude/skills/pc-control/
chmod +x ~/.claude/skills/pc-control/skill.sh
chmod +x ~/.claude/skills/pc-control/lib/*.sh

# 配置 PC 列表
nano ~/.claude/skills/pc-control/config/pcs.md
```

### 2. 部署 Windows Agent

```bash
# 在开发机器上构建
cd windows-agent
make build-windows

# 复制到 Windows PC:
#   - bin/windows-agent.exe
#   - llmbridge-agent.yaml
#   - install/install.bat

# 在 Windows 上以管理员身份运行
install.bat
```

### 3. 配置认证 Token

```bash
# 生成强随机 token
openssl rand -hex 32

# 在两处使用相同的 token:
# - Debian: ~/.claude/skills/pc-control/config/pcs.md
# - Windows: C:\LLMBridge\llmbridge-agent.yaml
```

### 4. 启用 Wake-on-LAN

**BIOS 设置**: 启用 "Wake on LAN" 或 "PXE Boot"

**Windows 网络适配器**:
- 设备管理器 → 网络适配器 → 属性
- 电源管理: ✓ 允许此设备唤醒计算机
- 高级: Wake on Magic Packet = 启用

**禁用快速启动**:
- 控制面板 → 电源选项 → 选择电源按钮的功能
- 取消勾选 "启用快速启动"

详细部署步骤请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

## 📖 使用方法

### Skill 命令

```bash
# 列出所有 PC
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
```

### 自然语言控制

直接对 Claude 说：

- "唤醒我的办公室电脑"
- "在游戏电脑上运行 ipconfig"
- "关闭笔记本电脑"
- "我的办公室电脑的 IP 地址是什么？"

Claude 会自动转换为相应的 skill 命令。

## ⚙️ 配置说明

### 配置文件位置

Agent 按以下优先级搜索配置文件：

1. 当前目录: `./llmbridge-agent.yaml`
2. 用户主目录: `~/.llmbridge/llmbridge-agent.yaml`
3. Windows: `C:\LLMBridge\llmbridge-agent.yaml`
4. Linux/macOS: `/etc/llmbridge/llmbridge-agent.yaml`

也可以通过命令行指定：

```bash
windows-agent.exe -config /path/to/config.yaml
```

### 配置文件示例

```yaml
server:
  port: 8888
  host: "0.0.0.0"

auth:
  token: "your-strong-random-token-here"

executor:
  default_timeout: 30
  max_timeout: 300
  allowed_shells:
    - cmd
    - powershell
  blocked_commands:
    - "^format\\s+"
    - "^del\\s+/[sS]"
    - "^diskpart"

logging:
  level: "info"
  file: "agent.log"
```

## 📡 API 文档

### 健康检查

```http
GET /health
```

**响应**:
```json
{
  "status": "ok",
  "hostname": "PC-NAME",
  "version": "1.0.0"
}
```

### 执行命令

```http
POST /api/v1/execute
Headers: X-Auth-Token: <token>
Content-Type: application/json
```

**请求体**:
```json
{
  "command": "ipconfig /all",
  "timeout": 30,
  "shell": "cmd"
}
```

**响应**:
```json
{
  "success": true,
  "stdout": "...",
  "stderr": "",
  "exit_code": 0,
  "execution_time": 1.23
}
```

### 系统信息

```http
GET /api/v1/info
Headers: X-Auth-Token: <token>
```

**响应**:
```json
{
  "hostname": "PC-NAME",
  "os": "Windows 11 Pro",
  "cpu_count": 8,
  "memory_total": 16384,
  "ip_addresses": ["192.168.1.100"],
  "mac_address": "AA:BB:CC:DD:EE:FF"
}
```

### 电源操作

```http
POST /api/v1/power
Headers: X-Auth-Token: <token>
Content-Type: application/json
```

**请求体**:
```json
{
  "action": "shutdown",
  "delay": 0
}
```

支持的操作: `shutdown`, `restart`, `sleep`

## 🔐 安全特性

- **Token 认证**: 所有 API 请求需要 X-Auth-Token header
- **命令黑名单**: 阻止危险命令（format, del /s, diskpart 等）
- **超时限制**: 防止命令挂起（默认 30s，最大 300s）
- **Shell 限制**: 仅允许 cmd 和 powershell
- **完整日志**: 记录所有命令及结果
- **局域网限制**: 仅设计用于 LAN，不应暴露到互联网

## 🔧 故障排查

### WOL 不工作

- ✓ 检查 BIOS/UEFI 中 WOL 是否启用
- ✓ 检查 Windows 网络适配器设置
- ✓ 禁用 Windows 快速启动
- ✓ 使用有线以太网连接（非 WiFi）
- ✓ 验证 MAC 地址正确

### Agent 无法访问

```bash
# 检查服务状态
sc query LLMBridgeAgent

# 检查防火墙
netsh advfirewall firewall show rule name="LLMBridge Agent"

# 本地测试
curl http://localhost:8888/health
```

### 认证失败

- 验证两处 token 完全匹配
- 检查 token 中是否有额外空格或换行
- 确保 token 不是默认值

### 命令执行失败

- 检查命令是否被安全规则阻止
- 验证超时时间是否足够
- 查看 agent 日志: `C:\LLMBridge\agent.log`

## 💻 开发指南

### 构建

```bash
cd windows-agent

# 安装依赖
make deps

# 构建 Windows 版本
make build-windows

# 构建所有平台
make build-all
```

### 测试

```bash
# 启动 agent
go run main.go

# 测试健康检查
curl http://localhost:8888/health

# 测试命令执行
curl -X POST http://localhost:8888/api/v1/execute \
  -H "X-Auth-Token: your-token" \
  -H "Content-Type: application/json" \
  -d '{"command":"echo hello","shell":"cmd"}'
```

### 项目结构

```
LLMBridge-PC/
├── windows-agent/              # Windows Agent (Go)
│   ├── main.go                 # 入口点
│   ├── config/                 # 配置加载
│   ├── server/                 # HTTP 服务器
│   ├── executor/               # 命令执行引擎
│   ├── logger/                 # 日志工具
│   └── install/                # 安装脚本
│
└── ~/.claude/skills/pc-control/  # Debian Controller (Bash)
    ├── skill.sh                # Skill 入口点
    ├── lib/                    # 库文件
    └── config/                 # 配置文件
```

## 🛠️ 技术栈

**Windows Agent**:
- Go 1.21+
- Gin (HTTP 框架)
- gopsutil (系统信息)
- logrus (日志)
- lumberjack (日志轮转)

**Debian Controller**:
- Bash
- netcat (WOL)
- curl (HTTP 客户端)
- jq (JSON 解析)

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🙏 致谢

本项目使用 Claude Code 开发，展示了 LLM 辅助开发的强大能力。

---

**⚠️ 安全提示**: 此系统仅设计用于受信任的局域网环境。请勿将 Agent 端口暴露到互联网。
