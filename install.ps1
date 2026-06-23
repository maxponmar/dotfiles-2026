#Requires -Version 5.1
<#
.SYNOPSIS
  Dotfiles installer for native Windows 11 (PowerShell) - Neovim, Alacritty,
  Windows Terminal.

.DESCRIPTION
  The Windows counterpart to install.sh. Windows has no tmux and this machine
  is used natively (not through WSL), so the Neovim, Alacritty, and Windows
  Terminal configs are set up here (Windows Terminal is configured to behave
  vim/tmux-like in lieu of tmux). Dependencies are installed with winget
  (built into Win 11).

  What it does:
    - winget-installs deps (Neovim, Alacritty, Windows Terminal, Git,
      PowerShell 7, ripgrep, fd, Node)
    - installs the "MesloLGS NF" Nerd Font per-user (no admin needed)
    - links %LOCALAPPDATA%\nvim   -> <repo>\nvim   (directory junction, admin-free)
    - copies  %APPDATA%\alacritty\alacritty.toml <- <repo>\alacritty\alacritty.windows.toml
    - copies  Windows Terminal settings.json <- <repo>\windows-terminal\settings.json
    - copies  %USERPROFILE%\.markdownlint-cli2.yaml (so nvim markdown linting works)
  Anything it would overwrite is moved to %USERPROFILE%\.dotfiles-backup\<timestamp>.

.PARAMETER Nvim
  Install/link only the Neovim config.
.PARAMETER Alacritty
  Install/deploy only the Alacritty config.
.PARAMETER WindowsTerminal
  Install/deploy only the Windows Terminal config.
.PARAMETER All
  Run every component non-interactively (skips the selection menu).
.PARAMETER NoDeps
  Only deploy configs; skip winget package and font installation.
.PARAMETER DryRun
  Print what would happen without changing anything.

.NOTES
  Run with no component switch in an interactive session to get a menu that
  lets you pick exactly what to set up (e.g. just Windows Terminal). Pass a
  component switch (or -All) to skip the menu - handy for scripting.

.EXAMPLE
  .\install.ps1                 # interactive menu: pick components + options
  .\install.ps1 -WindowsTerminal  # just Windows Terminal, no menu
  .\install.ps1 -Alacritty -NoDeps
  .\install.ps1 -All -DryRun      # preview everything, change nothing
