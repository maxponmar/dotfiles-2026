# shellcheck shell=bash
# Package-manager abstraction + user-space tooling installers.
# Sourced AFTER common.sh (uses run/log/ok/warn/die, $PM, $OS, $SUDO, $DRY_RUN,
# ensure_sudo, $TMPDIR_WORK). bash 3.2 compatible.

# --- package manager refresh + install -------------------------------------
PM_REFRESHED=0
pm_refresh() {
  [ "$PM_REFRESHED" -eq 1 ] && return 0
  ensure_sudo
  case "$PM" in
    apt)    run $SUDO apt-get update || warn "apt-get update failed" ;;
    pacman) run $SUDO pacman -Sy --noconfirm || warn "pacman -Sy failed" ;;
    zypper) run $SUDO zypper --non-interactive refresh || warn "zypper refresh failed" ;;
    brew)   run brew update || true ;;
    dnf|none) : ;;   # dnf refreshes metadata on demand
  esac
  PM_REFRESHED=1
}

pm_install() {
  [ $# -eq 0 ] && return 0
  ensure_sudo
  case "$PM" in
    apt)    run $SUDO apt-get install -y "$@"            || warn "apt-get could not install: $*" ;;
    dnf)    run $SUDO dnf install -y "$@"                || warn "dnf could not install: $*" ;;
    pacman) run $SUDO pacman -S --needed --noconfirm "$@" || warn "pacman could not install: $*" ;;
    zypper) run $SUDO zypper --non-interactive install "$@" || warn "zypper could not install: $*" ;;
    brew)   run brew install "$@"                        || warn "brew could not install: $*" ;;
    none)   warn "no package manager detected — install manually: $*" ;;
  esac
}

# Translate a logical dependency name to the concrete package name(s) for the
# current PM. Prints nothing when the dependency is unnecessary on this PM
# (e.g. python-venv is bundled outside Debian; xclip is pointless on macOS).
pkg_translate() {
  case "$1" in
    zsh|git|curl|tmux|ripgrep|unzip|luarocks|neovim|kitty|alacritty)
      printf '%s' "$1" ;;
    fontconfig)
      [ "$PM" = "brew" ] || printf 'fontconfig' ;;          # CoreText on macOS
    xclip|wl-clipboard)
      [ "$PM" = "brew" ] || printf '%s' "$1" ;;             # pbcopy on macOS
    fd)
      case "$PM" in apt|dnf) printf 'fd-find' ;; *) printf 'fd' ;; esac ;;
    python3)
      case "$PM" in pacman) printf 'python' ;; *) printf 'python3' ;; esac ;;
    python-pip)
      case "$PM" in
        apt|dnf|zypper) printf 'python3-pip' ;;
        pacman) printf 'python-pip' ;;
        brew) : ;;                                          # bundled with python
      esac ;;
    python-venv)
      case "$PM" in apt) printf 'python3-venv' ;; *) : ;; esac ;;   # separate pkg only on Debian
    node)
      case "$PM" in brew) printf 'node' ;; *) printf 'nodejs' ;; esac ;;
    npm)
      case "$PM" in brew) : ;; *) printf 'npm' ;; esac ;;   # node formula includes npm
    build)
      case "$PM" in
        apt) printf 'build-essential' ;;
        pacman) printf 'base-devel' ;;
        dnf|zypper) printf 'gcc gcc-c++ make' ;;
        brew) : ;;                                          # Xcode CLT via Homebrew bootstrap
      esac ;;
    go)
      case "$PM" in apt) printf 'golang-go' ;; dnf) printf 'golang' ;; *) printf 'go' ;; esac ;;
  esac
}

# install_deps LOGICAL...  — translate and install in one batch.
install_deps() {
  local logical p pkgs=""
  pm_refresh
  for logical in "$@"; do
    p="$(pkg_translate "$logical")"
    [ -n "$p" ] && pkgs="$pkgs $p"
  done
  pkgs="${pkgs# }"
  if [ -n "$pkgs" ]; then
    # word-splitting of $pkgs is intentional (multiple packages)
    # shellcheck disable=SC2086
    pm_install $pkgs
  fi
}

