#!/usr/bin/env bash
# backup-before-apply.sh
#
# Run this BEFORE `chezmoi apply` to:
#   1. Save every file that chezmoi would overwrite to ~/dotfiles-backup-<ts>/
#   2. Auto-migrate ~/.ssh/config host entries to ~/.ssh/config.local
#      (the new dotfiles ~/.ssh/config only ships catch-all defaults +
#      `Include config.local` — without this step, your hosts get wiped)
#   3. Print revert instructions
#
# Usage:
#   bash backup-before-apply.sh

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/dotfiles-backup-$TIMESTAMP"

# --- 1. Backup files chezmoi would MODIFY (status M) -------------------------

echo "==> Pre-apply backup → $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

modified=0
while IFS= read -r line; do
  status="${line:0:2}"
  target="${line:3}"
  # M = modified. Skip A (added — nothing to back up), R (run scripts), D (delete).
  [[ "$status" =~ M ]] || continue
  src="$HOME/$target"
  [[ -f "$src" ]] || continue
  mkdir -p "$BACKUP_DIR/$(dirname "$target")"
  cp -p "$src" "$BACKUP_DIR/$target"
  echo "    saved: ~/$target"
  modified=$((modified + 1))
done < <(chezmoi status)

if (( modified == 0 )); then
  echo "    (chezmoi would not modify any existing files — nothing to back up)"
fi

# --- 2. Migrate SSH host entries to ~/.ssh/config.local ----------------------

SSH_CFG="$HOME/.ssh/config"
SSH_LOCAL="$HOME/.ssh/config.local"

if [[ -f "$SSH_CFG" ]] && grep -qE '^Host [^*]' "$SSH_CFG"; then
  if [[ -f "$SSH_LOCAL" ]]; then
    echo "==> ~/.ssh/config.local already exists — leaving it alone"
  else
    echo "==> Extracting non-default SSH host entries → ~/.ssh/config.local"
    # Strip any Host * blocks: the new chezmoi-managed ~/.ssh/config will
    # provide its own Host * defaults, so config.local should only carry the
    # per-host entries.
    awk '/^Host \*/{flag=1} /^Host [^*]/{flag=0} !flag' "$SSH_CFG" > "$SSH_LOCAL"
    chmod 600 "$SSH_LOCAL"
    n=$(grep -c '^Host ' "$SSH_LOCAL" || echo 0)
    echo "    wrote $n host entries"
  fi
fi

# --- 3. Print next-step instructions -----------------------------------------

cat <<EOF

==> Backup complete.

NEXT STEPS

  1. Review pending changes:
       chezmoi diff

  2. Apply when ready (consider --exclude=scripts on the source machine, since
     packages and OMZ-replacement are already in place here):
       chezmoi apply --exclude=scripts

  3. Open a NEW terminal to verify zsh, prompt, ssh — DO NOT close the current
     shell yet (it's your safety net if the new shell is broken).

REVERT IF NEEDED

  Restore everything in one shot:
    rsync -a "$BACKUP_DIR/" "\$HOME/"

  Or just one file (example):
    cp -p "$BACKUP_DIR/.zshrc" "\$HOME/.zshrc"

Backup retained at: $BACKUP_DIR
EOF
