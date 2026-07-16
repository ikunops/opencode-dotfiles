# OpenCode 配置一键同步脚本
# 用法: 在新机器上运行此脚本

$repo = "https://github.com/ikunops/opencode-dotfiles.git"
$target = "$env:USERPROFILE\.config\opencode"
$temp = "$env:TEMP\opencode-sync"

Write-Host "🔄 开始同步 OpenCode 配置..." -ForegroundColor Cyan

# 检查 Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 请先安装 Node.js >= 18.0.0" -ForegroundColor Red
    exit 1
}

# 检查 OpenCode
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 请先安装 OpenCode: npm install -g opencode-ai" -ForegroundColor Red
    exit 1
}

# 克隆或更新配置
if (Test-Path $temp) {
    Write-Host "📥 更新配置..." -ForegroundColor Yellow
    git -C $temp pull
} else {
    Write-Host "📥 克隆配置..." -ForegroundColor Yellow
    git clone $repo $temp
}

# 安装依赖（包括 infra-ops-mcp）
Write-Host "📦 安装依赖..." -ForegroundColor Yellow
npm install --prefix $temp

# 复制到目标目录
Write-Host "📋 复制配置到 $target ..." -ForegroundColor Yellow
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

# 复制核心文件
Copy-Item -Path "$temp\opencode.jsonc" -Destination $target -Force
Copy-Item -Path "$temp\tui.jsonc" -Destination $target -Force
Copy-Item -Path "$temp\package.json" -Destination $target -Force
Copy-Item -Path "$temp\package-lock.json" -Destination $target -Force

# 复制目录
Copy-Item -Path "$temp\skills" -Destination "$target\skills" -Recurse -Force
Copy-Item -Path "$temp\plugins" -Destination "$target\plugins" -Recurse -Force

# 清理
Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✅ 配置同步完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📌 启动 OpenCode:" -ForegroundColor Cyan
Write-Host "   opencode"
Write-Host ""
Write-Host "📌 首次使用 Composio 时会弹出浏览器认证" -ForegroundColor Yellow
