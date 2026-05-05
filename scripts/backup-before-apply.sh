#!/usr/bin/env bash
# backup-before-apply.sh
#
# Run this BEFORE `chezmoi apply` to snapshot everything chezmoi could change:
#
#   1. Files chezmoi would MODIFY or DELETE → ~/dotfiles-backup-<ts>/
#   2. SSH host entries migrated to ~/.ssh/config.local (so chezmoi's
#      catch-all-only ~/.ssh/config doesn't wipe per-host configs)
#   3. Default-shell snapshot (so you can revert chsh if run_once_after
#      fires and changes it)
#   4. Package-manager inventory (brew / apt / dnf / pacman) — informational
#      so you can see what's new after run_once_before installs anything
#   5. chezmoi config dir (`~/.config/chezmoi`) snapshot
#
# Usage:
#   bash backup-before-apply.sh

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/dotfiles-backup-$TIMESTAMP"

echo "==> Pre-apply backup → $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# --- 1. Files chezmoi would MODIFY or DELETE -------------------------------

modified=0
while IFS= read -r line; do
  status="${line:0:2}"
  target="${line:3}"
  # M = modified (will be overwritten); D = deleted (file goes away)
  [[ "$status" =~ [MD] ]] || continue
  src="$HOME/$target"
  [[ -f "$src" ]] || continue
  mkdir -p "$BACKUP_DIR/$(dirname "$target")"
  cp -p "$src" "$BACKUP_DIR/$target"
  echo "    saved: ~/$target"
  modified=$((modified + 1))
done < <(chezmoi status 2>/dev/null || true)

if (( modified == 0 )); then
  echo "    (chezmoi would not modify/delete any existing files)"
fi

# --- 2. Migrate SSH host entries to ~/.ssh/config.local --------------------

SSH_CFG="$HOME/.ssh/config"
SSH_LOCAL="$HOME/.ssh/config.local"

if [[ -f "$SSH_CFG" ]] && grep -qE '^Host [^*]' "$SSH_CFG"; then
  if [[ -f "$SSH_LOCAL" ]]; then
    echo "==> ~/.ssh/config.local already exists — leaving it alone"
  else
    echo "==> Extracting non-default SSH host entries → ~/.ssh/config.local"
    awk '/^Host \*/{flag=1} /^Host [^*]/{flag=0} !flag' "$SSH_CFG" > "$SSH_LOCAL"
    chmod 600 "$SSH_LOCAL"
    n=$(grep -c '^Host ' "$SSH_LOCAL" || echo 0)
    echo "    wrote $n host entries"
  fi
fi

# --- 3. Default-shell snapshot (so you can revert chsh) --------------------

USER_SHELL=""
if command -v dscl >/dev/null 2>&1; then
  USER_SHELL=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
fi
[[ -z "$USER_SHELL" ]] && USER_SHELL=$(getent passwd "$USER" 2>/dev/null | awk -F: '{print $7}' || true)
[[ -z "$USER_SHELL" ]] && USER_SHELL="${SHELL:-}"
if [[ -n "$USER_SHELL" ]]; then
  printf '%s\n' "$USER_SHELL" > "$BACKUP_DIR/default-shell.txt"
  echo "==> Default shell recorded: $USER_SHELL"
fi

# --- 4. Package-manager inventory ------------------------------------------

mkdir -p "$BACKUP_DIR/packages"
echo "==> Package inventory snapshot"
if command -v brew >/dev/null 2>&1; then
  brew list --formula > "$BACKUP_DIR/packages/brew-formulas.txt" 2>/dev/null && \
    echo "    saved: brew formulas ($(wc -l < "$BACKUP_DIR/packages/brew-formulas.txt" | tr -d ' ') items)"
  brew list --cask > "$BACKUP_DIR/packages/brew-casks.txt" 2>/dev/null && \
    echo "    saved: brew casks ($(wc -l < "$BACKUP_DIR/packages/brew-casks.txt" | tr -d ' ') items)"
fi
if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f='${Package}\n' > "$BACKUP_DIR/packages/dpkg.txt" 2>/dev/null && \
    echo "    saved: dpkg ($(wc -l < "$BACKUP_DIR/packages/dpkg.txt" | tr -d ' ') items)"
fi
if command -v pacman >/dev/null 2>&1; then
  pacman -Qqe > "$BACKUP_DIR/packages/pacman.txt" 2>/dev/null && \
    echo "    saved: pacman ($(wc -l < "$BACKUP_DIR/packages/pacman.txt" | tr -d ' ') items)"
fi
if command -v rpm >/dev/null 2>&1; then
  rpm -qa --qf '%{NAME}\n' 2>/dev/null | sort > "$BACKUP_DIR/packages/rpm.txt" && \
    echo "    saved: rpm ($(wc -l < "$BACKUP_DIR/packages/rpm.txt" | tr -d ' ') items)"
fi

# --- 5. chezmoi config + state ----------------------------------------------

if [[ -d "$HOME/.config/chezmoi" ]]; then
  cp -R "$HOME/.config/chezmoi" "$BACKUP_DIR/chezmoi-config"
  echo "==> Saved chezmoi config dir"
fi

# --- 6. Print next-step instructions ----------------------------------------

cat <<EOF

==> Backup complete: $BACKUP_DIR

CONTENTS

  Modified files       : $modified file(s)
  ~/.ssh/config.local  : $([[ -f "$SSH_LOCAL" ]] && echo "OK" || echo "(not created)")
  default-shell.txt    : ${USER_SHELL:-(not recorded)}
  packages/            : brew/apt/dnf/pacman inventory
  chezmoi-config/      : your ~/.config/chezmoi snapshot (if any)

NEXT STEPS

  1. chezmoi diff                        # review pending changes
  2. chezmoi apply [--exclude=scripts]   # apply (--exclude=scripts skips
                                         # the heavy run_once package /
                                         # plugin / rustup / chsh installers
                                         # — useful if your machine already
                                         # has them set up by hand)
  3. Open a NEW terminal to verify       # don't close the current one yet

REVERT

  All file changes:
    bash scripts/restore-from-backup.sh

  Just default shell (if chsh ran and you want to revert):
    chsh -s "\$(cat $BACKUP_DIR/default-shell.txt)"

  Compare what packages were added by run_once installers:
    diff $BACKUP_DIR/packages/brew-formulas.txt <(brew list --formula)

Backup retained at: $BACKUP_DIR
EOF
