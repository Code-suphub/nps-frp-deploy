# NPS 客户端 (二进制部署)

适用于不想使用 Docker 的场景，直接运行二进制文件。

## 快速开始

### 1. 配置环境变量

编辑 `.env` 文件：

```bash
vim .env
```

修改以下配置：

```bash
# NPS 服务器地址和端口
NPS_SERVER=YOUR_SERVER_IP:8024    # 你的服务器IP:端口

# 客户端密钥 (从 NPS Web 管理界面获取)
NPS_VKEY=abc123def456          # 替换为你的 vkey
```

### 2. 启动客户端

```bash
./start.sh
```

首次启动会自动下载对应系统的 NPC 二进制文件。

### 3. 查看日志

```bash
tail -f npc.log
```

---

## 支持的系统

脚本会自动检测操作系统和架构并下载对应版本：

| 系统 | 架构 | 自动检测 |
|------|------|---------|
| Linux | AMD64 (x86_64) | ✅ |
| Linux | ARM64 | ✅ |
| Linux | ARMv7 | ✅ |
| macOS | AMD64 (Intel) | ✅ |
| macOS | ARM64 (Apple Silicon) | ✅ |
| Windows | AMD64 | ✅ |

**手动设置架构（可选）：**
```bash
# 在 .env 文件中设置
ARCH=darwin_amd64    # macOS Intel
ARCH=darwin_arm64    # macOS Apple Silicon
ARCH=windows_amd64   # Windows
```

---

## 如何获取 VKey

1. 登录 NPS Web 管理界面 (`http://你的服务器IP:8080`)
2. 左侧菜单「客户端」→「新增」
3. 创建后复制显示的 `vkey`
4. 填入 `.env` 文件的 `NPS_VKEY`

---

## 管理命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动客户端（首次自动下载二进制） |
| `./stop.sh` | 停止客户端 |
| `./restart.sh` | 重启客户端 |
| `tail -f npc.log` | 查看实时日志 |

---

## 下一步：创建隧道（重要）

客户端启动后，**需要在服务端 Web 管理界面创建隧道**，才能将内网服务暴露到公网。

### 快速步骤

1. **登录服务端 Web 界面** (`http://你的服务器IP:8080`)
2. **确认客户端在线**：左侧「客户端」查看状态是否为「在线」
3. **创建隧道**：左侧「TCP 隧道」→「新增」
   - 客户端：选择你的客户端
   - 服务端端口：如 `9001`（外网访问用）
   - 目标：`127.0.0.1:8080`（本地服务地址）
4. **测试访问**：从外网访问 `http://服务器IP:9001`

### 详细说明

**⚠️ 注意：隧道是在服务端配置的，不是在客户端！**

客户端只是建立连接通道，具体的端口映射规则需要在服务端 Web 管理界面配置。

**查看服务端详细教程：**
- 服务端 README：`server/nps/README.md` 中的「创建隧道」章节
- 或者直接访问服务端的 `http://服务器IP:8080` 按界面提示操作

**常见场景示例：**

| 本地服务 | 本地端口 | 目标地址 | 服务端端口 | 外网访问地址 |
|---------|---------|---------|-----------|-------------|
| 开发网站 | 8080 | `127.0.0.1:8080` | 9001 | `http://服务器IP:9001` |
| Home Assistant | 8123 | `127.0.0.1:8123` | 9002 | `http://服务器IP:9002` |
| NAS 管理 | 5000 | `127.0.0.1:5000` | 9003 | `http://服务器IP:9003` |

---

## 设置开机自启

### Linux (systemd)

创建服务文件：

```bash
sudo tee /etc/systemd/system/npc.service > /dev/null << EOF
[Unit]
Description=NPC Client
After=network.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/npc -server=YOUR_SERVER -vkey=YOUR_VKEY
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable npc
sudo systemctl start npc
```

### macOS (launchd)

创建 plist 文件：

```bash
tee ~/Library/LaunchAgents/com.npc.client.plist > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.npc.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(pwd)/npc</string>
        <string>-server=YOUR_SERVER</string>
        <string>-vkey=YOUR_VKEY</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$(pwd)</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.npc.client.plist
```

---

## Windows 部署

1. 下载 Windows 版本：`https://github.com/ehang-io/nps/releases`
2. 解压到目录
3. 创建 `.env` 文件，设置 `ARCH=windows_amd64`
4. 使用 Git Bash 或 WSL 运行 `./start.sh`

或者手动运行：
```cmd
npc.exe -server=你的服务器IP:8024 -vkey=your_vkey
```

---

## 故障排查

### 下载失败

手动下载：
```bash
# 查看系统架构
uname -m

# 从 GitHub 下载对应版本
wget https://github.com/ehang-io/nps/releases/download/v0.26.10/linux_amd64_client.tar.gz
tar -xzf linux_amd64_client.tar.gz
chmod +x npc
```

### 连接失败

查看日志：
```bash
cat npc.log
```

---

## 验证连接是否成功

### 方法一：查看客户端日志

```bash
tail -f npc.log
```

连接成功时会出现：
```
[I] [client.go:xxx]  Successfully connected to server
```

### 方法二：服务端查看在线客户端

1. 登录 NPS Web 管理界面
2. 左侧菜单「客户端」
3. 查看客户端状态是否为「在线」

### 方法三：测试隧道连通性

假设你创建了一个 TCP 隧道，服务端端口为 `9001`，本地端口为 `8080`：

```bash
# 在其他机器上访问服务端端口
curl http://你的服务器IP:9001
```

如果能访问到本地服务，说明穿透成功。

### 方法四：查看服务端日志（Docker 方式）

```bash
docker compose logs -f
```

查看是否有客户端连接记录：
```
New client connection from xxx.xxx.xxx.xxx
```
