# Scripts 脚本说明

本目录包含 NPS-FRP 部署工具的自动化脚本。

## 脚本列表

### 1. `pack-all.sh` - 一键打包
打包服务端和客户端部署包到 `dist/` 目录。

```bash
./scripts/pack-all.sh
```

**输出：**
- `dist/nps-frp-server-deploy.tar.gz` - 服务端部署包
- `dist/nps-frp-client-deploy.tar.gz` - 客户端部署包

---

### 2. `pack-server.sh` - 仅打包服务端
只打包服务端部署包（用于单独更新服务端）。

```bash
./scripts/pack-server.sh
```

---

### 3. `release.sh` - GitHub Release 自动发布
自动打包并发布到 GitHub Release。

```bash
# 发布新版本（需要先登录 gh auth login）
./scripts/release.sh v1.0.1
```

**前置条件 - 获取 GitHub Token：**

方式一：网页创建（推荐）
1. 打开 https://github.com/settings/tokens/new
2. Note: 填写用途，如 `nps-frp-deploy`
3. 勾选权限：**`repo`** 和 **`read:org`**
4. 点击 **Generate token**
5. 复制生成的 token（只显示一次！）

方式二：命令行创建（需有 gh CLI）
```bash
gh auth login -w
```

**登录 GitHub CLI：**
```bash
# 使用 token 登录
echo "your-token" | gh auth login --with-token
```

**Token 存储位置：**
登录成功后，token 会保存在：`~/.config/gh/hosts.yml`

**安全建议：**
```bash
# 限制配置文件权限，防止他人读取
chmod 600 ~/.config/gh/hosts.yml
```

**Token 需要权限：**
- `repo` - 仓库完整控制
- `read:org` - 读取组织信息

---

## 工作流程

### 开发更新后发布新版本：

```bash
# 1. 修改代码后提交
git add .
git commit -m "feat: xxx 功能更新"
git push

# 2. 打包并发布 Release
./scripts/release.sh v1.0.1
```

### 用户下载使用：

```bash
# 下载服务端
wget https://github.com/Code-suphub/nps-frp-deploy/releases/download/v1.0.0/nps-frp-server-deploy.tar.gz
tar xzf nps-frp-server-deploy.tar.gz

# 下载客户端
wget https://github.com/Code-suphub/nps-frp-deploy/releases/download/v1.0.0/nps-frp-client-deploy.tar.gz
tar xzf nps-frp-client-deploy.tar.gz
```
