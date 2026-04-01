#!/bin/bash

# 打包服务端部署文件

cd "$(dirname "$0")"

echo "================================"
echo "  服务端部署包打包工具"
echo "================================"
echo ""

# 输出文件名
OUTPUT_FILE="nps-frp-server-deploy.tar.gz"

# 创建输出目录
mkdir -p ../dist

# 清理旧文件
rm -f "../dist/$OUTPUT_FILE"

echo "打包文件列表:"
find . -type f \
  ! -path './nps/conf/*' \
  ! -path './nps/*.json' \
  ! -name '*.tar.gz' \
  ! -name 'pack.sh' \
  -print | head -20

echo ""
echo "开始打包..."

# 打包（排除运行时数据）
tar czf "../dist/$OUTPUT_FILE" \
  --exclude='nps/conf/clients.json' \
  --exclude='nps/conf/hosts.json' \
  --exclude='nps/conf/tasks.json' \
  --exclude='nps/conf/*.log' \
  --exclude='frp/frps.toml' \
  --exclude='*.tar.gz' \
  --exclude='pack.sh' \
  --exclude='.DS_Store' \
  .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "../dist/$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✓ 打包成功"
    echo ""
    echo "文件: /data/dist/$OUTPUT_FILE"
    echo "大小: $SIZE"
    echo ""
    echo "下载命令:"
    echo "  scp root@$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):/data/dist/$OUTPUT_FILE ."
else
    echo "✗ 打包失败"
    exit 1
fi
