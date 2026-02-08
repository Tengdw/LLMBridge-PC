# LLMBridge-PC 部署指南

## 概述

本指南将帮助您完成 LLMBridge-PC 系统的完整部署，包括 Debian 控制端和 Windows Agent 端。

## 前置要求

### Debian 端（软路由）
- Debian 12 或更高版本
- 已安装 Claude Code
- 网络连接正常

### Windows 端
- Windows 7 或更高版本
- 管理员权限
- 支持 Wake-on-LAN 的网卡（用于远程唤醒）

---

## 第一部分：Debian 控制端部署

### 1. 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y netcat-openbsd curl jq
```

### 2. 验证 Skill 安装

Skill 已安装在 `~/.claude/skills/pc-control/`，验证文件：

```bash
ls -la ~/.claude/skills/pc-control/
ls -la ~/.claude/skills/pc-control/lib/
ls -la ~/.claude/skills/pc-control/config/
```

### 3. 配置 PC 列表

编辑配置文件：

```bash
nano ~/.claude/skills/pc-control/config/pcs.md
```

**重要步骤**：

1. **生成强随机 Token**：
   ```bash
   openssl rand -hex 32
   ```
   复制输出的 token，稍后会用到。

2. **修改配置文件**：
   - 将 `Auth Token` 改为刚才生成的 token
   - 添加您的 Windows PC 信息

配置示例：

```markdown
### my-pc
- **Alias**: my-pc
- **IP**: 192.168.1.100
- **MAC**: AA:BB:CC:DD:EE:FF
- **Description**: My Windows desktop
- **Status**: active

## Global Settings

- **Auth Token**: <刚才生成的 token>
- **Agent Port**: 8888
- **Default Timeout**: 30
- **WOL Port**: 9
```

### 4. 获取 Windows PC 的 MAC 地址

在 Windows PC 上运行：

```cmd
ipconfig /all
```

找到 "物理地址" 或 "Physical Address"，格式如：`AA-BB-CC-DD-EE-FF`

将其转换为冒号分隔格式：`AA:BB:CC:DD:EE:FF`

### 5. 测试 Skill

```bash
# 显示帮助
~/.claude/skills/pc-control/skill.sh help

# 列出配置的 PC
~/.claude/skills/pc-control/skill.sh list
```

---

## 第二部分：Windows Agent 部署

### 1. 准备文件

从构建机器复制以下文件到 Windows PC：

```
C:\LLMBridge\
├── windows-agent.exe
├── config.yaml
└── install.bat
```

文件位置：
- `windows-agent.exe`: `windows-agent/bin/windows-agent.exe`
- `config.yaml`: `windows-agent/config.yaml`
- `install.bat`: `windows-agent/install/install.bat`

### 2. 配置 Agent

编辑 `C:\LLMBridge\config.yaml`：

```yaml
auth:
  token: "<与 Debian 端相同的 token>"
```

**确保 token 与 Debian 端完全一致！**

### 3. 下载 NSSM

1. 访问：https://nssm.cc/download
2. 下载 NSSM（推荐 2.24 版本）
3. 解压并将 `nssm.exe` 添加到系统 PATH，或放到 `C:\LLMBridge\` 目录

### 4. 安装服务

以**管理员身份**运行 `install.bat`：

```cmd
右键点击 install.bat → 以管理员身份运行
```

安装脚本会：
- 创建 Windows 服务
- 配置自动启动
- 配置防火墙规则
- 启动服务

### 5. 验证服务

```cmd
# 检查服务状态
sc query LLMBridgeAgent

# 测试健康检查
curl http://localhost:8888/health
```

应该返回：
```json
{"status":"ok","hostname":"YOUR-PC-NAME","version":"1.0.0"}
```

---

## 第三部分：启用 Wake-on-LAN

### 1. BIOS/UEFI 设置

1. 重启电脑，进入 BIOS/UEFI（通常按 Del、F2 或 F12）
2. 找到以下选项之一并启用：
   - Wake on LAN
   - Wake on PCI-E
   - PXE Boot
   - Power On by PCI-E Device
3. 保存并退出

### 2. Windows 网络适配器设置

1. 打开**设备管理器**
2. 展开**网络适配器**
3. 右键点击您的网卡 → **属性**

**电源管理选项卡**：
- ✓ 允许此设备唤醒计算机
- ✓ 只允许魔术包唤醒计算机

**高级选项卡**：
- 找到 "Wake on Magic Packet" 或类似选项
- 设置为 **启用**

### 3. 禁用快速启动

1. 控制面板 → 电源选项
2. 选择电源按钮的功能
3. 点击"更改当前不可用的设置"
4. 取消勾选 **"启用快速启动（推荐）"**
5. 保存更改

### 4. 使用有线连接

**重要**：Wake-on-LAN 通常只支持有线以太网连接，不支持 WiFi。

---

## 第四部分：测试系统

### 1. 从 Debian 测试连接

```bash
# 测试 agent 是否可访问（PC 必须开机）
curl http://192.168.1.100:8888/health