#>
[CmdletBinding()]
param(
  [switch]$Nvim,
  [switch]$Alacritty,
  [switch]$WindowsTerminal,
  [switch]$All,
  [switch]$NoDeps,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

# Was a component named on the command line? (Determines menu vs. direct run.)
$ComponentNamed = $Nvim -or $Alacritty -or $WindowsTerminal -or $All
if ($All) { $Nvim = $true; $Alacritty = $true; $WindowsTerminal = $true }

# Capture which params were passed explicitly. ($PSBoundParameters is per-scope,
# so the menu function can't see the script's args without this.)
$BoundParams = $PSBoundParameters

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

# --- interactive component selection ---------------------------------------
# Shown when the script is run with no component switch in an interactive
# session. Sets $script:Nvim/$Alacritty/$WindowsTerminal (and may toggle
# $NoDeps/$DryRun) from the user's choices. Returns $false if they quit.
function Invoke-ComponentMenu {
  Write-Host ''
  Log 'What do you want to set up?'
  Write-Host '  1) Neovim'
  Write-Host '  2) Alacritty'
  Write-Host '  3) Windows Terminal'
  Write-Host '  4) Everything'
  Write-Host '  q) Quit'
  $ans = Read-Host 'Enter numbers (comma-separated, e.g. 1,3) [default: 4]'
  if ([string]::IsNullOrWhiteSpace($ans)) { $ans = '4' }
  if ($ans -match '^\s*q') { return $false }

  foreach ($tok in ($ans -split '[,\s]+')) {
    switch ($tok.Trim()) {
      '1' { $script:Nvim = $true }
      '2' { $script:Alacritty = $true }
      '3' { $script:WindowsTerminal = $true }
      '4' { $script:Nvim = $true; $script:Alacritty = $true; $script:WindowsTerminal = $true }
      ''  { }
      default { Warn "ignoring unknown choice: $tok" }
    }
  }
  if (-not ($script:Nvim -or $script:Alacritty -or $script:WindowsTerminal)) {
    Warn 'nothing selected'; return $false
  }

  # Only prompt for toggles the user didn't already set on the command line.
  if (-not $BoundParams.ContainsKey('NoDeps')) {
    $d = Read-Host 'Install dependencies and the MesloLGS NF font? [Y/n]'
    if ($d -match '^\s*n') { $script:NoDeps = $true }
  }
  if (-not $BoundParams.ContainsKey('DryRun')) {
    $r = Read-Host 'Dry run (preview only, change nothing)? [y/N]'
    if ($r -match '^\s*y') { $script:DryRun = $true }
  }
  return $true
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
    Warn "winget not found - install 'App Installer' from the Microsoft Store, or install these manually: $($ids -join ', ')"
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

  # Already fully installed? Skip entirely so we never touch the .ttf files,
  # which a running terminal locks (re-downloading a locked font throws an
  # IOException). Re-registration is harmless if the files exist.
  $present = $files | Where-Object { Test-Path -LiteralPath (Join-Path $fontDir $_) }
  if ($present.Count -eq $files.Count) { Ok "MesloLGS NF present (skipping)"; return }

  Step "install MesloLGS NF (per-user)" {
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
    foreach ($f in $files) {
      $dst = Join-Path $fontDir $f
      # Don't re-download an existing font file - it may be locked by a
      # running terminal. Just ensure it's registered below.
      if (-not (Test-Path -LiteralPath $dst)) {
        $url = "$base/$([uri]::EscapeDataString($f))"
        try {
          Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing
        } catch [System.IO.IOException] {
          Warn "skipping $f (file is in use - close terminals using the font, or it's already installed)"
          continue
        }
      }
      $name = [IO.Path]::GetFileNameWithoutExtension($f)   # e.g. "MesloLGS NF Regular"
      New-ItemProperty -Path $regKey -Name "$name (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
    }
  }
  Ok "MesloLGS NF installed - set Alacritty/terminal font to 'MesloLGS NF'"
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

# Append the Windows Terminal shell-integration fragment to the PowerShell 7
# profile (idempotently, under a marker block). This makes PowerShell report its
# working directory (OSC 9;9) so duplicate-tab / duplicate-pane open in the
# current directory instead of the profile's startingDirectory. We append rather
# than overwrite because $PROFILE is user-owned and may already have content.
function Add-PSProfileShellIntegration {
  $marker  = '# >>> dotfiles: windows terminal shell integration >>>'
  $endmark = '# <<< dotfiles: windows terminal shell integration <<<'
  $src     = Join-Path $RepoRoot 'windows-terminal\powershell-profile.ps1'
  if (-not (Test-Path -LiteralPath $src)) { Warn "source missing, skipping: $src"; return }

  # Target PowerShell 7 (pwsh) - Windows Terminal's default profile here. Use
  # GetFolderPath so a OneDrive-redirected Documents folder resolves correctly.
  $docs        = [Environment]::GetFolderPath('MyDocuments')
  $profilePath = Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'

  if ((Test-Path -LiteralPath $profilePath) -and
      (Select-String -LiteralPath $profilePath -SimpleMatch $marker -Quiet)) {
    Ok "PowerShell profile already has WT shell integration"; return
  }

  $snippet = Get-Content -LiteralPath $src -Raw
  Step "add WT shell integration to $profilePath" {
    New-Item -ItemType Directory -Force -Path (Split-Path $profilePath -Parent) | Out-Null
    $block = "`r`n$marker`r`n$snippet`r`n$endmark`r`n"
    Add-Content -LiteralPath $profilePath -Value $block -Encoding UTF8
  }
  Ok "PowerShell profile updated - open a new pwsh tab for it to take effect"
}

# Resolve the Windows Terminal settings.json path. The Store/winget (MSIX)
# build lives under LocalState\Packages; an unpackaged build uses a plain
# LocalState dir. Prefer an existing file; otherwise default to the packaged
# location (what winget installs).
function Get-WTSettingsPath {
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
  )
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
  # Nothing installed yet: also probe for the package dir (created before the
  # file exists), else fall back to the canonical Store path.
  $pkgDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
  if (Test-Path -LiteralPath $pkgDir) { return (Join-Path $pkgDir 'settings.json') }
  return $candidates[0]
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

function Component-WindowsTerminal {
  Log "Component: windows-terminal"
  if (-not $NoDeps) {
    Install-Deps @('Microsoft.WindowsTerminal','Microsoft.PowerShell')
    Install-MesloNerdFont
  }
  # Windows Terminal regenerates its dynamic profiles on next launch, so
  # overwriting settings.json is safe; the prior file is backed up first.
  Copy-Config (Join-Path $RepoRoot 'windows-terminal\settings.json') (Get-WTSettingsPath)
  # Make new tabs/panes open in the current directory (OSC 9;9 reporting).
  Add-PSProfileShellIntegration
}

# --- run -------------------------------------------------------------------
Log "Windows dotfiles install  repo=$RepoRoot"

# No component named: show the picker when interactive, else default to all
# (so unattended/CI runs still install everything).
if (-not $ComponentNamed) {
  if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    if (-not (Invoke-ComponentMenu)) { Log 'Nothing to do - exiting.'; exit 0 }
  } else {
    $Nvim = $true; $Alacritty = $true; $WindowsTerminal = $true
  }
}

if ($DryRun) { Warn "DRY RUN - no changes will be made" }

if ($Nvim)            { Component-Nvim }
if ($Alacritty)       { Component-Alacritty }
if ($WindowsTerminal) { Component-WindowsTerminal }

Write-Host ''
Log 'Done. Next steps:'
Write-Host '  - Open a NEW terminal so PATH picks up the new tools.'
if ($Nvim)            { Write-Host '  - Launch nvim once to let Mason install LSP servers (:Mason). gopls needs Go, jdtls needs a JDK.' }
if ($Alacritty)       { Write-Host '  - Restart Alacritty; its font is set to "MesloLGS NF".' }
if ($WindowsTerminal) { Write-Host '  - Restart Windows Terminal (or it hot-reloads on save); see windows-terminal-cheatsheet.md for the vim/tmux keys.' }
Write-Host "  - Overwritten files were backed up to: $BackupRoot"
