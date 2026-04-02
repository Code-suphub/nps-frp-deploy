# FRP 客户端 (二进制部署)

适用于不想使用 Docker 的场景，直接运行二进制文件。

## 快速开始

### 1. 配置环境变量

编辑 `.env` 文件：

```bash
vim .env
```

基础配置：

```bash
# FRP 服务器信息
FRPS_SERVER=YOUR_SERVER_IP       # 你的服务器IP
FRPS_PORT=7000                # 服务端端口
FRPS_TOKEN=your_token_here    # 和服务端一致的 Token

# 运行模式
USE_CONFIG_FILE=false         # true: 使用配置文件, false: 单隧道
```

### 2. 选择运行模式

#### 模式 A：单隧道模式

```bash
USE_CONFIG_FILE=false
FRPC_REMOTE_PORT=7001         # 远程端口
FRPC_LOCAL_PORT=8080          # 本地端口
```

启动：
```bash
./start.sh
```

#### 模式 B：配置文件模式（推荐）

```bash
USE_CONFIG_FILE=true
```

创建 `frpc.toml`：

```toml
serverAddr = "YOUR_SERVER_IP"
serverPort = 7000
auth.method = "token"
auth.token = "your_token_here"

[[proxies]]
name = "bitwarden"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 7001

[[proxies]]
name = "nextcloud"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8081
remotePort = 7002
```

启动：
```bash
./start.sh
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

## 管理命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动客户端（首次自动下载二进制） |
| `./stop.sh` | 停止客户端 |
| `./restart.sh` | 重启客户端 |
| `tail -f frpc.log` | 查看实时日志 |

---

## 下一步：配置隧道（重要）

FRP 的隧道配置与 NPS 不同，**直接在客户端配置文件 `frpc.toml` 中定义**。

### 快速配置

编辑 `frpc.toml`：

```toml
serverAddr = "你的服务器IP"
serverPort = 7000
auth.method = "token"
auth.token = "你的Token"

[[proxies]]
name = "my-service"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080      # 本地服务端口
remotePort = 7001     # 外网访问端口
```

### 启动后测试

从外网访问：`http://服务器IP:7001` → 转发到本地 `127.0.0.1:8080`

详细配置示例请查看 `frpc.toml` 文件或 README.md

---

## 设置开机自启

### Linux (systemd)

创建服务文件：

```bash
sudo tee /etc/systemd/system/frpc.service > /dev/null << EOF
[Unit]
Description=FRP Client
After=network.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/frpc -c $(pwd)/frpc.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frpc
sudo systemctl start frpc
```

### macOS (launchd)

```bash
tee ~/Library/LaunchAgents/com.frpc.client.plist > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.frpc.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(pwd)/frpc</string>
        <string>-c</string>
        <string>$(pwd)/frpc.toml</string>
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

launchctl load ~/Library/LaunchAgents/com.frpc.client.plist
```

---

## Windows 部署

1. 设置 `ARCH=windows_amd64` 在 `.env` 中
2. 运行 `./start.sh` (使用 Git Bash 或 WSL)

或者手动下载运行：
```cmd
frpc.exe -c frpc.toml
```

---

## 故障排查

查看日志：
```bash
cat frpc.log
```

### 下载失败

手动下载：
```bash
wget https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_amd64.tar.gz
tar -xzf frp_0.60.0_linux_amd64.tar.gz --strip-components=1
chmod +x frpc
```

### Token 错误

确保和服务端 `FRPS_AUTH_TOKEN` 完全一致。

---

## 验证连接是否成功

### 方法一：查看客户端日志

```bash
tail -f frpc.log
```

连接成功时会出现：
```
login to server success
proxy started successfully
```

### 方法二：服务端 Dashboard 查看

1. 登录 FRP Dashboard (`http://你的服务器IP:7500`)
2. 查看「Proxies」或「Connections」
3. 确认你的隧道已在线

### 方法三：测试隧道连通性

假设你创建了一个 TCP 隧道，远程端口为 `7001`，本地端口为 `8080`：

```bash
# 在其他机器上访问服务端端口
curl http://你的服务器IP:7001
```

如果能访问到本地服务，说明穿透成功。

### 方法四：查看服务端日志

**Docker 方式：**
```bash
docker compose logs -f
```

**Binary 方式：**
```bash
tail -f frps.log
```

查看是否有客户端连接记录：
```
frps-log: client login success
frps-log: proxy [xxx] start
```
