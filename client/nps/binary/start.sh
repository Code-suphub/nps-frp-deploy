#!/bin/bash

cd "$(dirname "$0")"

# 加载配置
if [ -f .env ]; then
    source .env
fi

# 检查配置
if [ "$NPS_SERVER" = "你的服务器IP:8024" ] || [ -z "$NPS_SERVER" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_SERVER"
    exit 1
fi

if [ "$NPS_VKEY" = "your_vkey_here" ] || [ -z "$NPS_VKEY" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_VKEY"
    echo "提示: 从 NPS Web 管理界面的「客户端」页面获取 vkey"
    exit 1
fi

# 检测操作系统和架构
if [ "$ARCH" = "auto" ] || [ -z "$ARCH" ]; then
    # 检测操作系统
    OS=$(uname -s)
    case $OS in
        Linux)
            OS_TYPE="linux"
            ;;
        Darwin)
            OS_TYPE="darwin"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            OS_TYPE="windows"
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            echo "请手动设置 ARCH 变量，格式: {os}_{arch}"
            echo "可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64, windows_amd64"
            exit 1
            ;;
    esac

    # 检测架构
    case $(uname -m) in
        x86_64|amd64)
            ARCH_TYPE="amd64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            ;;
        armv7l)
            ARCH_TYPE="arm_v7"
            ;;
        *)
            echo "❌ 无法自动检测架构: $(uname -m)"
            echo "请手动设置 ARCH 变量，格式: {os}_{arch}"
            echo "可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64, windows_amd64"
            exit 1
            ;;
    esac

    # 特殊处理：NPS 没有 darwin_arm64，使用 darwin_amd64 + Rosetta
    if [ "$OS_TYPE" = "darwin" ] && [ "$ARCH_TYPE" = "arm64" ]; then
        echo "⚠️  NPS 未提供 darwin_arm64 版本，将使用 darwin_amd64 (通过 Rosetta 运行)"
        ARCH_TYPE="amd64"
        USE_ROSETTA=1
    fi

    ARCH="${OS_TYPE}_${ARCH_TYPE}"
    echo "✓ 自动检测到系统: $OS ($ARCH)"
fi

# 检查是否需要 Rosetta
if [ "$USE_ROSETTA" = "1" ]; then
    if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo ""
        echo "⚠️  首次在 Apple Silicon Mac 上运行 x86 程序"
        echo "   需要安装 Rosetta，执行以下命令："
        echo "   softwareupdate --install-rosetta --agree-to-license"
        echo ""
        exit 1
    fi
fi

# 检查二进制文件
if [ ! -f "$NPC_BINARY" ]; then
    echo "未找到 NPC 二进制文件，开始下载..."

    # 从 GitHub 下载最新版本
    DOWNLOAD_URL="https://github.com/ehang-io/nps/releases/download/v0.26.10/${ARCH}_client.tar.gz"

    echo "下载地址: $DOWNLOAD_URL"
    HTTP_CODE=$(curl -L -o npc.tar.gz -w "%{http_code}" "$DOWNLOAD_URL")

    if [ "$HTTP_CODE" != "200" ]; then
        echo "❌ 下载失败 (HTTP $HTTP_CODE)"
        rm -f npc.tar.gz
        echo ""
        echo "可能的原因："
        echo "  1. 该版本的预编译包不存在: ${ARCH}_client.tar.gz"
        echo "  2. 网络连接问题"
        echo ""
        echo "请手动下载: https://github.com/ehang-io/nps/releases"
        exit 1
    fi

    # 检查文件大小（避免下载到 404 页面）
    FILE_SIZE=$(stat -f%z npc.tar.gz 2>/dev/null || stat -c%s npc.tar.gz 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -lt "1000" ]; then
        echo "❌ 下载文件异常过小 ($FILE_SIZE bytes)，可能不存在该版本"
        rm -f npc.tar.gz
        exit 1
    fi

    echo "解压中..."
    tar -xzf npc.tar.gz
    rm -f npc.tar.gz

    # 设置可执行权限
    chmod +x npc

    echo "✓ 下载完成"
fi

echo ""
echo "启动 NPS 客户端..."
echo "服务器: $NPS_SERVER"
echo "VKey: ${NPS_VKEY:0:4}****"
echo ""

# 以后台方式运行
nohup ./npc -server="$NPS_SERVER" -vkey="$NPS_VKEY" -type="${NPS_TYPE:-tcp}" > npc.log 2>&1 &

echo $! > npc.pid
echo "✓ NPS 客户端已启动 (PID: $!)"
echo "日志文件: npc.log"
echo ""
echo "查看日志: tail -f npc.log"
echo "停止服务: ./stop.sh"
