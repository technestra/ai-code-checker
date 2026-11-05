param(
    [string]$ClaudeDir = (Join-Path $HOME ".claude"),
    [switch]$Force
)
$ErrorActionPreference = "Stop"

$skillSrc = Join-Path $PSScriptRoot "skills\ai-code-checker"
$agentSrc = Join-Path $PSScriptRoot "agents"
if (-not (Test-Path (Join-Path $skillSrc "SKILL.md"))) { throw "SKILL.md not found in $skillSrc" }
$agentFiles = @(Get-ChildItem $agentSrc -Filter *.md)
if ($agentFiles.Count -eq 0) { throw "No agent files found in $agentSrc" }

$skillTarget = Join-Path $ClaudeDir "skills\ai-code-checker"
$agentDir = Join-Path $ClaudeDir "agents"
$targets = @($skillTarget) + @($agentFiles | ForEach-Object { Join-Path $agentDir $_.Name })

$existing = @($targets | Where-Object { Test-Path $_ })
if ($existing.Count -gt 0 -and -not $Force) {
    Write-Host "Already installed:"
    $existing | ForEach-Object { Write-Host "  $_" }
    Write-Host "Re-run with -Force to overwrite."
    exit 1
}

New-Item -ItemType Directory -Force (Split-Path $skillTarget), $agentDir | Out-Null
if (Test-Path $skillTarget) { Remove-Item $skillTarget -Recurse -Force }
Copy-Item $skillSrc $skillTarget -Recurse
Copy-Item $agentFiles.FullName $agentDir -Force

Write-Host "Installed skill and agents under $ClaudeDir"
Write-Host "Restart Claude Code, then run /ai-code-checker, or ask: Use the ai-code-fixer agent to fix the report."
