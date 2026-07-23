param()

$skillDest = Join-Path $env:USERPROFILE '.config\opencode\skills\ai-safety-sop'
$hookDest = Join-Path $env:USERPROFILE '.claude\hookify'

$ok = $true
if (-not (Test-Path (Join-Path $skillDest 'SKILL.md'))) {
  Write-Host "Missing skill: $skillDest\SKILL.md"
  $ok = $false
}
if (-not (Test-Path $hookDest)) {
  Write-Host "Missing hookify dir: $hookDest"
  $ok = $false
}
if ($ok) { Write-Host 'ai-safety-sok validate: OK' } else { Write-Host 'ai-safety-sok validate: FAIL'; exit 1 }
