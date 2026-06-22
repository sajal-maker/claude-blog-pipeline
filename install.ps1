# blog-pipeline installer — copies the 6 blog commands into your Claude Code commands folder.
# Works for both public and private repos (uses your own git login for private).
#
# Run it with one line in PowerShell:
#   irm https://raw.githubusercontent.com/sajal-maker/claude-blog-pipeline/main/install.ps1 | iex
#
# (For a PRIVATE repo, clone instead — see README "Install for your team".)

$ErrorActionPreference = "Stop"
$repo = "https://github.com/sajal-maker/claude-blog-pipeline.git"
$tmp  = Join-Path $env:TEMP "claude-blog-pipeline"

Write-Host "Fetching blog-pipeline..." -ForegroundColor Cyan
if (Test-Path $tmp) { git -C $tmp pull --quiet } else { git clone --quiet $repo $tmp }

$dest = Join-Path $env:USERPROFILE ".claude\commands"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $tmp "commands\*.md") $dest -Force

Write-Host "Installed these commands into $dest :" -ForegroundColor Green
Get-ChildItem $dest -Filter "*.md" | Where-Object { $_.BaseName -in @("brand-analyze","blog-topics","blog-write","blog-banner","blog-json","blog-score") } | ForEach-Object { "  /$($_.BaseName)" }
Write-Host "`nDone. Restart Claude Code, then type '/' to see the commands." -ForegroundColor Green