# After installing fd on Debian/Ubuntu the binary is 'fdfind'; shim it as 'fd'.
post_install_fd_symlink() {
  if [ "$PM" = "apt" ] && command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "shimmed fd -> fdfind in ~/.local/bin"
  fi
}

# --- Homebrew bootstrap (macOS) --------------------------------------------
ensure_homebrew() {
  [ "$OS" = "macos" ] || return 0
  local brewbin
  if [ "$(uname -m)" = "arm64" ]; then brewbin="/opt/homebrew/bin/brew"; else brewbin="/usr/local/bin/brew"; fi
  if ! command -v brew >/dev/null 2>&1 && [ -x "$brewbin" ]; then
    eval "$("$brewbin" shellenv)"
  fi
  if command -v brew >/dev/null 2>&1; then ok "Homebrew present"; return 0; fi
  log "Installing Homebrew"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s install Homebrew (NONINTERACTIVE)\n' "${C_DIM}[dry-run]${C_RESET}"; return 0; fi
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed"
  if [ -x "$brewbin" ]; then eval "$("$brewbin" shellenv)"; fi
  command -v brew >/dev/null 2>&1 || warn "Homebrew installed but 'brew' is not on PATH; open a new shell and re-run."
  return 0
}

# --- Neovim version handling -----------------------------------------------
NVIM_MIN_MINOR=11   # LazyVim requires >= 0.11
nvim_version_ok() {
  command -v nvim >/dev/null 2>&1 || return 1
  local line major minor
  line="$(nvim --version 2>/dev/null | head -1)"           # e.g. "NVIM v0.11.6"
  major="$(printf '%s' "$line" | sed -nE 's/.*v([0-9]+)\.([0-9]+)\..*/\1/p')"
  minor="$(printf '%s' "$line" | sed -nE 's/.*v([0-9]+)\.([0-9]+)\..*/\2/p')"
  [ -n "$major" ] && [ -n "$minor" ] || return 1
  [ "$major" -gt 0 ] && return 0
  [ "$minor" -ge "$NVIM_MIN_MINOR" ]
}

install_neovim_tarball() {
  local arch url tmp dirname
  case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "no prebuilt Neovim for arch $(uname -m); install manually"; return 1 ;;
  esac
  url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz"
  dirname="nvim-linux-${arch}"
  log "Installing latest Neovim ($arch tarball) into ~/.local"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s download+extract %s\n' "${C_DIM}[dry-run]${C_RESET}" "$url"; return 0; fi
  tmp="$TMPDIR_WORK/nvim.tar.gz"
  curl -fL "$url" -o "$tmp" || { warn "Neovim tarball download failed"; return 1; }
  mkdir -p "$HOME/.local" "$HOME/.local/bin"
  rm -rf "$HOME/.local/$dirname"
  tar -xzf "$tmp" -C "$HOME/.local" || { warn "Neovim tarball extract failed"; return 1; }
  ln -sf "$HOME/.local/$dirname/bin/nvim" "$HOME/.local/bin/nvim"
  ok "Neovim installed at ~/.local/bin/nvim"
}

ensure_neovim() {
  if nvim_version_ok; then ok "Neovim $(nvim --version | head -1 | awk '{print $2}') is recent enough"; return 0; fi
  install_deps neovim
  if nvim_version_ok; then ok "Neovim installed from $PM"; return 0; fi
  if [ "$PM" = "apt" ]; then
    warn "distro Neovim is missing/too old — trying the neovim-ppa/unstable PPA"
    pm_install software-properties-common
    run $SUDO add-apt-repository -y ppa:neovim-ppa/unstable || warn "add-apt-repository failed"
    run $SUDO apt-get update || true
    pm_install neovim
  fi
  if ! nvim_version_ok && [ "$OS" != "macos" ]; then
    install_neovim_tarball || true
  fi
  if nvim_version_ok; then
    ok "Neovim is now recent enough"
  else
    warn "Could not ensure Neovim >= 0.$NVIM_MIN_MINOR — LazyVim/fff.nvim may not work. Install Neovim manually."
  fi
}

