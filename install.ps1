#Requires -Version 5.1
<#
.SYNOPSIS
  Dotfiles installer for native Windows 11 (PowerShell) — Neovim + Alacritty.

.DESCRIPTION
  The Windows counterpart to install.sh. Windows has no tmux and this machine
  is used natively (not through WSL), so only the Neovim and Alacritty configs
  are set up here. Dependencies are installed with winget (built into Win 11).

  What it does:
    - winget-installs deps (Neovim, Alacritty, Git, PowerShell 7, ripgrep, fd, Node)
    - installs the "MesloLGS NF" Nerd Font per-user (no admin needed)
    - links %LOCALAPPDATA%\nvim   -> <repo>\nvim   (directory junction, admin-free)
    - copies  %APPDATA%\alacritty\alacritty.toml <- <repo>\alacritty\alacritty.windows.toml
    - copies  %USERPROFILE%\.markdownlint-cli2.yaml (so nvim markdown linting works)
  Anything it would overwrite is moved to %USERPROFILE%\.dotfiles-backup\<timestamp>.

.PARAMETER Nvim
  Install/link only the Neovim config.
.PARAMETER Alacritty
  Install/deploy only the Alacritty config.
.PARAMETER NoDeps
  Only deploy configs; skip winget package and font installation.
.PARAMETER DryRun
  Print what would happen without changing anything.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -Alacritty -NoDeps
  .\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [switch]$Nvim,
  [switch]$Alacritty,
  [switch]$NoDeps,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

# Default to all components when none is named.
if (-not ($Nvim -or $Alacritty)) { $Nvim = $true; $Alacritty = $true }

# --- logging ---------------------------------------------------------------
function Log  ($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "  ok $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  !! $m" -ForegroundColor Yellow }
function Die  ($m) { Write-Host "xx $m"   -ForegroundColor Red; exit 1 }

# Run an action unless -DryRun; $desc is printed either way.
function Step([string]$desc, [scriptblock]$action) {
  if ($DryRun) { Write-Host "[dry-run] $desc" -ForegroundColor DarkGray; return }
  Write-Host "  -> $desc" -ForegroundColor DarkGray
  & $action
}

# --- backup ----------------------------------------------------------------
$Timestamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = Join-Path $env:USERPROFILE ".dotfiles-backup\$Timestamp"

# Move an existing path (file or dir, incl. existing links) into the backup tree.
function Backup-IfExists([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return }
  $dest = Join-Path $BackupRoot (Split-Path $path -Leaf)
  Step "backup $path -> $dest" {
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    Move-Item -LiteralPath $path -Destination $dest -Force
  }
  Ok "backed up $path"
}

# --- winget dependency install ---------------------------------------------
function Test-WingetInstalled([string]$id) {
  $out = winget list --id $id -e --source winget 2>$null
  return ($LASTEXITCODE -eq 0 -and ($out -match [regex]::Escape($id)))
}

function Install-WingetPackage([string]$id) {
  if (Test-WingetInstalled $id) { Ok "$id present"; return }
  Step "winget install $id" {
    winget install --id $id -e --source winget `
      --accept-package-agreements --accept-source-agreements --silent | Out-Null
  }
}

function Install-Deps([string[]]$ids) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found — install 'App Installer' from the Microsoft Store, or install these manually: $($ids -join ', ')"
    return
  }
  foreach ($id in $ids) { Install-WingetPackage $id }
}

# --- Nerd Font (per-user, no admin) ----------------------------------------
function Install-MesloNerdFont {
  $base = 'https://github.com/romkatv/powerlevel10k-media/raw/master'
  $files = @(
    'MesloLGS NF Regular.ttf',
    'MesloLGS NF Bold.ttf',
    'MesloLGS NF Italic.ttf',
    'MesloLGS NF Bold Italic.ttf'
  )
  $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $regKey  = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  Step "install MesloLGS NF (per-user)" {
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
    foreach ($f in $files) {
      $dst = Join-Path $fontDir $f
      $url = "$base/$([uri]::EscapeDataString($f))"
      Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing
      $name = [IO.Path]::GetFileNameWithoutExtension($f)   # e.g. "MesloLGS NF Regular"
      New-ItemProperty -Path $regKey -Name "$name (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
    }
  }
  Ok "MesloLGS NF installed — set Alacritty/terminal font to 'MesloLGS NF'"
}

# --- linking helpers -------------------------------------------------------
# Directory junction: works without admin or Developer Mode (unlike symlinks).
function Link-Dir([string]$src, [string]$dst) {
  if (-not (Test-Path -LiteralPath $src)) { Warn "source missing, skipping: $src"; return }
  $existing = Get-Item -LiteralPath $dst -ErrorAction SilentlyContinue
  if ($existing -and $existing.LinkType -and (Get-Item -LiteralPath $dst).Target -eq $src) {
    Ok "already linked: $dst"; return
  }
  Backup-IfExists $dst
  Step "junction $dst -> $src" {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
  }
  Ok "linked $dst -> $src"
}

function Copy-Config([string]$src, [string]$dst) {
  if (-not (Test-Path -LiteralPath $src)) { Warn "source missing, skipping: $src"; return }
  Backup-IfExists $dst
  Step "copy $dst <- $src" {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  Ok "copied $dst"
}

# --- components ------------------------------------------------------------
function Component-Nvim {
  Log "Component: nvim"
  if (-not $NoDeps) {
    Install-Deps @('Git.Git','Neovim.Neovim','OpenJS.NodeJS','BurntSushi.ripgrep.MSVC','sharkdp.fd')
  }
  Link-Dir  (Join-Path $RepoRoot 'nvim') (Join-Path $env:LOCALAPPDATA 'nvim')
  Copy-Config (Join-Path $RepoRoot 'markdownlint\.markdownlint-cli2.yaml') (Join-Path $env:USERPROFILE '.markdownlint-cli2.yaml')
}

function Component-Alacritty {
  Log "Component: alacritty"
  if (-not $NoDeps) {
    Install-Deps @('Alacritty.Alacritty','Microsoft.PowerShell')
    Install-MesloNerdFont
  }
  Copy-Config (Join-Path $RepoRoot 'alacritty\alacritty.windows.toml') (Join-Path $env:APPDATA 'alacritty\alacritty.toml')
}

# --- run -------------------------------------------------------------------
Log "Windows dotfiles install  repo=$RepoRoot"
if ($DryRun) { Warn "DRY RUN — no changes will be made" }

if ($Nvim)      { Component-Nvim }
if ($Alacritty) { Component-Alacritty }

Write-Host ''
Log 'Done. Next steps:'
Write-Host '  - Open a NEW terminal so PATH picks up the new tools.'
if ($Nvim)      { Write-Host '  - Launch nvim once to let Mason install LSP servers (:Mason). gopls needs Go, jdtls needs a JDK.' }
if ($Alacritty) { Write-Host '  - Restart Alacritty; its font is set to "MesloLGS NF".' }
Write-Host "  - Overwritten files were backed up to: $BackupRoot"
