# shellcheck shell=bash
# Shared helpers for the dotfiles installer/uninstaller.
# bash 3.2 compatible (macOS ships bash 3.2): no associative arrays, no
# mapfile, no ${v,,}/${v^^}, no negative array indices, no GNU-only flags.
# Sourced by install.sh and uninstall.sh, which must export $DOTFILES first.

# --- colors / logging -------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=; C_DIM=; C_BOLD=; C_RED=; C_GREEN=; C_YELLOW=; C_BLUE=
fi

log()  { printf '%s %s\n' "${C_BLUE}==>${C_RESET}" "$*"; }
ok()   { printf '%s %s\n' "${C_GREEN}  ok${C_RESET}" "$*"; }
warn() { printf '%s %s\n' "${C_YELLOW}  !!${C_RESET}" "$*" >&2; }
err()  { printf '%s %s\n' "${C_RED}ERROR${C_RESET}" "$*" >&2; }
die()  { err "$*"; exit 1; }

# --- dry-run wrapper --------------------------------------------------------
# Executes "$@", or just prints it when DRY_RUN=1. Redirections CANNOT pass
# through run() (it only sees argv) — keep '>>file' outside run() and guard it
# with DRY_RUN explicitly.
DRY_RUN="${DRY_RUN:-0}"
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s' "${C_DIM}[dry-run]${C_RESET}"
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# --- lifecycle: temp dir + traps -------------------------------------------
common_init() {
  TMPDIR_WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")" \
    || die "could not create a temp directory (check \$TMPDIR)"
  # EXIT cleans the temp dir; ERR reports the failing location (set -E required
  # so the trap is inherited into functions).
  trap 'rc=$?; [ -n "${TMPDIR_WORK:-}" ] && rm -rf "$TMPDIR_WORK"; exit $rc' EXIT
  trap 'err "aborted at ${BASH_SOURCE[0]}:${BASH_LINENO[0]} (exit $?)"; exit 1' ERR
}

# --- platform detection -----------------------------------------------------
detect_os() {
  # OS = macos | wsl | linux
  if [ "$(uname -s)" = "Darwin" ]; then
    OS="macos"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    OS="wsl"   # file-based check; survives sudo, matches WSL1 'Microsoft' + WSL2 'microsoft'
  else
    OS="linux"
  fi
}

detect_pkg_manager() {
  # PM = brew | apt | dnf | pacman | zypper | none
  if [ "$OS" = "macos" ]; then
    PM="brew"
  elif command -v apt-get >/dev/null 2>&1; then PM="apt"
  elif command -v dnf    >/dev/null 2>&1; then PM="dnf"
  elif command -v pacman >/dev/null 2>&1; then PM="pacman"
  elif command -v zypper >/dev/null 2>&1; then PM="zypper"
  else PM="none"; fi
}

# --- sudo handling ----------------------------------------------------------
SUDO=""
detect_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    SUDO=""                       # already root
  elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    SUDO=""
    warn "sudo not found and not running as root — system package installs may fail."
  fi
}
# Validate/refresh sudo once, up front. Leave \$SUDO UNQUOTED at call sites so
# an empty value (root) disappears instead of becoming an empty argv[0].
ensure_sudo() {
  # Homebrew always runs unprivileged, so $SUDO is never used on macOS. Calling
  # 'sudo -v' there would force an interactive password prompt for nothing and
  # abort non-interactive runs (no TTY) — skip it entirely when PM=brew.
  [ "${PM:-}" = "brew" ] && return 0
  if [ -n "$SUDO" ] && [ "$DRY_RUN" -eq 0 ]; then
    sudo -v || die "sudo authentication failed."
  fi
}

# --- backup + manifest ------------------------------------------------------
# Every displaced path is moved into ~/.dotfiles-backup/<timestamp>/ preserving
# relative structure, and recorded in a TSV manifest so uninstall can reverse
# the run precisely. Empty fields are written as '-' (a literal empty TSV field
# would collapse under IFS=tab read and shift later columns).
TAB="$(printf '\t')"

