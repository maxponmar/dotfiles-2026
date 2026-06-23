#!/usr/bin/env bash
#
# Dotfiles installer — zsh, tmux, Neovim, Claude Code, Kitty, Alacritty, aliases.
# Cross-platform: Linux, WSL2 (Windows), macOS. Auto-detects OS + package
# manager. Backs up anything it would overwrite and records a manifest so the
# install can be undone with ./uninstall.sh.
#
# Usage:
#   ./install.sh [components] [options]
#
# Components (default: all):
#   --zsh        zsh + Oh My Zsh + Powerlevel10k + plugins + fzf + font, link .zshrc/.p10k.zsh
#   --tmux       tmux, link .tmux.conf
#   --nvim       Neovim (LazyVim) + tools, link ~/.config/nvim + markdownlint config
#   --claude     Claude Code CLI, link ~/.claude/settings.json
#   --kitty      Kitty terminal, link ~/.config/kitty/kitty.conf
#   --alacritty  Alacritty (Windows+WSL): copy config to Windows %APPDATA%, default distro Ubuntu
#   --aliases    just the shell aliases (source block in ~/.zshrc; implied by --zsh)
#   --all        all of the above (default when no component is given)
#
# Options:
#   --no-deps    only create symlinks; skip installing packages/tools
#   --with-go    also install the Go toolchain (for the gopls LSP)
#   --with-dotnet  also install the .NET SDK (for C#/F# LSPs)
#   --wsl-distro <name>  WSL distro Alacritty launches / sets default (default: Ubuntu)
#   --dry-run    print what would happen without changing anything
#   --restore    undo the most recent install (same as ./uninstall.sh)
#   --list-backups   show available backups and exit
#   -h, --help   show this help
#
set -euo pipefail
set -E   # inherit ERR trap into functions

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
export DOTFILES="$SCRIPT_DIR"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/packages.sh
. "$SCRIPT_DIR/scripts/lib/packages.sh"

# user-space binaries (fd shim, neovim tarball, claude) land here
export PATH="$HOME/.local/bin:$PATH"

# Print the leading comment block (from line 3 to the first non-comment line),
# stripping the leading "# ". Resilient to the header growing/shrinking.
usage() { awk 'NR>=3 { if (/^#/) { sub(/^# ?/,""); print; next } else exit }' "$0"; }

# --- defaults / flags -------------------------------------------------------
DO_ALL=0; DO_ZSH=0; DO_TMUX=0; DO_NVIM=0; DO_CLAUDE=0; DO_KITTY=0; DO_ALACRITTY=0; DO_ALIASES=0
WITH_DEPS=1; WITH_GO=0; WITH_DOTNET=0
RESTORE=0; LIST=0; FORCE=0
WSL_DISTRO="Ubuntu"   # which WSL distro Alacritty launches / is set as default
DRY_RUN="${DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --all)        DO_ALL=1 ;;
    --zsh)        DO_ZSH=1 ;;
    --tmux)       DO_TMUX=1 ;;
    --nvim)       DO_NVIM=1 ;;
    --claude)     DO_CLAUDE=1 ;;
    --kitty)      DO_KITTY=1 ;;
    --alacritty)  DO_ALACRITTY=1 ;;
    --aliases)    DO_ALIASES=1 ;;
    --no-deps)    WITH_DEPS=0 ;;
    --deps)       WITH_DEPS=1 ;;
    --with-go)    WITH_GO=1 ;;
    --with-dotnet) WITH_DOTNET=1 ;;
    --wsl-distro) shift; WSL_DISTRO="${1:-}"; [ -n "$WSL_DISTRO" ] || { err "--wsl-distro needs a name"; exit 2; } ;;
    --dry-run)    DRY_RUN=1 ;;
    --restore)    RESTORE=1 ;;
    --force)      FORCE=1 ;;
    --list-backups) LIST=1 ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; break ;;
    -*)           err "unknown option: $1"; usage; exit 2 ;;
    *)            err "unexpected argument: $1"; usage; exit 2 ;;
  esac
  shift
done
export DRY_RUN FORCE WSL_DISTRO

# default to everything if no component and not a maintenance action
if [ "$DO_ALL$DO_ZSH$DO_TMUX$DO_NVIM$DO_CLAUDE$DO_KITTY$DO_ALACRITTY$DO_ALIASES" = "00000000" ] \
   && [ "$RESTORE" -eq 0 ] && [ "$LIST" -eq 0 ]; then
  DO_ALL=1
fi
if [ "$DO_ALL" -eq 1 ]; then
  DO_ZSH=1; DO_TMUX=1; DO_NVIM=1; DO_CLAUDE=1; DO_KITTY=1; DO_ALACRITTY=1
fi

common_init
detect_os
detect_pkg_manager
detect_sudo

# --- maintenance actions ----------------------------------------------------
if [ "$LIST" -eq 1 ]; then
  log "Backups under ~/.dotfiles-backup:"; list_backups; exit 0
