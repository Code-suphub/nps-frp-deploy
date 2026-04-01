#!/bin/bash

# 打包客户端部署文件

cd "$(dirname "$0")"

echo "================================"
echo "  客户端部署包打包工具"
echo "================================"
echo ""

# 输出文件名
OUTPUT_FILE="nps-frp-client-deploy.tar.gz"

# 创建输出目录
mkdir -p ../dist

# 清理旧文件
rm -f "../dist/$OUTPUT_FILE"

echo "打包内容:"
echo "  - NPS Docker 部署"
echo "  - NPS 二进制部署"
echo "  - FRP Docker 部署"
echo "  - FRP 二进制部署"
echo ""
echo "排除文件: 日志、二进制文件、PID文件、临时文件"
echo ""
echo "开始打包..."

# 打包（排除运行时生成的文件）
tar czf "../dist/$OUTPUT_FILE" \
  --exclude='.claude' \
  --exclude='*.log' \
  --exclude='nps/binary/npc' \
  --exclude='frp/binary/frpc' \
  --exclude='*.pid' \
  --exclude='*.tar.gz' \
  --exclude='pack.sh' \
  --exclude='.DS_Store' \
  --exclude='__MACOSX' \
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
