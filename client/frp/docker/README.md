# FRP 客户端 (Docker 部署)

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
```

### 2. 选择运行模式

#### 模式 A：单隧道模式（简单快速）

适合只暴露一个本地服务：

```bash
USE_CONFIG_FILE=false
FRPC_REMOTE_PORT=7001         # 服务端开放的端口
FRPC_LOCAL_PORT=8080          # 本地服务端口
```

启动：
```bash
./start.sh
```

访问：`http://你的服务器IP:7001` → 转发到本地 `localhost:8080`

#### 模式 B：配置文件模式（多隧道）

适合暴露多个本地服务：

```bash
USE_CONFIG_FILE=true
FRPC_CONFIG_FILE=frpc.toml
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

[[proxies]]
name = "homeassistant"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8123
remotePort = 7003
```

启动：
```bash
./start.sh
```

---

## 管理命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动客户端 |
| `./stop.sh` | 停止客户端 |
| `./restart.sh` | 重启客户端 |
| `docker logs -f frpc` | 查看实时日志 |

---

## 多客户端部署

如果这台机器需要连接多个 FRP 服务器：

1. 复制目录：`cp -r docker docker2`
2. 修改 `docker2/.env`：更换 `FRPS_SERVER` 和 `FRPS_TOKEN`
3. 修改 `docker2/.env`：更换 `CONTAINER_NAME=frpc2`
4. 启动：`cd docker2 && ./start.sh`

---

## 故障排查

### 连接失败

```bash
docker logs -f frpc
```

常见原因：
- Token 不匹配 → 检查和服务端 `FRPS_AUTH_TOKEN` 是否一致
- 端口冲突 → 更换 `FRPC_REMOTE_PORT`
- 防火墙 → 确保服务端 7000 端口开放

### 配置文件模式无法启动

检查配置文件路径：
```bash
ls -la frpc.toml
```

检查配置文件语法：
```bash
docker run --rm -v $(pwd)/frpc.toml:/etc/frp/frpc.toml snowdreamtech/frpc -c /etc/frp/frpc.toml --verify
```
