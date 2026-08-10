# go-cache-proxy start/auto-start script (Windows, PowerShell 5.1 compatible)
# Usage:
#   .\start-go-cache.ps1 -Background    # start in background + switch baseURL to proxy
#   .\start-go-cache.ps1 -Install       # register auto-start (scheduled task)
#   .\start-go-cache.ps1 -Uninstall     # remove auto-start
#   .\start-go-cache.ps1 -Status        # show proxy status
#   .\start-go-cache.ps1                # foreground (debug)

param(
    [switch]$Background,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Status
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$proxyPy = Join-Path $scriptDir "go-cache-proxy.py"
$configPath = Join-Path $env:USERPROFILE ".config\opencode\opencode.jsonc"
$proxyBaseUrl = "http://127.0.0.1:8787/v1"
$taskName = "GoCacheProxy"
$startupName = "GoCacheProxy"

$python = $null
$runtimes = Get-ChildItem "$env:USERPROFILE\.cache\codex-runtimes" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($runtimes) { $python = $runtimes.FullName }
if (-not $python) {
    $cand = Get-Command python -ErrorAction SilentlyContinue
    if ($cand) { $python = $cand.Source }
}
if (-not $python) {
    try {
        $cand = Get-Command py -ErrorAction SilentlyContinue
        if ($cand) {
            $pyver = & $cand.Source -3 -c "import sys; print(sys.executable)" 2>$null
            if ($pyver) { $python = $pyver.Trim() }
        }
    } catch { }
}
if (-not $python) {
    Write-Host "[ERR] Python not found" -ForegroundColor Red
    exit 1
}

function Test-ProxyUp {
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:8787/__stats" -TimeoutSec 3
        return $true
    } catch {
        return $false
    }
}

function Get-ConfiguredBaseUrl {
    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            return $cfg.provider.'opencode-go'.options.baseURL
        } catch { }
    }
    return $null
}

function Set-BaseUrlToProxy {
    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if (-not $cfg.provider) { $cfg | Add-Member -NotePropertyName "provider" -NotePropertyValue @{} -Force }
            if (-not $cfg.provider.'opencode-go') { $cfg.provider | Add-Member -NotePropertyName "opencode-go" -NotePropertyValue @{} -Force }
            if (-not $cfg.provider.'opencode-go'.options) { $cfg.provider.'opencode-go' | Add-Member -NotePropertyName "options" -NotePropertyValue @{} -Force }
            $cfg.provider.'opencode-go'.options.baseURL = $proxyBaseUrl
            $cfg | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            Write-Host "[OK] baseURL set to $proxyBaseUrl" -ForegroundColor Green
            Write-Host "[HINT] restart opencode for config change to take effect" -ForegroundColor Yellow
        } catch {
            Write-Host "[WARN] failed to update config: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] config not found: $configPath" -ForegroundColor Yellow
    }
}

if ($Status) {
    if (Test-ProxyUp) {
        Write-Host "[OK] proxy RUNNING (127.0.0.1:8787)" -ForegroundColor Green
    } else {
        Write-Host "[ERR] proxy NOT running" -ForegroundColor Red
    }
    $cur = Get-ConfiguredBaseUrl
    if ($cur) {
        Write-Host "baseURL: $cur" -ForegroundColor Cyan
        if ($cur -like "http://127.0.0.1:8787*") {
            Write-Host "mode: PROXY (cache enabled)" -ForegroundColor Green
        } else {
            Write-Host "mode: DIRECT (no cache)" -ForegroundColor Yellow
        }
    }
    exit 0
}

if ($Uninstall) {
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\$startupName" -ErrorAction SilentlyContinue
    schtasks /Delete /TN $taskName /F 2>$null | Out-Null
    Write-Host "[OK] auto-start removed" -ForegroundColor Green
    exit 0
}

if ($Install) {
    $action = New-ScheduledTaskAction -Execute $python -Argument "`"$proxyPy`"" -WorkingDirectory $scriptDir
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Host "[OK] auto-start registered (task: $taskName)" -ForegroundColor Green
    if (-not (Test-ProxyUp)) {
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 3
    }
    Set-BaseUrlToProxy
    if (Test-ProxyUp) {
        Write-Host "[OK] proxy running (127.0.0.1:8787)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] proxy not started, check scheduled task" -ForegroundColor Yellow
    }
    exit 0
}

if ($Background) {
    if (-not (Test-ProxyUp)) {
        Start-Process -FilePath $python -ArgumentList "`"$proxyPy`"" -WorkingDirectory $scriptDir -WindowStyle Hidden
        Start-Sleep -Seconds 4
    }
    Set-BaseUrlToProxy
    if (Test-ProxyUp) {
        Write-Host "[OK] proxy running (127.0.0.1:8787), baseURL switched to proxy" -ForegroundColor Green
    } else {
        Write-Host "[ERR] proxy start failed" -ForegroundColor Red
    }
    exit 0
}

# foreground (debug): ensure proxy then run in foreground
if (-not (Test-ProxyUp)) {
    Start-Process -FilePath $python -ArgumentList "`"$proxyPy`"" -WorkingDirectory $scriptDir -WindowStyle Hidden
    Start-Sleep -Seconds 4
}
& $python $proxyPy
