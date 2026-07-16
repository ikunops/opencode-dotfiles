#!/bin/bash
# OpenCode 配置一键同步脚本（Linux/macOS）
# 用法: bash setup.sh

REPO="https://github.com/ikunops/opencode-dotfiles.git"
TARGET="$HOME/.config/opencode"
TEMP="/tmp/opencode-sync"

echo "🔄 开始同步 OpenCode 配置..."

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="linux"
    echo "📌 检测到平台: macOS"
else
    PLATFORM="linux"
    echo "📌 检测到平台: Linux"
fi

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 请先安装 Node.js >= 18.0.0"
    echo "   安装: https://nodejs.org/"
    exit 1
fi

# 检查 OpenCode
if ! command -v opencode &> /dev/null; then
    echo "❌ 请先安装 OpenCode"
    echo "   安装: npm install -g opencode-ai"
    exit 1
fi

# 克隆或更新配置
if [ -d "$TEMP" ]; then
    echo "📥 更新配置..."
    git -C "$TEMP" pull
else
    echo "📥 克隆配置..."
    git clone "$REPO" "$TEMP"
fi

# 安装依赖（包括 infra-ops-mcp）
echo "📦 安装依赖..."
cd "$TEMP" && npm install

# 创建目标目录
mkdir -p "$TARGET"

# 读取基础配置和平台配置，合并生成最终配置
# 这里简化处理，直接复制基础配置并修改 shell
cp "$TEMP/opencode.base.jsonc" "$TARGET/opencode.jsonc"

# 用 sed 修改 shell 配置
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/"powershell"/"bash"/g' "$TARGET/opencode.jsonc"
else
    sed -i 's/"powershell"/"bash"/g' "$TARGET/opencode.jsonc"
fi

# 复制其他文件
cp "$TEMP/tui.jsonc" "$TARGET/" 2>/dev/null || true
cp "$TEMP/package.json" "$TARGET/"
cp "$TEMP/package-lock.json" "$TARGET/"

# 复制目录
cp -r "$TEMP/skills" "$TARGET/"
cp -r "$TEMP/plugins" "$TARGET/"

# 清理
rm -rf "$TEMP"

echo "✅ 配置同步完成！"
echo ""
echo "📌 当前配置:"
echo "   Shell: bash"
echo "   MCP: infra-ops + composio"
echo ""
echo "📌 启动 OpenCode:"
echo "   opencode"
echo ""
echo "📌 首次使用 Composio 时会弹出浏览器认证"