fi
if [ "$RESTORE" -eq 1 ]; then
  m="$(latest_manifest || true)"
  [ -n "${m:-}" ] || die "No backups found in ~/.dotfiles-backup."
  do_restore "$m"
  exit 0
fi

log "OS=${C_BOLD}$OS${C_RESET}  package-manager=${C_BOLD}$PM${C_RESET}  dotfiles=${C_DIM}$DOTFILES${C_RESET}"
if [ "$DRY_RUN" -eq 1 ]; then warn "DRY RUN — no changes will be made"; fi
if [ "$PM" = "none" ] && [ "$WITH_DEPS" -eq 1 ]; then
  warn "No supported package manager; dependencies must be installed manually."
fi

init_backup
if [ "$OS" = "macos" ] && [ "$WITH_DEPS" -eq 1 ]; then ensure_homebrew; fi

# --- components -------------------------------------------------------------
component_zsh() {
  log "Component: ${C_BOLD}zsh${C_RESET}"
  if [ "$WITH_DEPS" -eq 1 ]; then
    install_deps zsh git curl
    install_ohmyzsh
    install_zsh_extras
    install_fzf
    install_fonts
  fi
  link_file "$DOTFILES/zsh/.zshrc"   "$HOME/.zshrc"
  link_file "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  ensure_canonical_path
  if [ "$WITH_DEPS" -eq 1 ]; then maybe_chsh_zsh; fi
  return 0
}

component_tmux() {
  log "Component: ${C_BOLD}tmux${C_RESET}"
  if [ "$WITH_DEPS" -eq 1 ]; then install_deps tmux; fi
  link_file "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
  return 0
}

component_nvim() {
  log "Component: ${C_BOLD}nvim${C_RESET}"
  if [ "$WITH_DEPS" -eq 1 ]; then
    install_deps git curl ripgrep fd unzip fontconfig \
                 python3 python-pip python-venv node npm luarocks build \
                 xclip wl-clipboard
    post_install_fd_symlink
    ensure_neovim
    if [ "$WITH_GO" -eq 1 ]; then install_go; fi
    if [ "$WITH_DOTNET" -eq 1 ]; then install_dotnet; fi
  fi
  link_file "$DOTFILES/nvim" "$HOME/.config/nvim"
  link_file "$DOTFILES/markdownlint/.markdownlint-cli2.yaml" "$HOME/.markdownlint-cli2.yaml"
  if [ "$WITH_DEPS" -eq 1 ]; then bootstrap_nvim; fi
  check_lang_toolchains
  return 0
}

# Some LazyVim language extras need a compiler/runtime that Mason can't provide
# itself (e.g. gopls is built with `go`, jdtls runs on a JDK). Mason "installs"
# happen lazily on first nvim launch, so a missing toolchain shows up as a
# confusing runtime error rather than an install failure. Probe the extras that
# are actually enabled in lazy.lua and warn up front. Informational only.
check_lang_toolchains() {
  local lazy="$DOTFILES/nvim/lua/config/lazy.lua"
  [ -f "$lazy" ] || return 0
  local triple extra rest cmd label missing=0
  # "extra-name|command-to-probe|how to install it"
  for triple in \
    "lang.go|go|Go — re-run with --with-go (or: brew install go)" \
    "lang.cmake|cmake|CMake — install via your package manager (brew install cmake)" \
    "lang.dotnet|dotnet|.NET SDK — re-run with --with-dotnet"; do
    extra="${triple%%|*}"; rest="${triple#*|}"; cmd="${rest%%|*}"; label="${rest#*|}"
    grep -E "extras\.$extra\"" "$lazy" | grep -qv '^[[:space:]]*--' || continue
    command -v "$cmd" >/dev/null 2>&1 && continue
    warn "nvim extra '$extra' enabled but '$cmd' not found — $label"
    missing=1
  done
  # Java is special-cased: on macOS /usr/bin/java is a stub that satisfies
  # 'command -v java' but has no runtime, so probe the runtime directly.
  if grep -E 'extras\.lang\.java"' "$lazy" | grep -qv '^[[:space:]]*--'; then
    if ! java -version >/dev/null 2>&1; then
      warn "nvim extra 'lang.java' enabled but no working JDK — jdtls needs JDK 17+ (brew install --cask temurin)"
      missing=1
    fi
  fi
  [ "$missing" -eq 0 ] && ok "nvim language-extra toolchains look present"
  return 0
}

component_claude() {
  log "Component: ${C_BOLD}claude${C_RESET}"
  if [ "$WITH_DEPS" -eq 1 ]; then
    install_deps python3 curl   # statusline.py runs via python3
    install_claude_code
  fi
  link_file "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  ensure_canonical_path   # statusline.py is referenced by absolute path
  return 0
}

component_kitty() {
  log "Component: ${C_BOLD}kitty${C_RESET}"
  if [ "$WITH_DEPS" -eq 1 ]; then
    install_kitty
    install_fonts   # kitty.conf uses MesloLGS Nerd Font
  fi
  link_file "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  return 0
}

