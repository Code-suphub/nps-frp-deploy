#!/bin/bash

# 一键打包服务端和客户端部署包
# 在 nps-frp 目录下执行

cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

echo "================================"
echo "  内网穿透服务打包工具"
echo "================================"
echo ""

# 创建输出目录
mkdir -p "$PROJECT_DIR/dist"

# 打包服务端
echo "[1/2] 打包服务端部署包..."

# 清理旧的打包文件
rm -f "$PROJECT_DIR/dist/nps-frp-server-deploy.tar.gz"

# 打包服务端目录
cd "$PROJECT_DIR/server"
tar czf "$PROJECT_DIR/dist/nps-frp-server-deploy.tar.gz" \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  .

SERVER_SIZE=$(du -h "$PROJECT_DIR/dist/nps-frp-server-deploy.tar.gz" | cut -f1)
echo "  ✓ 服务端打包完成: nps-frp-server-deploy.tar.gz ($SERVER_SIZE)"

# 打包客户端
echo ""
echo "[2/2] 打包客户端部署包..."

# 清理旧的打包文件
rm -f "$PROJECT_DIR/dist/nps-frp-client-deploy.tar.gz"

# 打包客户端目录
cd "$PROJECT_DIR/client"
tar czf "$PROJECT_DIR/dist/nps-frp-client-deploy.tar.gz" \
  --exclude='.claude' \
  --exclude='*.log' \
  --exclude='npc' \
  --exclude='frpc' \
  --exclude='*.pid' \
  --exclude='.DS_Store' \
  .

CLIENT_SIZE=$(du -h "$PROJECT_DIR/dist/nps-frp-client-deploy.tar.gz" | cut -f1)
echo "  ✓ 客户端打包完成: nps-frp-client-deploy.tar.gz ($CLIENT_SIZE)"

cd "$PROJECT_DIR"

echo ""
echo "================================"
echo "  打包完成"
echo "================================"
echo ""
echo "输出目录: $PROJECT_DIR/dist/"
echo ""
ls -lh "$PROJECT_DIR/dist/"
echo ""
echo "下载命令:"
echo "  scp root@你的服务器IP:$PROJECT_DIR/dist/nps-frp-server-deploy.tar.gz ./"
echo "  scp root@你的服务器IP:$PROJECT_DIR/dist/nps-frp-client-deploy.tar.gz ./"
