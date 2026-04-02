# FRP 服务端部署指南

FRP (Fast Reverse Proxy) 是一个快速反向代理，用于将内网服务暴露到公网。

---

## 目录

1. [快速开始](#快速开始)
2. [启动方式选择](#启动方式选择)
3. [配置说明](#配置说明)
4. [管理命令](#管理命令)
5. [查看服务信息](#查看服务信息)
6. [客户端连接](#客户端连接)
7. [常见问题排查](#常见问题排查)

---

## 快速开始

### 1. 配置环境变量

创建 `.env` 文件并修改：

```bash
cat > .env << 'EOF'
# 服务端监听端口
FRPS_BIND_PORT=7000              # FRPC 客户端连接端口

# Dashboard 管理界面
FRPS_DASHBOARD_PORT=7500         # Web 管理界面端口
FRPS_DASHBOARD_USER=admin        # 登录用户名
FRPS_DASHBOARD_PASSWORD=your_password_here  # 登录密码（必须修改！）

# 认证 Token（客户端连接需要）
FRPS_AUTH_TOKEN=your_token_here  # 客户端连接凭证（必须修改！）

# 允许的端口范围
FRPS_ALLOW_PORTS_START=7001      # 隧道端口起始
FRPS_ALLOW_PORTS_END=7010        # 隧道端口结束
EOF
```

**重要：** 至少修改 `FRPS_DASHBOARD_PASSWORD` 和 `FRPS_AUTH_TOKEN`！

### 2. 启动服务

#### 方式一：Docker 启动（推荐）

```bash
./start.sh
```

#### 方式二：二进制启动（无需 Docker）

```bash
./start.sh binary
```

首次使用会自动下载对应架构的二进制文件。

### 3. 访问 Dashboard

启动后访问：

```
http://你的服务器IP:7500
```

默认账号：
- 用户名：`admin`（或 `.env` 中设置的）
- 密码：`.env` 中的 `FRPS_DASHBOARD_PASSWORD`

---

## 启动方式选择

| 特性 | Docker 方式 | Binary 方式 |
|------|------------|-------------|
| 依赖 | 需要 Docker | 无需 Docker |
| 自动重启 | ✓ 容器自动重启 | ✗ 需手动或配置 systemd |
| 首次启动 | 快（拉取镜像） | 需下载二进制文件 |
| 日志查看 | `docker compose logs -f` | `tail -f frps.log` |
| 适用场景 | 生产环境 | 测试或无 Docker 环境 |

**切换方式：**

```bash
# Docker → Binary
./stop.sh && ./start.sh binary

# Binary → Docker
./stop.sh binary && ./start.sh
```

---

## 配置说明

### 配置优先级

**`.env` → `frps.toml`**

- `.env`：推荐！环境变量配置，不进入 git
- `frps.toml`：由脚本根据 `.env` 自动生成，不建议直接修改

### 关键配置项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `FRPS_BIND_PORT` | 客户端连接端口 | 7000 |
| `FRPS_DASHBOARD_PORT` | Web 界面端口 | 7500 |
| `FRPS_DASHBOARD_USER` | 登录用户名 | admin |
| `FRPS_DASHBOARD_PASSWORD` | 登录密码 | 必须修改 |
| `FRPS_AUTH_TOKEN` | 客户端认证 Token | 必须修改 |
| `FRPS_ALLOW_PORTS_START` | 隧道端口范围起始 | 7001 |
| `FRPS_ALLOW_PORTS_END` | 隧道端口范围结束 | 7010 |

### 修改配置后生效

```bash
# 修改 .env 后，重启服务
./restart.sh        # Docker 方式
# 或
./restart.sh binary # Binary 方式
```

---

## 管理命令

### 查看服务信息（推荐）

```bash
./info.sh
```

显示内容：
- 服务运行状态（Docker/Binary/未运行）
- Dashboard URL
- 连接地址和 Token
- 常用命令提示
- 客户端配置示例

### 启动

```bash
./start.sh          # Docker 方式
./start.sh binary   # Binary 方式
```

### 停止

```bash
./stop.sh           # Docker 方式
./stop.sh binary    # Binary 方式
```

### 重启

```bash
./restart.sh        # Docker 方式
./restart.sh binary # Binary 方式
```

### 查看日志

**Docker 方式：**
```bash
docker compose logs -f
docker compose logs --tail 100
```

**Binary 方式：**
```bash
tail -f frps.log
tail -n 100 frps.log
```

---

## 查看服务信息

使用 `./info.sh` 快速查看所有信息：

```
================================
       FRPS 服务信息
================================

【服务状态】
  ✓ 运行中 (Docker)

【Dashboard 管理界面】
  URL: http://1.2.3.4:7500
  用户名: admin
  密码: your_password

【客户端连接信息】
  服务器地址: 1.2.3.4:7000
  认证 Token: your_token

【允许端口范围】
  7001 - 7010

【常用命令】
  启动: ./start.sh
  停止: ./stop.sh
  重启: ./restart.sh
  查看日志: docker compose logs -f

【修改配置】
  配置文件: .env
    FRPS_DASHBOARD_USER=admin
    FRPS_DASHBOARD_PASSWORD=你的密码
    FRPS_AUTH_TOKEN=你的认证token
    ...

【客户端配置示例 frpc.toml】
  serverAddr = "1.2.3.4"
  serverPort = 7000
  auth.method = "token"
  auth.token = "your_token"
```

---

## 客户端连接

### 连接方式

FRP 使用 **Token 认证**，所有客户端使用相同的 `FRPS_AUTH_TOKEN` 连接。

### 方式一：Docker 运行（简单快速）

```bash
docker run -d \
  --name frpc \
  --restart always \
  --net host \
  snowdreamtech/frpc \
  -s 你的服务器IP:7000 \
  -t your_token \
  -p 7001 \
  -l 本地服务端口
```

参数说明：
- `-s`：FRPS 服务器地址和端口
- `-t`：连接 Token（.env 中的 `FRPS_AUTH_TOKEN`）
- `-p`：远程端口（FRPS 上开放的端口，如 7001）
- `-l`：本地服务端口（如 8080）

### 方式二：配置文件（推荐，支持多隧道）

创建 `frpc.toml`：

```toml
serverAddr = "你的服务器IP"
serverPort = 7000
auth.method = "token"
auth.token = "your_token"

[[proxies]]
name = "service1"
type = "tcp"
localPort = 8080
remotePort = 7001

[[proxies]]
name = "service2"
type = "tcp"
localPort = 8081
remotePort = 7002
```

运行：
```bash
docker run -d \
  --name frpc \
  --restart always \
  -v $(pwd)/frpc.toml:/etc/frp/frpc.toml \
  snowdreamtech/frpc
```

### 方式三：二进制运行

```bash
./frpc -c frpc.toml
```

---

## 验证客户端连接

### 方法一：Dashboard 查看

1. 登录 Dashboard (`http://你的服务器IP:7500`)
2. 查看左侧菜单：
   - 「Proxies」- 查看所有隧道状态
   - 「Connections」- 查看当前连接
3. 确认你的隧道显示为在线状态

### 方法二：查看服务端日志

**Docker 方式：**
```bash
docker compose logs -f
```

**Binary 方式：**
```bash
tail -f frps.log
```

连接成功时会显示：
```
frps-log: client login success
frps-log: proxy [tunnel-name] start
```

### 方法三：测试隧道连通性

假设你创建了一个 TCP 隧道，远程端口为 `7001`，本地服务端口为 `8080`：

```bash
# 在其他机器上测试访问
curl http://你的服务器IP:7001
```

如果能访问到客户端本地服务，说明穿透成功。

### 方法四：查看客户端日志

在客户端机器上：
```bash
tail -f frpc.log
```

连接成功时会出现：
```
login to server success
proxy started successfully
```

---

## 常见问题排查

### 1. 无法访问 Dashboard

**现象：** 浏览器访问被拒绝

**排查：**

```bash
# 1. 查看服务状态
./info.sh

# 2. 检查端口监听
ss -tlnp | grep 7500

# 3. 本地测试
curl http://localhost:7500

# 4. 检查防火墙
ufw allow 7500/tcp
```

### 2. 客户端连接失败

**现象：** 客户端无法连接到服务端

**排查：**

```bash
# 1. 服务端检查端口
ss -tlnp | grep 7000

# 2. 检查防火墙
ufw allow 7000/tcp
ufw allow 7001:7010/tcp  # 隧道端口范围

# 3. 检查 Token 是否匹配
# 服务端 .env 中的 FRPS_AUTH_TOKEN 必须等于客户端配置的 token

# 4. 查看日志
docker compose logs -f   # Docker 方式
tail -f frps.log         # Binary 方式
```

### 3. Docker 命令未找到

**现象：** `docker-compose: command not found`

**解决：**

```bash
# 安装 Docker Compose 插件
apt-get update && apt-get install -y docker-compose-plugin

# 或使用二进制方式
./start.sh binary
```

### 4. 端口冲突

**现象：** `bind: address already in use`

**解决：**

```bash
# 1. 查看占用
ss -tlnp | grep 7000

# 2. 修改 .env 使用其他端口
echo "FRPS_BIND_PORT=7002" >> .env

# 3. 重启
./restart.sh
```

### 5. 修改 Token 后客户端连不上

**原因：** Token 不匹配

**解决：**
1. 修改 `.env` 中的 `FRPS_AUTH_TOKEN`
2. 执行 `./restart.sh` 重启服务端
3. 客户端更新为相同的 Token

---

## 防火墙放行

确保服务器防火墙放行以下端口：

```bash
# Ubuntu/Debian (UFW)
ufw allow 7000/tcp      # 客户端连接
ufw allow 7500/tcp      # Dashboard
ufw allow 7001:7010/tcp # 隧道端口范围

# CentOS (Firewalld)
firewall-cmd --permanent --add-port=7000/tcp
firewall-cmd --permanent --add-port=7500/tcp
firewall-cmd --permanent --add-port=7001-7010/tcp
firewall-cmd --reload
```

---

## 更多文档

- 官方文档：https://gofrp.org/
- GitHub：https://github.com/fatedier/frp
