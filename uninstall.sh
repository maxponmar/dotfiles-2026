#!/usr/bin/env bash
#
# Dotfiles uninstaller — reverses an install using the backup manifest.
# Removes the symlinks the installer created (only if they still point into this
# repo) and moves backed-up originals back. Files you changed yourself are left
# untouched unless --force.
#
# Usage:
#   ./uninstall.sh [--from <timestamp>] [--force] [--dry-run] [--list]
#
#   --from <ts>  restore a specific backup (see ~/.dotfiles-backup); default: latest
#   --list       list available backups and exit
#   --force      remove re-pointed symlinks / user-replaced files too
#   --dry-run    print what would happen without changing anything
#   -h, --help   show this help
#
set -euo pipefail
set -E

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
export DOTFILES="$SCRIPT_DIR"
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/scripts/lib/common.sh"

usage() { awk 'NR>=3 { if (/^#/) { sub(/^# ?/,""); print; next } else exit }' "$0"; }

FROM=""; FORCE=0; LIST=0
DRY_RUN="${DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --from)    shift; FROM="${1:-}"; [ -n "$FROM" ] || die "--from needs a timestamp" ;;
    --force)   FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --list|--list-backups) LIST=1 ;;
    -h|--help) usage; exit 0 ;;
    *)         err "unknown option: $1"; usage; exit 2 ;;
  esac
  shift
done
export DRY_RUN FORCE

common_init

if [ "$LIST" -eq 1 ]; then
  log "Backups under ~/.dotfiles-backup:"; list_backups; exit 0
fi

if [ -n "$FROM" ]; then
  manifest="$HOME/.dotfiles-backup/$FROM/manifest.tsv"
else
  manifest="$(latest_manifest || true)"
fi
[ -n "${manifest:-}" ] || die "No backups found in ~/.dotfiles-backup."

[ "$DRY_RUN" -eq 1 ] && warn "DRY RUN — no changes will be made"
do_restore "$manifest"
