#!/bin/bash
# GitHub Release 自动发布脚本
# 用法: ./scripts/release.sh v1.0.1

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "❌ 错误: 请提供版本号"
  echo "用法: ./scripts/release.sh v1.0.1"
  exit 1
fi

# 检查 gh 是否登录
if ! gh auth status &>/dev/null; then
  echo "⚠️  GitHub CLI 未登录，请先执行: gh auth login"
  exit 1
fi

echo "🚀 开始发布流程..."

# 1. 重新打包
echo "📦 重新打包..."
./scripts/pack-all.sh

# 2. 检查 tag 是否存在
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "✅ Tag $VERSION 已存在"
else
  echo "🏷️  创建 tag: $VERSION"
  git tag "$VERSION"
  git push origin "$VERSION"
fi

# 3. 创建或更新 release
echo "📤 上传到 GitHub Release..."

# 先检查 release 是否存在
if gh release view "$VERSION" &>/dev/null; then
  echo "📤 Release 已存在，上传文件..."
  gh release upload "$VERSION" \
    dist/nps-frp-client-deploy.tar.gz \
    dist/nps-frp-server-deploy.tar.gz \
    --clobber
else
  echo "📤 创建新 Release..."
  gh release create "$VERSION" \
    --title "$VERSION" \
    --notes "自动发布版本 $VERSION" \
    dist/nps-frp-client-deploy.tar.gz \
    dist/nps-frp-server-deploy.tar.gz
fi

echo "✅ 发布完成!"
echo "🔗 访问: https://github.com/Code-suphub/nps-frp-deploy/releases/tag/$VERSION"
