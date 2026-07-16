# OpenCode 配置一键同步脚本（跨平台）
# 用法: 在新机器上运行此脚本

$repo = "https://github.com/ikunops/opencode-dotfiles.git"

# 检测操作系统
if ($IsLinux -or $IsMacOS) {
    $target = "$env:HOME/.config/opencode"
    $platform = "linux"
} else {
    $target = "$env:USERPROFILE\.config\opencode"
    $platform = "windows"
}

$temp = "$env:TEMP/opencode-sync"

Write-Host "🔄 开始同步 OpenCode 配置..." -ForegroundColor Cyan
Write-Host "📌 检测到平台: $platform" -ForegroundColor Yellow

# 检查 Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 请先安装 Node.js >= 18.0.0" -ForegroundColor Red
    Write-Host "   安装: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# 检查 OpenCode
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 请先安装 OpenCode" -ForegroundColor Red
    Write-Host "   安装: npm install -g opencode-ai" -ForegroundColor Yellow
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

# 创建目标目录
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

# 读取基础配置
$baseConfig = Get-Content "$temp/opencode.base.jsonc" | ConvertFrom-Json

# 读取平台特定配置
$platformConfig = Get-Content "$temp/platforms/$platform.jsonc" | ConvertFrom-Json

# 合并配置
$finalConfig = $baseConfig
$finalConfig.shell = $platformConfig.shell

# 保存最终配置
$finalConfig | ConvertTo-Json -Depth 10 | Set-Content "$target/opencode.jsonc"

# 复制其他文件
Copy-Item -Path "$temp/tui.jsonc" -Destination $target -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$temp/package.json" -Destination $target -Force
Copy-Item -Path "$temp/package-lock.json" -Destination $target -Force

# 复制目录
Copy-Item -Path "$temp/skills" -Destination "$target/skills" -Recurse -Force
Copy-Item -Path "$temp/plugins" -Destination "$target/plugins" -Recurse -Force

# 清理
Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✅ 配置同步完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📌 当前配置:" -ForegroundColor Cyan
Write-Host "   Shell: $($finalConfig.shell)"
Write-Host "   MCP: infra-ops + composio"
Write-Host ""
Write-Host "📌 启动 OpenCode:" -ForegroundColor Cyan
Write-Host "   opencode"
Write-Host ""
Write-Host "📌 首次使用 Composio 时会弹出浏览器认证" -ForegroundColor Yellow
