# NPS 内网穿透服务

NPS 是一款轻量级、高性能、功能强大的内网穿透代理服务器，支持 Web 图形化管理界面。

## 快速开始

### 启动服务

```bash
./start.sh
```

启动后访问 Web 管理界面：`http://你的服务器IP:8080`

默认账号：
- 用户名：`admin`
- 密码：见 `.env` 文件中的 `NPS_WEB_PASSWORD`

---

## 配置文件说明

### 1. 环境变量配置 (.env)

主要配置都在 `.env` 文件中，**建议优先修改这里**：

```bash
# Web 管理界面配置
NPS_WEB_PORT=8080           # 管理界面端口
NPS_WEB_USER=admin          # 登录用户名
NPS_WEB_PASSWORD=your_nps_password_here  # 登录密码（重要：请修改！）

# 客户端连接端口
NPS_BRIDGE_PORT=8024        # NPC 客户端连接用的端口

# TCP 隧道端口范围
NPS_ALLOW_PORTS_START=9000  # 允许分配的端口起始
NPS_ALLOW_PORTS_END=9100    # 允许分配的端口结束
```

**修改 .env 后，需要重启服务才能生效：**
```bash
./restart.sh
```

### 2. 服务配置 (conf/nps.conf)

高级配置在 `conf/nps.conf` 中，一般不需要修改。

如需修改，编辑后执行：
```bash
docker compose restart
```

---

## 管理命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动服务 |
| `./stop.sh` | 停止服务 |
| `./restart.sh` | 重启服务（会重新加载 .env 配置） |

---

## 客户端连接

### 方式一：Docker 运行（推荐）

在本地机器（需要暴露到公网的机器）上运行：

```bash
docker run -d \
  --name npc \
  --restart always \
  --net host \
  yisier1/npc \
  -server=你的服务器IP:8024 \
  -vkey=从Web界面获取的密钥
```

### 方式二：二进制运行

从 [NPS Releases](https://github.com/ehang-io/nps/releases) 下载对应系统的 npc 客户端。

```bash
./npc -server=你的服务器IP:8024 -vkey=从Web界面获取的密钥
```

---

## 创建 TCP 隧道

1. 登录 Web 管理界面
2. 左侧菜单「客户端」→ 新增 → 记住 `vkey`
3. 左侧菜单「TCP隧道」→ 新增：
   - 选择刚才创建的客户端
   - 服务端端口：输入 9000-9100 范围内的端口（如 9001）
   - 目标 (IP:端口)：本地服务的地址，如 `127.0.0.1:8080`
4. 保存后，访问 `http://你的服务器IP:9001` 即可穿透到本地服务

---

## 常见问题

### 修改密码后无法登录

确保修改 `.env` 后执行了 `./restart.sh`，或者手动执行：
```bash
# 更新配置
sed -i 's/^web_password=.*/web_password=你的新密码/' conf/nps.conf

# 重启
docker compose restart
```

### 端口冲突

如果 8080 或 8024 端口被占用：
1. 修改 `.env` 中的端口
2. 执行 `./restart.sh`
3. 注意：修改后客户端连接命令也要相应改变

### 防火墙放行

确保服务器防火墙放行以下端口：
- `8024`：NPC 客户端连接
- `8080`：Web 管理界面
- `9000-9100`：TCP 隧道端口范围

```bash
# Ubuntu/Debian (UFW)
ufw allow 8024/tcp
ufw allow 8080/tcp
ufw allow 9000:9100/tcp

# CentOS (Firewalld)
firewall-cmd --permanent --add-port=8024/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=9000-9100/tcp
firewall-cmd --reload
```

---

## 数据备份

重要数据在 `conf/` 目录下：
- `clients.json`：客户端信息
- `hosts.json`：域名解析配置
- `tasks.json`：隧道配置

建议定期备份整个 `conf/` 目录。

---

## 更多文档

- 官方文档：https://ehang-io.github.io/nps/
- GitHub：https://github.com/ehang-io/nps
