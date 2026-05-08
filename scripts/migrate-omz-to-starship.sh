#!/usr/bin/env bash
# migrate-omz-to-starship.sh
#
# Manually migrate THIS machine from oh-my-zsh + robbyrussell to pure zsh +
# Starship + 3 plugins. Does NOT use chezmoi — copies files directly from this
# repo into your live $HOME. Idempotent (safe to re-run).
#
# Usage:
#   bash scripts/migrate-omz-to-starship.sh
#
# Rollback:
#   cp ~/.zshrc.pre-starship-<ts> ~/.zshrc
#   exec zsh    # or just open a new terminal

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OS="$(uname -s)"

echo "==> OMZ → Starship migration"
echo "    repo: $REPO_ROOT"
echo "    OS:   $OS"
echo

# --- 1. Backup current ~/.zshrc ---------------------------------------------
BACKUP="$HOME/.zshrc.pre-starship-$TIMESTAMP"
if [[ -f "$HOME/.zshrc" ]]; then
  cp -p "$HOME/.zshrc" "$BACKUP"
  echo "==> Backed up: ~/.zshrc → ${BACKUP/#$HOME/~}"
fi

# --- 2. Install starship binary ---------------------------------------------
if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing starship"
  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "    brew not found — install Homebrew first" >&2
      exit 1
    fi
    brew install starship
  elif [[ -f /etc/debian_version ]] || [[ -f /etc/fedora-release ]]; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  elif [[ -f /etc/arch-release ]]; then
    sudo pacman -S --noconfirm starship
  else
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi
else
  echo "==> starship already installed ($(starship --version | head -1))"
fi

# --- 3. Clone the 4 zsh plugins ---------------------------------------------
# Mirror run_once_before_02-install-zsh-plugins.sh.tmpl: same set, same order.
PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$PLUGIN_DIR"
plugins=(
  "zsh-autosuggestions          https://github.com/zsh-users/zsh-autosuggestions.git"
  "fzf-tab                      https://github.com/Aloxaf/fzf-tab.git"
  "zsh-syntax-highlighting      https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search.git"
)
for entry in "${plugins[@]}"; do
  name="${entry%% *}"
  url="${entry##* }"
  if [[ -d "$PLUGIN_DIR/$name" ]]; then
    echo "==> Plugin already present: $name"
  else
    echo "==> Cloning plugin: $name"
    git clone --depth=1 "$url" "$PLUGIN_DIR/$name"
  fi
done

# --- 4. Modular zsh config (~/.config/zsh/) ---------------------------------
mkdir -p "$HOME/.config/zsh"
cp -p "$REPO_ROOT/dot_config/zsh/00-env.zsh"     "$HOME/.config/zsh/"
cp -p "$REPO_ROOT/dot_config/zsh/10-path.zsh"    "$HOME/.config/zsh/"
cp -p "$REPO_ROOT/dot_config/zsh/20-tools.zsh"   "$HOME/.config/zsh/"
cp -p "$REPO_ROOT/dot_config/zsh/30-aliases.zsh" "$HOME/.config/zsh/"
if [[ "$OS" == "Darwin" ]]; then
  cp -p "$REPO_ROOT/dot_config/zsh/40-darwin.zsh" "$HOME/.config/zsh/"
  rm -f "$HOME/.config/zsh/40-linux.zsh"
else
  cp -p "$REPO_ROOT/dot_config/zsh/40-linux.zsh" "$HOME/.config/zsh/"
  rm -f "$HOME/.config/zsh/40-darwin.zsh"
fi
echo "==> Wrote ~/.config/zsh/ (5 modules)"

# --- 5. Starship config -----------------------------------------------------
# starship.toml is a chezmoi template (gates Nerd Font glyphs vs ASCII via
# the .nerd_font data var). This script doesn't go through chezmoi, so render
# the template via `chezmoi execute-template` if available; otherwise bake
# nerd_font=true (matching the upstream default).
mkdir -p "$HOME/.config"
if [[ -f "$HOME/.config/starship.toml" ]]; then
  echo "==> ~/.config/starship.toml already exists — leaving alone"
else
  STARSHIP_SRC="$REPO_ROOT/dot_config/starship.toml.tmpl"
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi execute-template < "$STARSHIP_SRC" > "$HOME/.config/starship.toml"
  else
    # Strip {{ if .nerd_font }}…{{ else }}…{{ end }} blocks, keeping the
    # nerd-font branch (matches the .chezmoidata.yaml default).
    awk '
      /{{- if \.nerd_font/ { mode="nerd"; next }
      /{{- else/           { mode="ascii"; next }
      /{{- end/            { mode="";    next }
      mode != "ascii"      { print }
    ' "$STARSHIP_SRC" > "$HOME/.config/starship.toml"
  fi
  echo "==> Wrote ~/.config/starship.toml (Nerd Font variant)"
fi

# --- 6. Replace ~/.zshrc ----------------------------------------------------
cp -p "$REPO_ROOT/dot_zshrc" "$HOME/.zshrc"
echo "==> Replaced ~/.zshrc with pure-zsh + Starship loader"

# --- 7. Done ----------------------------------------------------------------
cat <<EOF

==> Migration complete.

NEXT STEPS

  1. Open a NEW terminal (DO NOT close this one — it's your safety net).
  2. Sanity-check:
       echo \$SHELL                  # /bin/zsh or /usr/bin/zsh
       which starship                # path to binary
       type gst                      # gst is an alias for git status
       take new-test && cd ..        # take function works
       ..                            # cd up via alias

  3. Visual confirmation:
       - Buddha banner shows
       - Prompt switches to Starship (multi-line, git-aware)
       - Typing a command shows ghost-text (autosuggest)
       - Wrong command name turns red (syntax-highlight)

ROLLBACK

  If anything is broken:
       cp $BACKUP ~/.zshrc
       exec zsh

  Your OMZ install at ~/.oh-my-zsh/ is untouched. Delete only after a few
  days of confident use:
       rm -rf ~/.oh-my-zsh ~/.zcompdump*

CHEZMOI (later, when you're ready)

  Once this manual setup proves stable, you can add chezmoi on top to manage
  it across machines:
       brew install chezmoi
       chezmoi init --source=$REPO_ROOT
       chezmoi diff   # should show NO changes (live matches source)
EOF
