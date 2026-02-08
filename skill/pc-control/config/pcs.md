# PC 控制配置

## PC 列表

### office-pc
- **别名**: office-pc
- **IP**: 192.168.1.100
- **MAC**: AA:BB:CC:DD:EE:FF
- **描述**: 办公室台式电脑
- **状态**: active

### gaming-pc
- **别名**: gaming-pc
- **IP**: 192.168.1.101
- **MAC**: 11:22:33:44:55:66
- **描述**: 卧室游戏电脑
- **状态**: active

### laptop
- **别名**: laptop
- **IP**: 192.168.1.102
- **MAC**: 22:33:44:55:66:77
- **描述**: 工作笔记本
- **状态**: active

## 全局设置

- **认证令牌**: your-secret-token-here-change-me
- **Agent 端口**: 8888
- **默认超时**: 30
- **WOL 端口**: 9

## 配置指南

### 添加新 PC

1. 在 "PC 列表" 下添加新的部分，格式如下：
   ```
   ### pc-alias
   - **别名**: pc-alias
   - **IP**: 192.168.1.xxx
   - **MAC**: XX:XX:XX:XX:XX:XX
   - **描述**: PC 的描述信息
   - **状态**: active
   ```

2. 替换以下内容：
   - `pc-alias`: PC 的唯一标识符
   - `192.168.1.xxx`: PC 的静态 IP 地址
   - `XX:XX:XX:XX:XX:XX`: 网络适配器的 MAC 地址
   - 描述: 人类可读的描述信息
   - 状态: active 或 inactive

### 查找 MAC 地址

**在 Windows 上：**
```cmd
ipconfig /all
```
在网络适配器下查找 "物理地址"。

**在 Linux 上：**
```bash
ip link show
```

### 安全注意事项

1. **更改认证令牌**：生成强随机令牌：
   ```bash
   openssl rand -hex 32
   ```

2. **使用静态 IP**：在路由器的 DHCP 设置中为所有 PC 分配静态 IP 地址。

3. **防火墙**：确保 Windows 防火墙允许 agent 使用端口 8888。

4. **网络**：此系统仅设计用于局域网使用。请勿暴露到互联网。

### Wake-on-LAN 设置

要使 Wake-on-LAN 正常工作，您必须：

1. **在 BIOS/UEFI 中启用**：
   - 进入 BIOS/UEFI 设置
   - 查找 "Wake on LAN"、"PXE Boot" 或 "Power On by PCI-E"
   - 启用该选项

2. **在 Windows 中启用**：
   - 设备管理器 → 网络适配器 → 属性
   - 电源管理选项卡：
     - ✓ 允许此设备唤醒计算机
     - ✓ 只允许魔术包唤醒计算机
   - 高级选项卡：
     - Wake on Magic Packet: 启用

3. **使用有线连接**：Wake-on-LAN 通常只适用于以太网，不适用于 WiFi。

4. **快速启动**：禁用 Windows 快速启动以确保 WOL 可靠工作：
   - 控制面板 → 电源选项 → 选择电源按钮的功能
   - 取消勾选 "启用快速启动"
