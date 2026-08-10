# go-cache-proxy start/auto-start script (Windows, PowerShell 5.1 compatible)
# Usage:
#   .\start-go-cache.ps1 -Background    # start in background
#   .\start-go-cache.ps1 -Install       # register auto-start (scheduled task)
#   .\start-go-cache.ps1 -Uninstall     # remove auto-start
#   .\start-go-cache.ps1                # foreground (debug)

param(
    [switch]$Background,
    [switch]$Install,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$proxyPy = Join-Path $scriptDir "go-cache-proxy.py"
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
    if (Test-ProxyUp) {
        Write-Host "[OK] proxy running (127.0.0.1:8787)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] proxy not started, check scheduled task" -ForegroundColor Yellow
    }
    exit 0
}

if (Test-ProxyUp) {
    Write-Host "[OK] proxy already running (127.0.0.1:8787)" -ForegroundColor Green
    exit 0
}

if ($Background) {
    Start-Process -FilePath $python -ArgumentList "`"$proxyPy`"" -WorkingDirectory $scriptDir -WindowStyle Hidden
    Start-Sleep -Seconds 4
    if (Test-ProxyUp) {
        Write-Host "[OK] background start done (127.0.0.1:8787)" -ForegroundColor Green
    } else {
        Write-Host "[ERR] background start failed" -ForegroundColor Red
    }
} else {
    & $python $proxyPy
}