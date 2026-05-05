#!/usr/bin/env bash
# restore-from-backup.sh
#
# Counterpart to backup-before-apply.sh. Restores files from a backup dir
# back into $HOME if `chezmoi apply` made things worse.
#
# Usage:
#   bash restore-from-backup.sh                       # use latest backup
#   bash restore-from-backup.sh <backup-dir>          # use specific backup
#   bash restore-from-backup.sh --list                # list available backups

set -euo pipefail

list_backups() {
  shopt -s nullglob
  local dirs=("$HOME"/dotfiles-backup-*)
  shopt -u nullglob
  if (( ${#dirs[@]} == 0 )); then
    echo "(no backups found in $HOME/)"
    return 1
  fi
  for d in "${dirs[@]}"; do
    local n
    n=$(find "$d" -type f | wc -l | tr -d ' ')
    echo "  $d ($n files)"
  done
}

# --- Parse args --------------------------------------------------------------

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  echo "Available backups:"
  list_backups
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  BACKUP_DIR="$1"
  [[ -d "$BACKUP_DIR" ]] || { echo "Error: not a directory: $BACKUP_DIR" >&2; exit 1; }
else
  # Pick most recent — timestamp in name = lexical order works
  shopt -s nullglob
  candidates=("$HOME"/dotfiles-backup-*)
  shopt -u nullglob
  if (( ${#candidates[@]} == 0 )); then
    echo "Error: no backups found in $HOME/" >&2
    echo "Run 'bash backup-before-apply.sh' first." >&2
    exit 1
  fi
  # Glob expansion already sorts lexically; timestamp suffix means lexical
  # order = chronological order, so the last element is the most recent.
  BACKUP_DIR="${candidates[${#candidates[@]}-1]}"
fi

# --- Preview -----------------------------------------------------------------

echo "==> Restore source: $BACKUP_DIR"
echo "==> Files that will be OVERWRITTEN in \$HOME:"
file_count=$(find "$BACKUP_DIR" -type f | wc -l | tr -d ' ')
if (( file_count == 0 )); then
  echo "    (backup dir is empty — nothing to restore)"
  exit 0
fi
find "$BACKUP_DIR" -type f | sed "s|^$BACKUP_DIR/|    ~/|"

# --- Confirm -----------------------------------------------------------------

echo
read -r -p "Proceed? [y/N] " ans
case "$ans" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# --- Restore -----------------------------------------------------------------

restored=0
while IFS= read -r f; do
  rel="${f#"$BACKUP_DIR"/}"
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -p "$f" "$dest"
  echo "    restored: ~/$rel"
  restored=$((restored + 1))
done < <(find "$BACKUP_DIR" -type f)

# --- Optional cleanup: orphan ~/.ssh/config.local ----------------------------
# After restoring the original ~/.ssh/config (which has its host entries), the
# config.local created by backup-before-apply.sh is redundant. Restored
# ~/.ssh/config doesn't `Include config.local`, so it's harmless — but offering
# cleanup keeps things tidy.

SSH_LOCAL="$HOME/.ssh/config.local"
if [[ -f "$BACKUP_DIR/.ssh/config" && -f "$SSH_LOCAL" ]]; then
  echo
  read -r -p "Remove now-orphan ~/.ssh/config.local? [y/N] " ans
  case "$ans" in
    [yY]|[yY][eE][sS]) rm -f "$SSH_LOCAL"; echo "    removed ~/.ssh/config.local" ;;
    *) echo "    kept ~/.ssh/config.local" ;;
  esac
fi

# --- Done --------------------------------------------------------------------

cat <<EOF

==> Restored $restored files.

NEXT STEPS

  Open a NEW terminal — verify the restored shell config loads cleanly.

  If you also want chezmoi's run_once scripts to fire again on the next apply
  (e.g., to retry a failed install), reset the script state:
    chezmoi state delete-bucket --bucket=scriptState

  Backup dir kept at: $BACKUP_DIR
  (delete it manually with: rm -rf "$BACKUP_DIR")
EOF
