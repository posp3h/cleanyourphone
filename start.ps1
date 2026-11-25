# Clean Your Phone: one-command start for Claude Code (Windows).
#   irm https://raw.githubusercontent.com/posp3h/cleanyourphone/main/start.ps1 | iex
# Installs or updates the plugin, makes a work folder for backups and starts the guided session.
$ErrorActionPreference = 'Stop'
$repo = 'posp3h/cleanyourphone'
$plugin = 'cleanyourphone@cleanyourphone'

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Host "Claude Code is not installed. Install it first:" -ForegroundColor Yellow
  Write-Host "  irm https://claude.ai/install.ps1 | iex"
  Write-Host "then open a new PowerShell window and run this command again."
  return
}

Write-Host "Installing / updating the cleanyourphone plugin..." -ForegroundColor Cyan
claude plugin marketplace add $repo | Out-Null
claude plugin marketplace update cleanyourphone | Out-Null
claude plugin install $plugin | Out-Null
claude plugin update $plugin | Out-Null

$work = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'cleanyourphone'
New-Item -ItemType Directory -Force $work | Out-Null
Set-Location $work
Write-Host "Work folder (backups and logs): $work" -ForegroundColor Cyan

$lang = (Get-Culture).NativeName
claude "Run the cleanyourphone:debloat-phone skill and guide me through it step by step. My system language is ${lang}: talk to me in that language unless I write in another one."
