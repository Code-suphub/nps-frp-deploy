#!/bin/bash

# 打包服务端部署文件

cd "$(dirname "$0")/.."

echo "================================"
echo "  服务端部署包打包工具"
echo "================================"
echo ""

# 输出文件名
OUTPUT_FILE="dist/nps-frp-server-deploy.tar.gz"

# 创建输出目录
mkdir -p dist

# 清理旧文件
rm -f "$OUTPUT_FILE"

echo "打包文件列表:"
find server -type f \
  ! -path 'server/nps/conf/clients.json' \
  ! -path 'server/nps/conf/hosts.json' \
  ! -path 'server/nps/conf/tasks.json' \
  ! -path 'server/nps/conf/*.log' \
  ! -path 'server/frp/frps.toml' \
  ! -path 'server/nps/*.log' \
  ! -path 'server/nps/*.pid' \
  ! -path 'server/nps/nps' \
  ! -path 'server/frp/*.log' \
  ! -path 'server/frp/*.pid' \
  ! -path 'server/frp/frps' \
  ! -path 'server/frp/frpc' \
  ! -name '*.tar.gz' \
  -print | head -20

echo ""
echo "开始打包..."

# 打包 server 目录（排除运行时数据）
tar czf "$OUTPUT_FILE" \
  --exclude='nps/conf/clients.json' \
  --exclude='nps/conf/hosts.json' \
  --exclude='nps/conf/tasks.json' \
  --exclude='nps/conf/*.log' \
  --exclude='nps/*.log' \
  --exclude='nps/*.pid' \
  --exclude='nps/nps' \
  --exclude='frp/frps.toml' \
  --exclude='frp/*.log' \
  --exclude='frp/*.pid' \
  --exclude='frp/frps' \
  --exclude='frp/frpc' \
  --exclude='*.tar.gz' \
  --exclude='.DS_Store' \
  server/

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    # 获取绝对路径用于显示
    ABS_PATH=$(pwd)/$OUTPUT_FILE
    echo ""
    echo "✓ 打包成功"
    echo ""
    echo "文件: $ABS_PATH"
    echo "大小: $SIZE"
    echo ""
    echo "下载命令:"
    echo "  scp root@$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):$ABS_PATH ."
else
    echo "✗ 打包失败"
    exit 1
fi
