# NPS 服务端部署指南

NPS 是一款轻量级、高性能的内网穿透代理服务器，支持 Web 图形化管理界面。

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

复制示例配置并修改：

```bash
# 编辑 .env 文件（如果不存在则创建）
cat > .env << 'EOF'
# Web 管理界面配置
NPS_WEB_PORT=8080           # 管理界面端口（访问时用 http://IP:8080）
NPS_WEB_USER=admin          # 登录用户名
NPS_WEB_PASSWORD=your_password_here  # 登录密码（必须修改！）

# 客户端连接配置
NPS_BRIDGE_PORT=8024        # NPC 客户端连接端口
NPS_PUBLIC_VKEY=123456      # 公共连接密钥（客户端连接时用）

# 隧道端口范围
NPS_ALLOW_PORTS_START=9000  # 允许分配的端口起始
NPS_ALLOW_PORTS_END=9100    # 允许分配的端口结束
EOF
```

**重要：** 至少修改 `NPS_WEB_PASSWORD` 和 `NPS_PUBLIC_VKEY`！

### 2. 启动服务

#### 方式一：Docker 启动（推荐，自动重启）

```bash
./start.sh
```

#### 方式二：二进制启动（无需 Docker）

```bash
./start.sh binary
```

首次使用会自动下载对应架构的二进制文件。

### 3. 访问管理界面

启动后访问：

```
http://你的服务器IP:8080
```

默认账号：
- 用户名：`admin`（或你在 .env 中设置的）
- 密码：见 `.env` 文件中的 `NPS_WEB_PASSWORD`

---

## 启动方式选择

| 特性 | Docker 方式 | Binary 方式 |
|------|------------|-------------|
| 依赖 | 需要 Docker | 无需 Docker |
| 自动重启 | ✓ 容器自动重启 | ✗ 需要手动或配置 systemd |
| 首次启动 | 快（拉取镜像） | 需下载二进制文件 |
| 日志查看 | `docker compose logs -f` | `tail -f nps.log` |
| 适用场景 | 生产环境 | 测试环境或无法安装 Docker |

**切换方式：**

```bash
# Docker → Binary
./stop.sh && ./start.sh binary

# Binary → Docker
./stop.sh binary && ./start.sh
```

---

## 配置说明

### 配置文件优先级

配置优先级：**`.env` > `conf/nps.conf`**

- `.env`：推荐！环境变量配置，不进入 git，安全
- `conf/nps.conf`：NPS 原生配置文件，会被 `.env` 覆盖

### 关键配置项说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `NPS_WEB_PORT` | Web 管理界面端口 | 8080 |
| `NPS_WEB_USER` | 登录用户名 | admin |
| `NPS_WEB_PASSWORD` | 登录密码 | 必须修改 |
| `NPS_BRIDGE_PORT` | 客户端连接端口 | 8024 |
| `NPS_PUBLIC_VKEY` | 公共连接密钥 | 必须修改 |
| `NPS_ALLOW_PORTS_START` | 隧道端口范围起始 | 9000 |
| `NPS_ALLOW_PORTS_END` | 隧道端口范围结束 | 9100 |

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

这个命令会显示：
- 服务运行状态（Docker/Binary/未运行）
- Web 管理界面 URL
- 连接地址和密钥
- 常用命令提示
- 配置说明

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
docker compose logs -f    # 实时查看
docker compose logs --tail 100  # 最近100行
```

**Binary 方式：**
```bash
tail -f nps.log           # 实时查看
tail -n 100 nps.log       # 最近100行
```

---

## 客户端连接

### 理解两种密钥

NPS 支持两种客户端连接方式：

#### 方式 A：公共密钥（简单快速）

使用服务端配置的 `NPS_PUBLIC_VKEY`，所有客户端都用同一个密钥连接。

**适用场景：** 快速测试、个人使用、客户端较少

**连接命令：**
```bash
./npc -server=你的服务器IP:8024 -vkey=123456 -type=tcp
```

#### 方式 B：独立密钥（推荐生产环境）

每个客户端有独立的密钥，需要在 Web 管理界面预先创建。

**适用场景：** 多客户端、需要精细权限控制

**步骤：**

1. 登录 Web 管理界面
2. 左侧菜单「客户端」→ 点击「新增」
3. 填写备注（如"家里NAS"），点击「新增」
4. 记住生成的 `vkey`（如 `abc123xyz`）

**连接命令：**
```bash
./npc -server=你的服务器IP:8024 -vkey=abc123xyz -type=tcp
```

### 客户端部署

在需要暴露到公网的机器（内网机器）上运行客户端：

**Docker 方式：**
```bash
docker run -d \
  --name npc \
  --restart always \
  --net host \
  yisier1/npc \
  -server=你的服务器IP:8024 \
  -vkey=你的密钥 \
  -type=tcp
```

**Binary 方式：**
```bash
# 下载对应系统的 npc 二进制文件
./npc -server=你的服务器IP:8024 -vkey=你的密钥 -type=tcp
```

---

## 常见问题排查

### 1. 无法访问 Web 界面

**现象：** 浏览器访问 `http://IP:端口` 显示拒绝连接

**排查步骤：**

```bash
# 1. 查看服务状态
./info.sh

# 2. 检查端口监听
ss -tlnp | grep 8080

# 3. 本地测试
curl http://localhost:8080

# 4. 检查防火墙
ufw status          # Ubuntu/Debian
firewall-cmd --list-ports  # CentOS

# 5. 开放端口
ufw allow 8080/tcp
ufw allow 8024/tcp
```

### 2. 客户端无法连接

**现象：** 客户端显示连接失败

**排查步骤：**

```bash
# 1. 服务端检查端口
ss -tlnp | grep 8024

# 2. 检查防火墙
ufw allow 8024/tcp

# 3. 测试连通性（在客户端机器上）
telnet 服务端IP 8024

# 4. 查看服务端日志
docker compose logs -f   # Docker 方式
tail -f nps.log          # Binary 方式
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

**现象：** 启动时报错 `bind: address already in use`

**解决：**

```bash
# 1. 查看占用端口的进程
ss -tlnp | grep 8080

# 2. 修改 .env 使用其他端口
echo "NPS_WEB_PORT=8081" >> .env

# 3. 重启
./restart.sh
```

### 5. 修改密码后无法登录

**原因：** 只修改了 `.env` 但未重启服务

**解决：**

```bash
./restart.sh
```

---

## 数据备份

重要数据在 `conf/` 目录下：
- `nps.conf`：服务端配置
- `clients.json`：客户端信息
- `tasks.json`：隧道配置

**备份命令：**

```bash
tar czf nps-backup-$(date +%Y%m%d).tar.gz conf/
```

---

## 更多文档

- NPS 官方文档：https://ehang-io.github.io/nps/
- NPS GitHub：https://github.com/ehang-io/nps