# --- git clone helpers ------------------------------------------------------
git_clone_or_pull() {
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    run git -C "$dir" pull --ff-only || warn "git pull failed for $dir (leaving as-is)"
  else
    if [ -e "$dir" ]; then warn "removing partial/non-git dir: $dir"; run rm -rf "$dir"; fi
    run git clone --depth=1 "$url" "$dir" || warn "git clone failed: $url"
  fi
}

# --- Oh My Zsh + theme + plugins + fzf -------------------------------------
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then ok "Oh My Zsh present"; return 0; fi
  log "Installing Oh My Zsh (unattended; keeps existing ~/.zshrc)"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s install oh-my-zsh\n' "${C_DIM}[dry-run]${C_RESET}"; return 0; fi
  # RUNZSH=no: don't exec zsh (would hang). CHSH=no: don't change shell here.
  # KEEP_ZSHRC=yes: don't touch ~/.zshrc (we symlink our own).
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || die "Oh My Zsh install failed"
}

install_zsh_extras() {
  git_clone_or_pull https://github.com/romkatv/powerlevel10k.git           "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
  git_clone_or_pull https://github.com/zsh-users/zsh-autosuggestions       "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  git_clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
  git_clone_or_pull https://github.com/agkozak/zsh-z                       "$ZSH_CUSTOM_DIR/plugins/zsh-z"
}

install_fzf() {
  git_clone_or_pull https://github.com/junegunn/fzf.git "$HOME/.fzf"
  # --no-update-rc: don't edit ~/.zshrc (it already sources ~/.fzf.zsh).
  # keep zsh enabled so ~/.fzf.zsh IS generated (do NOT pass --no-zsh).
  run "$HOME/.fzf/install" --key-bindings --completion --no-update-rc \
    || warn "fzf install script failed"
}

# --- fonts ------------------------------------------------------------------
FONT_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
FONT_FILES_REGULAR="MesloLGS NF Regular.ttf"
print_wsl_font_instructions() {
  cat <<EOF
  ${C_YELLOW}WSL detected — install the terminal font on WINDOWS, not inside WSL.${C_RESET}
  Fonts inside WSL do not affect Windows Terminal / VS Code rendering.

  1) Download these 4 files (open in a browser or 'explorer.exe' them):
       $FONT_BASE/MesloLGS%20NF%20Regular.ttf
       $FONT_BASE/MesloLGS%20NF%20Bold.ttf
       $FONT_BASE/MesloLGS%20NF%20Italic.ttf
       $FONT_BASE/MesloLGS%20NF%20Bold%20Italic.ttf
  2) Select all 4 -> right-click -> Install (for all users).
  3) Set the font to "MesloLGS NF":
       - Windows Terminal: Settings -> your profile -> Appearance -> Font face
       - VS Code: "terminal.integrated.fontFamily": "MesloLGS NF"
  4) Reopen the terminal, then run: p10k configure
EOF
}

