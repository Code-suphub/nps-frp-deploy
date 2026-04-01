# FRP 内网穿透服务

FRP (Fast Reverse Proxy) 是一个快速反向代理，用于将内网服务暴露到公网。

## 快速开始

### 启动服务

```bash
./start.sh
```

启动后访问 Dashboard：`http://你的服务器IP:7500`

默认账号：
- 用户名：`admin`
- 密码：见 `.env` 文件中的 `FRPS_DASHBOARD_PASSWORD`

---

## 配置文件说明

### 1. 环境变量配置 (.env)

所有主要配置都在 `.env` 文件中，**建议优先修改这里**：

```bash
# 服务端监听端口
FRPS_BIND_PORT=7000              # FRPC 客户端连接用的端口

# Dashboard 管理界面
FRPS_DASHBOARD_PORT=7500         # Web 管理界面端口
FRPS_DASHBOARD_USER=admin        # 登录用户名
FRPS_DASHBOARD_PASSWORD=your_frp_password_here  # 登录密码（重要：请修改！）

# 认证 Token（客户端连接需要）
FRPS_AUTH_TOKEN=your_frp_token_here  # 客户端连接凭证（重要：请修改！）

# 允许的端口范围
FRPS_ALLOW_PORTS_START=7001      # 允许分配的端口起始
FRPS_ALLOW_PORTS_END=7010        # 允许分配的端口结束
```

**修改 .env 后，需要重启服务才能生效：**
```bash
./restart.sh
```

重启时会自动根据 `.env` 重新生成 `frps.toml` 配置文件。

### 2. 服务配置 (frps.toml)

此文件由 `restart.sh` 脚本根据 `.env` 自动生成，**不建议直接修改**。

如需自定义高级配置，可以编辑 `frps.toml`，然后执行：
```bash
docker compose restart
```

**注意**：执行 `./restart.sh` 会覆盖 `frps.toml`，请将自定义配置写入 `.env` 或使用其他文件名。

---

## 管理命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动服务 |
| `./stop.sh` | 停止服务 |
| `./restart.sh` | 重启服务（会重新加载 .env 配置并生成 frps.toml） |

---

## 客户端连接

### 方式一：命令行参数（简单快速）

在本地机器（需要暴露到公网的机器）上运行：

```bash
docker run -d \
  --name frpc \
  --restart always \
  --net host \
  snowdreamtech/frpc \
  -s 你的服务器IP:7000 \
  -t your_frp_token_here \
  -p 7001 \
  -l 本地服务端口
```

参数说明：
- `-s`：FRPS 服务器地址和端口
- `-t`：连接 Token（.env 中的 FRPS_AUTH_TOKEN）
- `-p`：远程端口（FRPS 上开放的端口，如 7001）
- `-l`：本地服务端口（如 8080）

### 方式二：配置文件（推荐，支持多隧道）

创建 `frpc.toml` 配置文件：

```toml
serverAddr = "你的服务器IP"
serverPort = 7000
auth.method = "token"
auth.token = "your_frp_token_here"

[[proxies]]
name = "bitwarden"
type = "tcp"
localPort = 8080
remotePort = 7001

[[proxies]]
name = "nextcloud"
type = "tcp"
localPort = 8081
remotePort = 7002
```

运行客户端：
```bash
docker run -d \
  --name frpc \
  --restart always \
  -v $(pwd)/frpc.toml:/etc/frp/frpc.toml \
  snowdreamtech/frpc
```

### 方式三：二进制运行

从 [FRP Releases](https://github.com/fatedier/frp/releases) 下载对应系统的 frpc 客户端。

```bash
./frpc -c frpc.toml
```

---

## 配置多隧道示例

假设你有多个本地服务需要暴露：

| 本地服务 | 本地端口 | 远程端口 | 访问地址 |
|---------|---------|---------|---------|
| Bitwarden | 8080 | 7001 | http://你的服务器IP:7001 |
| Nextcloud | 8081 | 7002 | http://你的服务器IP:7002 |
| Home Assistant | 8123 | 7003 | http://你的服务器IP:7003 |

创建 `frpc.toml`：

```toml
serverAddr = "你的服务器IP"
serverPort = 7000
auth.method = "token"
auth.token = "your_frp_token_here"

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

---

## 常见问题

### 修改 Token 后客户端连不上

1. 修改 `.env` 中的 `FRPS_AUTH_TOKEN`
2. 执行 `./restart.sh` 重启服务端
3. 客户端也需要更新为新的 Token

### 端口冲突

如果 7000 或 7500 端口被占用：
1. 修改 `.env` 中的端口
2. 执行 `./restart.sh`
3. 注意：修改后客户端连接命令也要相应改变

### 防火墙放行

确保服务器防火墙放行以下端口：
- `7000`：FRPC 客户端连接
- `7500`：Dashboard 管理界面
- `7001-7010`：TCP 隧道端口范围

```bash
# Ubuntu/Debian (UFW)
ufw allow 7000/tcp
ufw allow 7500/tcp
ufw allow 7001:7010/tcp

# CentOS (Firewalld)
firewall-cmd --permanent --add-port=7000/tcp
firewall-cmd --permanent --add-port=7500/tcp
firewall-cmd --permanent --add-port=7001-7010/tcp
firewall-cmd --reload
```

### 查看服务端日志

```bash
docker logs frps
```

### 查看客户端日志

```bash
docker logs frpc
```

---

## 进阶配置

### 启用加密和压缩

在客户端 `frpc.toml` 中添加：

```toml
[[proxies]]
name = "secure-service"
type = "tcp"
localPort = 8080
remotePort = 7001
transport.useEncryption = true
transport.useCompression = true
```

### 限制访问 IP

在服务端 `.env` 中添加高级配置（需要手动编辑 frps.toml）：

```toml
# frps.toml 中添加
auth.method = "token"
auth.token = "your_frp_token_here"

# 只允许特定 IP 访问 Dashboard
webServer.addr = "127.0.0.1"  # 仅本机访问，配合 SSH 隧道使用
```

---

## 更多文档

- 官方文档：https://gofrp.org/
- GitHub：https://github.com/fatedier/frp
- 中文文档：https://github.com/fatedier/frp/blob/dev/README_zh.md