init_backup() {
  BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup}"
  TS="$(date +%Y%m%d-%H%M%S)"
  BACKUP_DIR="$BACKUP_ROOT/$TS"
  MANIFEST="$BACKUP_DIR/manifest.tsv"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$BACKUP_DIR"
    : > "$MANIFEST"
    printf '# dotfiles=%s\n' "$DOTFILES" >> "$MANIFEST"
    printf '# created=%s\n' "$TS" >> "$MANIFEST"
  fi
  log "Backups for this run: ${C_DIM}$BACKUP_DIR${C_RESET}"
}

manifest_append() {
  # action <TAB> original_path <TAB> backup_path(- if none) <TAB> created(yes/no)
  [ "$DRY_RUN" -eq 1 ] && return 0
  printf '%s%s%s%s%s%s%s\n' "$1" "$TAB" "$2" "$TAB" "$3" "$TAB" "$4" >> "$MANIFEST"
}

backup_path_for() {
  # Echoes the backup destination for $1, preserving structure under $HOME.
  local dest="$1" rel
  case "$dest" in
    "$HOME"/*) rel="${dest#"$HOME"/}"; printf '%s\n' "$BACKUP_DIR/$rel" ;;
    *)         printf '%s\n' "$BACKUP_DIR/_abs$dest" ;;
  esac
}

# Moves $1 into the backup tree if it exists (incl. broken symlinks).
# Result path (or '-') is returned via the global BAK_RESULT to avoid a
# command-substitution subshell swallowing our log output.
BAK_RESULT="-"
backup_if_exists() {
  local dest="$1" bak
  BAK_RESULT="-"
  if [ -e "$dest" ] || [ -L "$dest" ]; then   # -L too: -e is false for broken symlinks
    bak="$(backup_path_for "$dest")"
    run mkdir -p "$(dirname "$bak")"
    run mv "$dest" "$bak"
    log "backed up ${C_DIM}$dest${C_RESET} -> $bak"
    BAK_RESULT="$bak"
  fi
}

# --- safe, idempotent symlink ----------------------------------------------
# link_file SRC DEST: ensures DEST is a symlink to SRC, backing up whatever was
# there. Idempotent (skips if already correct). 'ln -sfn' (-n = no-dereference)
# is essential so re-linking a directory target replaces the link instead of
# nesting inside it.
link_file() {
  local src="$1" dest="$2" bak="-"
  if [ ! -e "$src" ]; then
    warn "source missing, skipping link: $src"
    return 0
  fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "already linked: ${C_DIM}$dest${C_RESET}"
    manifest_append link "$dest" "-" yes
    return 0
  fi
  run mkdir -p "$(dirname "$dest")"
  backup_if_exists "$dest"; bak="$BAK_RESULT"
  run ln -sfn "$src" "$dest"
  manifest_append link "$dest" "$bak" yes
  ok "linked $dest -> ${C_DIM}$src${C_RESET}"
}

# --- copy (for targets we can't symlink into) ------------------------------
# copy_file SRC DEST: ensure DEST is a copy of SRC, backing up whatever was
# there. Needed for the Windows filesystem from WSL — NTFS won't follow a Linux
# symlink — so the Alacritty config is copied, not linked. Always overwrites so
# re-runs pick up edits made in the repo. Recorded as a 'copy' manifest action.
copy_file() {
  local src="$1" dest="$2" bak="-"
  if [ ! -e "$src" ]; then
    warn "source missing, skipping copy: $src"
    return 0
  fi
  run mkdir -p "$(dirname "$dest")"
  backup_if_exists "$dest"; bak="$BAK_RESULT"
  run cp "$src" "$dest"
  manifest_append copy "$dest" "$bak" yes
  ok "copied $dest <- ${C_DIM}$src${C_RESET}"
}

# --- canonical-path safety net ---------------------------------------------
# zsh/.zshrc sources $HOME/repositories/dotfiles/zsh/aliases.zsh and
# claude/settings.json references $HOME/repositories/dotfiles/claude/statusline.py
# by absolute path. If the repo lives elsewhere, create a compatibility symlink
# so those hardcoded paths still resolve.
CANONICAL_DIR="$HOME/repositories/dotfiles"
ensure_canonical_path() {
  [ "$DOTFILES" = "$CANONICAL_DIR" ] && return 0
  if [ -L "$CANONICAL_DIR" ]; then
    if [ "$(readlink "$CANONICAL_DIR")" = "$DOTFILES" ]; then
      ok "canonical path already linked: $CANONICAL_DIR"
      return 0
    fi
    # it's a symlink pointing elsewhere (e.g. the repo was moved) — re-point it
    warn "re-pointing existing canonical symlink $CANONICAL_DIR -> $DOTFILES"
    run ln -sfn "$DOTFILES" "$CANONICAL_DIR"
    manifest_append link "$CANONICAL_DIR" "-" yes
    return 0
  fi
  if [ -e "$CANONICAL_DIR" ]; then
    warn "Repo is at $DOTFILES, but $CANONICAL_DIR already exists and is not a symlink to it."
    warn "Shell aliases and the Claude status line hardcode $CANONICAL_DIR and may not work."
    return 0
  fi
  log "Linking canonical path $CANONICAL_DIR -> $DOTFILES (repo is not at the default location)"
  run mkdir -p "$(dirname "$CANONICAL_DIR")"
  run ln -sfn "$DOTFILES" "$CANONICAL_DIR"
  manifest_append link "$CANONICAL_DIR" "-" yes
  return 0
}

# --- aliases-only source block ---------------------------------------------
# For users who want just the aliases without the full zsh config: append a
# marker-delimited source block to ~/.zshrc (restore strips it back out).
ALIAS_BEGIN="# >>> dotfiles aliases >>>"
ALIAS_END="# <<< dotfiles aliases <<<"
install_aliases_block() {
  local rc="$HOME/.zshrc"
  if [ -L "$rc" ] && [ "$(readlink "$rc")" = "$DOTFILES/zsh/.zshrc" ]; then
    ok "aliases already provided by the symlinked ~/.zshrc"
    return 0
  fi
  if [ -f "$rc" ] && grep -qF "$ALIAS_BEGIN" "$rc" 2>/dev/null; then
    ok "aliases block already present in $rc"
    return 0
  fi
  log "Adding aliases source block to $rc"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s append aliases block to %s\n' "${C_DIM}[dry-run]${C_RESET}" "$rc"
    return 0
  fi
  local created="no"
  if [ -f "$rc" ]; then   # keep a safety copy of the pre-edit file
    local bak; bak="$(backup_path_for "$rc")"
    mkdir -p "$(dirname "$bak")"; cp "$rc" "$bak"
  else
    created="yes"         # we are creating ~/.zshrc from scratch
  fi
  {
    printf '\n%s\n' "$ALIAS_BEGIN"
    printf '[ -f "%s/zsh/aliases.zsh" ] && source "%s/zsh/aliases.zsh"\n' "$DOTFILES" "$DOTFILES"
    printf '%s\n' "$ALIAS_END"
  } >> "$rc"
  manifest_append block "$rc" "-" "$created"
  ok "aliases block added to $rc"
}

# --- restore / uninstall ----------------------------------------------------
list_backups() {
  local d found=0
  for d in "$HOME/.dotfiles-backup"/*/; do
    [ -d "$d" ] || continue
    found=1
    printf '  %s\n' "${d%/}"
  done
  [ "$found" -eq 0 ] && printf '  (none)\n'
  return 0
}

