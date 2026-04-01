# NPS 客户端 (Docker 部署)

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

### 3. 查看日志

```bash
docker logs -f npc
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
| `./start.sh` | 启动客户端 |
| `./stop.sh` | 停止客户端 |
| `./restart.sh` | 重启客户端 |
| `docker logs -f npc` | 查看实时日志 |

---

## 多客户端部署

如果这台机器需要连接多个 NPS 服务器：

1. 复制目录：`cp -r docker docker2`
2. 修改 `docker2/.env`：更换 `NPS_SERVER` 和 `NPS_VKEY`
3. 修改 `docker2/.env`：更换 `CONTAINER_NAME=npc2`
4. 启动：`cd docker2 && ./start.sh`

---

## 故障排查

### 连接失败

查看日志：
```bash
docker logs npc
```

常见原因：
- VKey 错误 → 重新从 Web 界面获取
- 服务器防火墙未放行 8024 端口
- 服务器地址或端口错误

### 重启后连接不上

```bash
./restart.sh
```

或者：
```bash
docker compose restart
```