# 使用 skill 测试
~/.claude/skills/pc-control/skill.sh info my-pc
```

### 2. 测试 Wake-on-LAN

```bash
# 1. 关闭 Windows PC（正常关机，不是休眠）

# 2. 从 Debian 发送 WOL 包
~/.claude/skills/pc-control/skill.sh wake my-pc

# 3. 等待 30-60 秒让 PC 启动

# 4. 测试连接
~/.claude/skills/pc-control/skill.sh info my-pc
```

### 3. 测试命令执行

```bash
# 执行简单命令
~/.claude/skills/pc-control/skill.sh exec my-pc "echo Hello"

# 获取 IP 配置
~/.claude/skills/pc-control/skill.sh exec my-pc "ipconfig"

# 使用 PowerShell
~/.claude/skills/pc-control/skill.sh exec my-pc "Get-Process" powershell
```

### 4. 测试电源操作

```bash
# 休眠
~/.claude/skills/pc-control/skill.sh sleep my-pc

# 重启
~/.claude/skills/pc-control/skill.sh restart my-pc

# 关机
~/.claude/skills/pc-control/skill.sh shutdown my-pc
```

---

## 第五部分：在 Claude Code 中使用

### 1. 启动 Claude Code

```bash
claude
```

### 2. 使用 Skill 命令

```bash
# 列出所有 PC
/pc-control list

# 唤醒 PC
/pc-control wake my-pc

# 执行命令
/pc-control exec my-pc "systeminfo"

# 获取信息
/pc-control info my-pc

# 关机
/pc-control shutdown my-pc
```

### 3. 使用自然语言

直接对 Claude 说：

- "唤醒我的电脑"
- "在我的电脑上运行 ipconfig"
- "我的电脑的 IP 地址是什么？"
- "关闭我的电脑"

Claude 会自动调用相应的 skill 命令。

---

## 故障排查

### WOL 不工作

**症状**：发送 WOL 包后 PC 没有启动

**解决方案**：
1. 确认 BIOS 中 WOL 已启用
2. 确认 Windows 网络适配器设置正确
3. 确认已禁用快速启动
4. 确认使用有线连接（非 WiFi）
5. 确认 MAC 地址正确
6. 尝试从路由器管理界面发送 WOL 包测试

### Agent 无法访问

**症状**：`curl http://IP:8888/health` 失败

**解决方案**：
1. 检查服务状态：`sc query LLMBridgeAgent`
2. 如果服务未运行：`nssm start LLMBridgeAgent`
3. 检查防火墙：
   ```cmd
   netsh advfirewall firewall show rule name="LLMBridge Agent"
   ```
4. 查看日志：`C:\LLMBridge\agent.log`
5. 从 Windows 本地测试：`curl http://localhost:8888/health`

### 认证失败

**症状**：返回 401 Unauthorized

**解决方案**：
1. 确认两端 token 完全一致
2. 检查 token 中是否有额外空格或换行
3. 重新生成 token 并更新两端配置

### 命令被阻止

**症状**：命令执行返回 "blocked by security policy"

**解决方案**：
1. 检查命令是否在黑名单中（format, del /s, diskpart 等）
2. 如果是安全命令，可以修改 `config.yaml` 中的 `blocked_commands`
3. 重启 agent 服务使配置生效

### 命令超时

**症状**：命令执行超时

**解决方案**：
1. 增加超时时间：
   ```bash
   /pc-control exec my-pc "long-command" cmd 120
   ```
2. 或修改 `config.yaml` 中的 `max_timeout`

---

## 安全建议

1. **使用强 Token**：
   ```bash
   openssl rand -hex 32
   ```

2. **限制网络访问**：
   - 仅在局域网使用
   - 不要将端口 8888 暴露到互联网

3. **定期更新 Token**：
   - 定期更换认证 token
   - 同时更新两端配置

4. **审查日志**：
   - 定期检查 `C:\LLMBridge\agent.log`
   - 查看是否有异常命令执行

5. **最小权限**：
   - Agent 以普通用户权限运行
   - 不要以管理员身份运行 agent

6. **备份配置**：
   - 备份 `pcs.md` 和 `config.yaml`
   - 记录 token 在安全位置

---

## 多 PC 部署

要管理多台 Windows PC：

1. **在每台 Windows PC 上**：
   - 安装 agent
   - 使用相同的 token
   - 确保每台 PC 有唯一的静态 IP

2. **在 Debian 端**：
   - 在 `pcs.md` 中添加每台 PC 的配置
   - 使用不同的 alias 区分

示例配置：

```markdown
### office-pc
- **IP**: 192.168.1.100
- **MAC**: AA:BB:CC:DD:EE:FF

### gaming-pc
- **IP**: 192.168.1.101
- **MAC**: 11:22:33:44:55:66

### laptop
- **IP**: 192.168.1.102
- **MAC**: 22:33:44:55:66:77
```

---

## 下一步

系统部署完成后，您可以：

1. 在 Claude Code 中使用自然语言控制 PC
2. 创建自动化脚本批量管理多台 PC
3. 集成到其他自动化工具中
4. 根据需求扩展功能

祝您使用愉快！