latest_manifest() {
  local d
  d="$(ls -1d "$HOME/.dotfiles-backup"/*/ 2>/dev/null | sort | tail -n1)"
  [ -n "$d" ] && printf '%s\n' "${d}manifest.tsv"
  return 0
}

restore_link() {
  local dest="$1" backup="$2" tgt
  if [ -L "$dest" ]; then
    tgt="$(readlink "$dest")"
    case "$tgt" in
      "$DOTFILES"|"$DOTFILES"/*)
        run rm -f "$dest"; ok "removed our symlink: $dest" ;;
      *)
        if [ "${FORCE:-0}" -eq 1 ]; then
          run rm -f "$dest"; warn "force-removed re-pointed symlink: $dest"
        else
          warn "skip (symlink re-pointed by you): $dest"; return 0
        fi ;;
    esac
  elif [ -e "$dest" ]; then
    if [ "${FORCE:-0}" -eq 1 ]; then
      run rm -rf "$dest"; warn "force-removed user content: $dest"
    else
      warn "skip (now a real file, not our link): $dest"; return 0
    fi
  fi
  if [ -n "$backup" ] && [ -e "$backup" ]; then
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      warn "skip restore of backup (destination still occupied): $dest"
    else
      run mkdir -p "$(dirname "$dest")"
      run mv "$backup" "$dest"
      ok "restored backup -> $dest"
    fi
  fi
}

restore_copy() {
  # Reverse a copy_file: the destination is a real file we wrote (often on the
  # Windows filesystem), so remove it, then move any backup back into place.
  local dest="$1" backup="$2"
  if [ -L "$dest" ]; then
    warn "skip (now a symlink, not our copy): $dest"; return 0
  elif [ -e "$dest" ]; then
    run rm -f "$dest"; ok "removed copied file: $dest"
  fi
  if [ -n "$backup" ] && [ -e "$backup" ]; then
    if [ -e "$dest" ]; then
      warn "skip restore of backup (destination still occupied): $dest"
    else
      run mkdir -p "$(dirname "$dest")"
      run mv "$backup" "$dest"
      ok "restored backup -> $dest"
    fi
  fi
}

restore_block() {
  local file="$1" created="${2:-no}"
  [ -f "$file" ] || return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s strip aliases block from %s\n' "${C_DIM}[dry-run]${C_RESET}" "$file"
    return 0
  fi
  # Only rewrite when BOTH markers are present; a lone marker (user-edited file)
  # would make the awk skip the rest of the file and truncate it.
  if ! grep -qF "$ALIAS_BEGIN" "$file" || ! grep -qF "$ALIAS_END" "$file"; then
    warn "aliases markers not both present in $file — leaving it untouched"
    return 0
  fi
  awk -v b="$ALIAS_BEGIN" -v e="$ALIAS_END" '
    $0==b {skip=1; next} $0==e {skip=0; next} skip!=1 {print}
  ' "$file" > "$file.dotfiles.tmp" && mv "$file.dotfiles.tmp" "$file"
  ok "removed aliases block from $file"
  # If we created this file and only whitespace is left, remove it entirely.
  if [ "$created" = "yes" ] && ! grep -q '[^[:space:]]' "$file"; then
    rm -f "$file"; ok "removed $file (created by installer, now empty)"
  fi
}

do_restore() {
  local manifest="$1" action dest backup created
  [ -f "$manifest" ] || die "manifest not found: $manifest"
  [ -r "$manifest" ] || die "manifest not readable: $manifest"
  log "Restoring from ${C_DIM}$manifest${C_RESET}"
  # Reverse order (undo last action first); skip comments. macOS lacks tac, so
  # reverse with awk. Read from a file (not a pipe) so the while body runs in
  # the current shell.
  awk '!/^#/ && NF {a[NR]=$0} END{for(i=NR;i>=1;i--) if(a[i]!="") print a[i]}' \
    "$manifest" > "$TMPDIR_WORK/restore.lst"
  while IFS="$TAB" read -r action dest backup created; do
    [ -z "${action:-}" ] && continue
    # every well-formed record has 4 non-empty fields (backup is '-' when none)
    if [ -z "${dest:-}" ] || [ -z "${backup:-}" ] || [ -z "${created:-}" ]; then
      warn "skipping malformed manifest line (action='$action' dest='$dest')"
      continue
    fi
    [ "$backup" = "-" ] && backup=""
    case "$action" in
      link)  restore_link "$dest" "$backup" ;;
      copy)  restore_copy "$dest" "$backup" ;;
      block) restore_block "$dest" "$created" ;;
      *)     warn "unknown manifest action '$action' for $dest (skipping)" ;;
    esac
  done < "$TMPDIR_WORK/restore.lst"
  ok "Restore complete. (Backup files left in place under ~/.dotfiles-backup.)"
}
