param(
  [string]$SourceRoot = 'D:\ops-inspect\opencode-dotfiles',
  [string[]]$Targets = @(
    "$env:USERPROFILE\.config\opencode\skills",
    "$env:USERPROFILE\.claude"
  )
)

$skillSrc = Join-Path $SourceRoot 'skills\function-specific\development-workflow\ai-safety-sop'
$hookSrc = Join-Path $SourceRoot 'scripts\hookify'
$knowledgeSrc = Join-Path $SourceRoot 'knowledge\ai-safety'

Write-Host "Init ai-safety-sop from: $SourceRoot"

if (-not (Test-Path $skillSrc)) {
  throw "Missing skill source at $skillSrc"
}

foreach ($t in $Targets) {
  if (-not (Test-Path $t)) {
    New-Item -ItemType Directory -Path $t -Force | Out-Null
  }
}

$skillDest = Join-Path $Targets[0] 'ai-safety-sop'
if (Test-Path $skillDest) { Remove-Item -LiteralPath $skillDest -Recurse -Force }
Copy-Item -LiteralPath $skillSrc -Destination $skillDest -Recurse -Force

if (Test-Path $hookSrc) {
  $hookDest = Join-Path $Targets[1] 'hookify'
  if (-not (Test-Path $hookDest)) { New-Item -ItemType Directory -Path $hookDest -Force | Out-Null }
  Get-ChildItem -LiteralPath $hookSrc -Filter '*.local.md' | ForEach-Object {
    $dest = Join-Path $hookDest $_.Name
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
  }
}

if (Test-Path $knowledgeSrc) {
  $knowledgeDest = Join-Path $Targets[0] '..\knowledge\ai-safety'
  if (-not (Test-Path $knowledgeDest)) { New-Item -ItemType Directory -Path $knowledgeDest -Force | Out-Null }
  Copy-Item -LiteralPath $knowledgeSrc -Destination $knowledgeDest -Recurse -Force
}

Write-Host "Installed ai-safety-sop to: $skillDest"
Write-Host "Installed hookify rules to: $($Targets[1])\hookify"
