# LLMBridge-PC

这是一个通过 LLM（Claude Code）从 Debian 软路由远程控制局域网内 Windows 电脑的完整解决方案。

## 项目概述

LLMBridge-PC 提供了一套完整的远程 PC 控制系统，包括：

- **Windows Agent**: 运行在 Windows PC 上的 Go HTTP 服务，提供命令执行、系统信息查询、电源管理等功能
- **Debian Controller Skill**: 运行在 Debian 软路由上的 Bash skill，集成到 Claude Code 中，支持自然语言控制

## 核心功能

- 🌐 **远程唤醒 (Wake-on-LAN)**: 通过魔术包唤醒关机的 Windows 电脑
- 💻 **远程命令执行**: 在 Windows 上执行任意命令（cmd/powershell）
- 📊 **系统信息查询**: 获取主机名、OS、CPU、内存、IP、MAC 等信息
- ⚡ **电源管理**: 远程关机、重启、休眠
- 🔐 **安全机制**: Token 认证、命令黑名单、超时限制
- 🤖 **LLM 集成**: Claude Code skill，支持自然语言控制

## 项目结构

```
LLMBridge-PC/
├── README.md                   # 项目主文档
├── DEPLOYMENT.md               # 部署指南
├── LICENSE                     # MIT 许可证
├── .gitignore                  # Git 忽略规则
├── CLAUDE.md                   # 本文件 - Claude Code 项目说明
│
└── windows-agent/              # Windows Agent (Go)
    ├── main.go                 # 入口点
    ├── config/                 # 配置加载
    ├── server/                 # HTTP 服务器
    ├── executor/               # 命令执行引擎
    ├── logger/                 # 日志工具
    ├── install/                # 安装脚本
    └── llmbridge-agent.yaml    # 配置文件
```

## 技术栈

### Windows Agent
- **语言**: Go 1.21+
- **框架**: Gin (HTTP)
- **依赖**: gopsutil, logrus, lumberjack

### Debian Controller
- **语言**: Bash
- **依赖**: netcat, curl, jq

## 开发指南

### 构建 Windows Agent

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
cd windows-agent
go run main.go

# 测试健康检查
curl http://localhost:8888/health

# 测试命令执行
curl -X POST http://localhost:8888/api/v1/execute \
  -H "X-Auth-Token: your-token" \
  -H "Content-Type: application/json" \
  -d '{"command":"echo hello","shell":"cmd"}'
```

## 部署

详细部署步骤请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 快速开始

1. **生成 Token**:
   ```bash
   openssl rand -hex 32
   ```

2. **配置 Debian**:
   ```bash
   nano ~/.claude/skills/pc-control/config/pcs.md
   ```

3. **部署 Windows Agent**:
   - 复制 `windows-agent.exe` 到 `C:\LLMBridge\`
   - 复制 `llmbridge-agent.yaml` 到 `C:\LLMBridge\`
   - 编辑配置文件设置 token
   - 以管理员身份运行 `install.bat`

4. **启用 Wake-on-LAN**:
   - BIOS 设置
   - Windows 网络适配器设置
   - 禁用快速启动

## 使用方法

### Skill 命令

```bash
# 列出所有 PC
/pc-control list

# 唤醒 PC
/pc-control wake office-pc

# 执行命令
/pc-control exec office-pc "ipconfig /all"

# 获取系统信息
/pc-control info laptop

# 电源操作
/pc-control shutdown office-pc
```

### 自然语言控制

直接对 Claude 说：
- "唤醒我的办公室电脑"
- "在游戏电脑上运行 ipconfig"
- "关闭笔记本电脑"

## API 文档

### 健康检查
```http
GET /health
```

### 执行命令
```http
POST /api/v1/execute
Headers: X-Auth-Token: <token>
Body: {"command": "ipconfig", "shell": "cmd", "timeout": 30}
```

### 系统信息
```http
GET /api/v1/info
Headers: X-Auth-Token: <token>
```

### 电源操作
```http
POST /api/v1/power
Headers: X-Auth-Token: <token>
Body: {"action": "shutdown", "delay": 0}
```

## 安全特性

- **Token 认证**: 所有 API 请求需要 X-Auth-Token header
- **命令黑名单**: 阻止危险命令（format, del /s, diskpart 等）
- **超时限制**: 防止命令挂起（默认 30s，最大 300s）
- **Shell 限制**: 仅允许 cmd 和 powershell
- **完整日志**: 记录所有命令及结果
- **局域网限制**: 仅设计用于 LAN，不应暴露到互联网

## 配置说明

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

## 故障排查

### WOL 不工作
- 检查 BIOS/UEFI 中 WOL 是否启用
- 检查 Windows 网络适配器设置
- 禁用 Windows 快速启动
- 使用有线以太网连接（非 WiFi）

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

### 命令执行失败
- 检查命令是否被安全规则阻止
- 验证超时时间是否足够
- 查看 agent 日志: `C:\LLMBridge\agent.log`

## 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 致谢

本项目使用 Claude Code 开发，展示了 LLM 辅助开发的强大能力。

---

**⚠️ 安全提示**: 此系统仅设计用于受信任的局域网环境。请勿将 Agent 端口暴露到互联网。
