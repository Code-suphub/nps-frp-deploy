#!/bin/bash

# 打包客户端部署文件

cd "$(dirname "$0")"

echo "================================"
echo "  客户端部署包打包工具"
echo "================================"
echo ""

# 输出文件名
OUTPUT_FILE="../dist/nps-frp-client-deploy.tar.gz"

# 创建输出目录
mkdir -p ../dist

# 清理旧文件
rm -f "$OUTPUT_FILE"

echo "打包内容:"
echo "  - NPS Docker 部署"
echo "  - NPS 二进制部署"
echo "  - FRP Docker 部署"
echo "  - FRP 二进制部署"
echo ""
echo "排除文件: 日志、二进制文件、PID文件、临时文件"
echo ""

# 检查是否在正确的目录
if [ ! -d "nps" ] || [ ! -d "frp" ]; then
    echo "✗ 错误: 当前目录不正确，请从 client/ 目录运行"
    exit 1
fi

echo "开始打包..."

# 打包（排除运行时生成的文件）
tar czf "$OUTPUT_FILE" \
  --exclude='.claude' \
  --exclude='*.log' \
  --exclude='nps/binary/npc' \
  --exclude='nps/binary/npc.pid' \
  --exclude='frp/binary/frpc' \
  --exclude='frp/binary/frpc.pid' \
  --exclude='*.pid' \
  --exclude='*.tar.gz' \
  --exclude='pack.sh' \
  --exclude='.DS_Store' \
  --exclude='__MACOSX' \
  --exclude='.git' \
  --exclude='rustdesk' \
  --exclude='nps-frp' \
  .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✓ 打包成功"
    echo ""
    echo "文件: /data/nps-frp/dist/nps-frp-client-deploy.tar.gz"
    echo "大小: $SIZE"
    echo ""
    echo "下载命令:"
    echo "  scp root@$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):/data/nps-frp/dist/nps-frp-client-deploy.tar.gz ."
else
    echo "✗ 打包失败"
    exit 1
fi