component_alacritty() {
  log "Component: ${C_BOLD}alacritty${C_RESET}"
  local src="$DOTFILES/alacritty/alacritty.toml"
  if [ "$OS" = "wsl" ]; then
    # Alacritty is a native Windows app here, so its config lives on the Windows
    # side. Copy (not symlink — NTFS can't follow a WSL link) into %APPDATA%,
    # substituting the chosen WSL distro into the shell args first.
    local appdata rendered="$TMPDIR_WORK/alacritty.toml"
    sed 's/-d", "Ubuntu"/-d", "'"$WSL_DISTRO"'"/' "$src" > "$rendered"
    appdata="$(win_appdata_path)"
    if [ -n "$appdata" ]; then
      copy_file "$rendered" "$appdata/alacritty/alacritty.toml"
    else
      warn "Could not locate Windows %APPDATA%."
      warn "Copy $src to %APPDATA%\\alacritty\\alacritty.toml on Windows yourself (set the distro to '$WSL_DISTRO')."
    fi
    [ "$WITH_DEPS" -eq 1 ] && print_wsl_font_instructions
    # Make the chosen distro the default so plain `wsl` (and Alacritty) use it.
    if command -v wsl.exe >/dev/null 2>&1; then
      log "Setting '$WSL_DISTRO' as the default WSL distro"
      run wsl.exe --set-default "$WSL_DISTRO" \
        || warn "Could not set default WSL distro to '$WSL_DISTRO' (check the name with: wsl.exe -l -v)"
    fi
    return 0
  fi
  if [ "$OS" = "macos" ]; then
    warn "alacritty: skipping on macOS — this config targets Windows+WSL (its shell is wsl.exe)."
    return 0
  fi
  # Native Linux: install + symlink, but the wsl.exe shell line won't apply here.
  if [ "$WITH_DEPS" -eq 1 ]; then install_alacritty; install_fonts; fi
  link_file "$src" "$HOME/.config/alacritty/alacritty.toml"
  warn "alacritty.toml sets [terminal.shell] to wsl.exe (for Windows). On native Linux, edit that out."
  return 0
}

component_aliases() {
  # Standalone aliases only make sense without the full zsh config; with --zsh
  # the symlinked ~/.zshrc already sources them.
  if [ "$DO_ZSH" -eq 1 ]; then return 0; fi
  log "Component: ${C_BOLD}aliases${C_RESET}"
  ensure_canonical_path
  install_aliases_block
  return 0
}

# chsh helper (kept here so it sees $OS/$DRY_RUN)
maybe_chsh_zsh() {
  [ "$OS" = "macos" ] && return 0   # zsh is already the default on Catalina+
  local zsh_path; zsh_path="$(command -v zsh 2>/dev/null || true)"
  [ -n "$zsh_path" ] || return 0
  case "${SHELL:-}" in *zsh) return 0 ;; esac
  log "Setting default shell to zsh ($zsh_path)"
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s chsh -s %s\n' "${C_DIM}[dry-run]${C_RESET}" "$zsh_path"; return 0; fi
  chsh -s "$zsh_path" || warn "chsh failed — run 'chsh -s $zsh_path' yourself, then re-login"
  return 0
}

if [ "$DO_ZSH" -eq 1 ];     then component_zsh;     fi
if [ "$DO_TMUX" -eq 1 ];    then component_tmux;    fi
if [ "$DO_NVIM" -eq 1 ];    then component_nvim;    fi
if [ "$DO_CLAUDE" -eq 1 ];  then component_claude;  fi
if [ "$DO_KITTY" -eq 1 ];   then component_kitty;   fi
if [ "$DO_ALACRITTY" -eq 1 ]; then component_alacritty; fi
if [ "$DO_ALIASES" -eq 1 ]; then component_aliases; fi

# --- summary ----------------------------------------------------------------
echo
log "${C_GREEN}Done.${C_RESET} Next steps:"
printf '  - Restart your terminal (or run: exec zsh) to load the new shell config.\n'
if [ "$OS" = "wsl" ]; then
  printf '  - WSL: install MesloLGS NF on Windows and set it as your terminal font (see above).\n'
elif [ "$DO_ZSH" -eq 1 ]; then
  printf '  - Set your terminal font to "MesloLGS NF" for Powerlevel10k icons.\n'
fi
if [ "$DO_NVIM" -eq 1 ];   then printf '  - Open nvim once to let Mason finish installing LSP servers (:Mason).\n'; fi
if [ "$DO_CLAUDE" -eq 1 ]; then printf '  - Run "claude" to start Claude Code (config is symlinked).\n'; fi
if [ "$DO_KITTY" -eq 1 ];  then printf '  - Restart Kitty (or ctrl+shift+f5) to load kitty.conf.\n'; fi
if [ "$DO_ALACRITTY" -eq 1 ] && [ "$OS" = "wsl" ]; then printf '  - Alacritty: install "MesloLGS NF" on Windows (links above), then restart Alacritty.\n'; fi
printf '  - To undo this install: %s./uninstall.sh%s (backups are in ~/.dotfiles-backup).\n' "$C_BOLD" "$C_RESET"
