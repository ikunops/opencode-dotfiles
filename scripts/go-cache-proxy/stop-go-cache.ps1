# go-cache-proxy stop script: stop proxy AND switch opencode-go back to direct upstream.
# Usage:
#   .\stop-go-cache.ps1            # stop proxy + restore baseURL to direct upstream
#   .\stop-go-cache.ps1 -KeepConfig  # only stop proxy, keep baseURL pointing at proxy

param(
    [switch]$KeepConfig
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $env:USERPROFILE ".config\opencode\opencode.jsonc"
$directUpstream = "https://opencode.ai/zen/go/v1"

# 1. Stop proxy process(es) - only python.exe running go-cache-proxy.py
#    (match by full python path, never powershell/cmd whose cmdline may contain the name)
$procs = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq "python.exe" -and
    $_.CommandLine -match "go-cache-proxy\.py"
}
foreach ($p in $procs) {
    if ($p.ProcessId -ne $PID) {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] stopped proxy pid=$($p.ProcessId)" -ForegroundColor Green
    }
}

# 2. Restore baseURL to direct upstream (unless -KeepConfig)
if (-not $KeepConfig) {
    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($cfg.provider.'opencode-go'.options.baseURL) {
                $cfg.provider.'opencode-go'.options.baseURL = $directUpstream
                $cfg | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
                Write-Host "[OK] baseURL restored to $directUpstream" -ForegroundColor Green
                Write-Host "[HINT] restart opencode for config change to take effect" -ForegroundColor Yellow
            } else {
                Write-Host "[WARN] no baseURL override found in config, nothing to restore" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[ERR] failed to update config: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[WARN] config not found: $configPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] proxy stopped, baseURL left as-is (proxy mode)" -ForegroundColor Green
}

Write-Host "[DONE] go-cache-proxy stopped" -ForegroundColor Green
