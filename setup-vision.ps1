# setup-vision.ps1 - one-shot installer for the vision toolkit CLIs
# (glance / ground / detect / trace / crop). Idempotent: safe to re-run.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\setup-vision.ps1
#   -Force     overwrite the existing env file (old one kept as env.bak)
#   -NoMirror  use the default PyPI index instead of the Tsinghua mirror

param(
  [switch]$Force,
  [switch]$NoMirror
)

$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:LOCALAPPDATA "agent-vision-toolkit"
$VenvDir    = Join-Path $InstallDir "venv"
$EnvFile    = Join-Path $InstallDir "env"
$VendorDir  = Join-Path $PSScriptRoot "skills\vision-tools\vendor"
$WrapDir    = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
$Mirror     = "https://pypi.tuna.tsinghua.edu.cn/simple"
$DefaultBase = "https://opencode.ai/zen/go/v1"
$DefaultModel = "kimi-k3"

function Say($msg)  { Write-Host "[vision-setup] $msg" -ForegroundColor Cyan }
function Done($msg) { Write-Host "[vision-setup] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[vision-setup] WARN: $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[vision-setup] ERROR: $msg" -ForegroundColor Red; exit 1 }

# 1. locate a real python executable
$PySrc = $null
if (Get-Command "py" -ErrorAction SilentlyContinue) {
  $PySrc = (& py -3 -c "import sys; print(sys.executable)") 2>$null
}
if (-not $PySrc -or -not (Test-Path $PySrc)) {
  if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $PySrc = (& python -c "import sys; print(sys.executable)") 2>$null
  }
}
if (-not $PySrc -or -not (Test-Path $PySrc)) {
  Fail "Python 3 not found. Install it from https://www.python.org first."
}
Say "python: $PySrc"

# 2. vendor files must exist next to this script
if (-not (Test-Path (Join-Path $VendorDir "vision_client.py"))) {
  Fail "vendor files missing at $VendorDir (clone the full dotfiles repo first)"
}

# 3. venv (once)
$PyExe = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $PyExe)) {
  Say "creating venv at $VenvDir"
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  & $PySrc -m venv $VenvDir
  if ($LASTEXITCODE -ne 0) { Fail "venv creation failed" }
  Done "venv created"
}

# 4. dependencies (fast path when already installed)
function Has-Pkg($pkg) {
  & $PyExe -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('$pkg') else 1)" 2>$null
  return ($LASTEXITCODE -eq 0)
}
$missing = @()
foreach ($pkg in @("PIL", "numpy", "vtracer")) {
  if (-not (Has-Pkg $pkg)) { $missing += $pkg }
}
if ($missing.Count -gt 0) {
  $pkgNames = switch ($missing) { "PIL" { "pillow" } default { $_ } }
  Say "installing: $($pkgNames -join ', ')"
  $pipArgs = @("-m", "pip", "install", "-q", "--upgrade")
  if (-not $NoMirror) { $pipArgs += @("-i", $Mirror) }
  & $PyExe @pipArgs $pkgNames
  if ($LASTEXITCODE -ne 0) {
    if (-not $NoMirror) {
      Warn "mirror install failed, retrying with the default PyPI index"
      & $PyExe -m pip install -q --upgrade $pkgNames
      if ($LASTEXITCODE -ne 0) { Fail "pip install failed" }
    } else { Fail "pip install failed" }
  }
  Done "dependencies installed"
} else {
  Say "dependencies already present"
}

# 5. copy patched toolkit into INSTALL_DIR (keeps upstream layout: bin/ + modules)
Copy-Item (Join-Path $VendorDir "*") -Destination $InstallDir -Recurse -Force
Remove-Item (Join-Path $InstallDir "__pycache__") -Recurse -Force -ErrorAction SilentlyContinue
Done "toolkit copied to $InstallDir"

# 6. wrappers in a PATH directory (UTF-8 output fixed here)
if (-not (Test-Path $WrapDir)) {
  New-Item -ItemType Directory -Path $WrapDir -Force | Out-Null
}
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$WrapDir*") {
  [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(';') + ";" + $WrapDir), "User")
  Say "added $WrapDir to the user PATH (new terminals pick it up)"
}
foreach ($tool in @("glance", "ground", "detect", "trace", "crop")) {
  $wrapper = "@echo off`r`nset `"PYTHONIOENCODING=utf-8`"`r`n`"$PyExe`" -X utf8 `"$InstallDir\bin\$tool`" %*`r`n"
  Set-Content -Path (Join-Path $WrapDir "$tool.cmd") -Value $wrapper -Encoding Default
}
Done "5 wrappers installed in $WrapDir"

# 7. env file: reuse the opencode-go key from auth.json, zero manual input
$key = $env:OPENCODE_GO_API_KEY
if (-not $key) {
  $authPath = Join-Path $HOME ".local\share\opencode\auth.json"
  if (Test-Path $authPath) {
    try {
      $auth = Get-Content -Raw -LiteralPath $authPath | ConvertFrom-Json
      $key = $auth."opencode-go".key
    } catch { }
  }
}
if (-not $key) {
  Warn "no opencode-go key found in auth.json; fill VISION_API_KEY in $EnvFile yourself"
}
$newEnv = @(
  "VISION_API_KEY=$key",
  "VISION_BASE_URL=$DefaultBase",
  "VISION_MODEL=$DefaultModel",
  "LANG=zh"
) -join "`r`n"
if (Test-Path $EnvFile) {
  if ($Force) {
    Copy-Item -LiteralPath $EnvFile -Destination "$EnvFile.bak" -Force
    Set-Content -LiteralPath $EnvFile -Value $newEnv -Encoding Ascii
    Done "env overwritten (backup: env.bak)"
  } else {
    Say "env file exists, keeping it (use -Force to reset to $DefaultModel defaults)"
  }
} else {
  Set-Content -LiteralPath $EnvFile -Value $newEnv -Encoding Ascii
  Done "env written: $EnvFile"
}

# 8. smoke test: every CLI must parse --help
foreach ($tool in @("glance", "ground", "detect", "trace", "crop")) {
  & $PyExe -X utf8 (Join-Path $InstallDir "bin\$tool") --help *> $null
  if ($LASTEXITCODE -eq 0) { Done "$tool OK" } else { Fail "$tool --help failed" }
}

Done "vision toolkit installed. Open a NEW terminal and try: glance <image.png>"