install_fonts() {
  if [ "$OS" = "wsl" ]; then print_wsl_font_instructions; return 0; fi
  if [ "$OS" = "macos" ]; then
    run brew install --cask font-meslo-lg-nerd-font || warn "Meslo Nerd Font cask install failed"
    ok "Set your terminal font to 'MesloLGS NF'"
    return 0
  fi
  # Linux desktop: install into ~/.local/share/fonts with decoded filenames.
  local dir="$HOME/.local/share/fonts" name enc
  run mkdir -p "$dir"
  for name in \
    "MesloLGS NF Regular.ttf" \
    "MesloLGS NF Bold.ttf" \
    "MesloLGS NF Italic.ttf" \
    "MesloLGS NF Bold Italic.ttf"; do
    enc="$(printf '%s' "$name" | sed 's/ /%20/g')"
    run curl -fL "$FONT_BASE/$enc" -o "$dir/$name" || warn "font download failed: $name"
  done
  if command -v fc-cache >/dev/null 2>&1; then run fc-cache -f "$dir" || true; fi
  ok "MesloLGS NF installed; set your terminal font to 'MesloLGS NF'"
}

# --- Kitty terminal ---------------------------------------------------------
install_kitty() {
  if command -v kitty >/dev/null 2>&1; then ok "kitty present"; return 0; fi
  case "$PM" in
    brew) run brew install --cask kitty || warn "kitty cask install failed" ;;
    none) warn "no package manager detected — install kitty manually" ;;
    *)    install_deps kitty ;;
  esac
}

# --- Alacritty terminal -----------------------------------------------------
install_alacritty() {
  if command -v alacritty >/dev/null 2>&1; then ok "alacritty present"; return 0; fi
  case "$PM" in
    brew) run brew install --cask alacritty || warn "alacritty cask install failed" ;;
    none) warn "no package manager detected — install alacritty manually" ;;
    *)    install_deps alacritty ;;
  esac
}

# Echo the WSL path to the Windows %APPDATA% directory (where the native Windows
# Alacritty reads its config), or nothing if it can't be determined. cmd.exe is
# run from a Windows-accessible cwd to avoid the "UNC paths are not supported"
# warning that fires when the cwd is a Linux path.
win_appdata_path() {
  command -v wslpath >/dev/null 2>&1 || return 0
  local win wslp
  win="$( (cd /mnt/c 2>/dev/null && cmd.exe /c "echo %APPDATA%") 2>/dev/null | tr -d '\r' )"
  [ -n "$win" ] || return 0
  case "$win" in *%APPDATA%*) return 0 ;; esac   # variable didn't expand
  wslp="$(wslpath -u "$win" 2>/dev/null)" || return 0
  printf '%s\n' "$wslp"
}

# --- Claude Code CLI --------------------------------------------------------
install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code present ($(claude --version 2>/dev/null | head -1))"
    return 0
  fi
  log "Installing Claude Code (native installer)"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s curl -fsSL https://claude.ai/install.sh | bash\n' "${C_DIM}[dry-run]${C_RESET}"; return 0; fi
  curl -fsSL https://claude.ai/install.sh | bash \
    || warn "Claude Code install failed — install manually from https://claude.com/claude-code"
}

# --- optional toolchains (heavy; only for some LSP servers) ------------------
install_go()     { install_deps go; }
install_dotnet() {
  case "$PM" in
    apt)    pm_install dotnet-sdk-8.0 ;;
    dnf)    pm_install dotnet-sdk-8.0 ;;
    pacman) pm_install dotnet-sdk ;;
    brew)   run brew install --cask dotnet-sdk || warn "dotnet-sdk cask failed" ;;
    *)      warn ".NET SDK is not reliably packaged here — install manually if you need C#/F# LSPs" ;;
  esac
}

# --- Neovim plugin bootstrap (headless) ------------------------------------
bootstrap_nvim() {
  command -v nvim >/dev/null 2>&1 || { warn "nvim not found; skipping plugin bootstrap"; return 0; }
  log "Bootstrapping Neovim plugins (this builds fff.nvim + treesitter; may take a minute)"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s nvim --headless +Lazy! sync +qa\n' "${C_DIM}[dry-run]${C_RESET}"; return 0; fi
  # +Lazy! (bang) blocks until sync finishes; nonzero exit is often benign.
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "Neovim plugin sync returned nonzero (often harmless)"
  ok "Neovim plugins synced. LSP servers install via Mason on first launch (:Mason)."
}
