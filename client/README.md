# 内网穿透客户端部署方案

本文档提供 NPS 和 FRP 客户端的完整部署方案，支持 Docker 和二进制两种方式，都使用 `.env` 文件进行环境管理。

## 目录结构

```
client/
├── nps/                    # NPS 客户端
│   ├── docker/            # Docker 部署方式
│   │   ├── .env          # 环境变量配置
│   │   ├── docker-compose.yml
│   │   ├── start.sh      # 启动脚本
│   │   ├── stop.sh       # 停止脚本
│   │   ├── restart.sh    # 重启脚本
│   │   └── README.md     # 使用说明
│   └── binary/           # 二进制部署方式
│       ├── .env
│       ├── start.sh      # 自动下载并启动
│       ├── stop.sh
│       ├── restart.sh
│       └── README.md
│
└── frp/                   # FRP 客户端
    ├── docker/           # Docker 部署方式
    │   ├── .env
    │   ├── docker-compose.yml
    │   ├── start.sh
    │   ├── stop.sh
    │   ├── restart.sh
    │   └── README.md
    └── binary/          # 二进制部署方式
        ├── .env
        ├── frpc.toml    # 多隧道配置模板
        ├── start.sh     # 自动下载并启动
        ├── stop.sh
        ├── restart.sh
        └── README.md
```

## 快速选择指南

| 场景 | 推荐方案 |
|------|---------|
| 机器已安装 Docker | `docker/` 方式 |
| 嵌入式/低内存设备 | `binary/` 方式 |
| NAS (群晖/威联通) | `docker/` 方式 |
| 路由器 (OpenWrt) | `binary/` 方式 |
| Windows 系统 | `binary/` 方式 |
| macOS | `binary/` 方式 |

## 快速开始

### 1. 选择方案

```bash
# 例如选择 FRP + Docker
cd frp/docker

# 或 NPS + 二进制
cd nps/binary
```

### 2. 配置环境变量

```bash
vim .env
```

### 3. 启动服务

```bash
./start.sh
```

---

## NPS 客户端配置

编辑 `.env`：

```bash
# 服务器信息
NPS_SERVER=YOUR_SERVER_IP:8024    # 你的服务器IP:端口

# 客户端密钥（从 NPS Web 管理界面获取）
NPS_VKEY=abc123def456
```

**如何获取 VKey**：
1. 登录服务器 Web 界面 (`http://服务器IP:8080`)
2. 「客户端」→「新增」
3. 复制显示的 `vkey`

---

## FRP 客户端配置

编辑 `.env`：

```bash
# 服务器信息
FRPS_SERVER=YOUR_SERVER_IP
FRPS_PORT=7000
FRPS_TOKEN=your_token_here    # 和服务端 FRPS_AUTH_TOKEN 一致

# 运行模式
USE_CONFIG_FILE=false         # false: 单隧道, true: 多隧道配置文件

# 单隧道模式配置
FRPC_REMOTE_PORT=7001         # 服务端开放的端口
FRPC_LOCAL_PORT=8080          # 本地服务端口
```

---

## 常用命令

```bash
./start.sh      # 启动（首次自动下载二进制）
./stop.sh       # 停止
./restart.sh    # 重启（重新加载配置）
```

---

## 多服务部署

如果一台机器需要暴露多个服务：

### FRP 推荐方案

使用配置文件模式 (`USE_CONFIG_FILE=true`)，编辑 `frpc.toml`：

```toml
serverAddr = "YOUR_SERVER_IP"
serverPort = 7000
auth.token = "your_token"

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

### NPS 方案

在 NPS Web 界面为同一个客户端添加多个 TCP 隧道。

---

## 开机自启

### Linux (systemd)

详见各 `README.md` 中的 systemd 配置部分。

### Docker 方式

已设置 `restart: always`，Docker 服务启动后自动运行。

### 二进制方式

使用 systemd 或 launchd (macOS) 管理，详见各 README。

---

## 故障排查

### 查看日志

```bash
# Docker 方式
docker logs -f npc
docker logs -f frpc

# 二进制方式
tail -f npc.log
tail -f frpc.log
```

### 连接失败常见原因

1. **Token/VKey 错误** → 检查服务端配置
2. **端口未开放** → 检查服务器防火墙
3. **服务器地址错误** → 检查 `.env` 中的 IP 和端口

---

## 更多文档

- NPS 官方文档：https://ehang-io.github.io/nps/
- FRP 官方文档：https://gofrp.org/
