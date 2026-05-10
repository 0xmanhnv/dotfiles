# Core CLI
brew "git"
brew "gh"
brew "neovim"
brew "tmux"
brew "zsh"

# Modern replacements
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"
brew "zoxide"
brew "starship"

# Utilities
brew "jq"
brew "yq"
brew "tree"
brew "wget"
brew "htop"
brew "ghostscript"     # Used by snacks.nvim image rendering for PDF preview
brew "lazygit"         # Git TUI — pairs nicely with tmux
brew "git-delta"       # Pretty diffs (wired up in dot_gitconfig.tmpl)
brew "tealdeer"        # Fast Rust impl of tldr — `tldr <cmd>` for examples
brew "glow"            # Render markdown in the terminal

# Languages — pin to LTS / current stable. jenv manages JDK switching; gvm
# (manual installer) handles per-project Go versions when needed.
brew "jenv"
brew "openjdk@25"      # Java 25 LTS (latest LTS, supported until 2030)
brew "node@24"         # Node 24 LTS (Active LTS since Oct 2025)
brew "go"              # Go has no LTS — current stable (1.26.x)
brew "python@3.13"     # Python 3.13 (mature, broader package compat than 3.14)
brew "ruby@3.4"        # Ruby 3.4 (latest stable; ruby@4 is too new for now)

# Networking / pentest tools (referenced by ~/.config/zsh/40-darwin.zsh)
brew "inetutils"
brew "nginx"
brew "openvpn"
brew "wireguard-tools"
brew "freerdp"
brew "binwalk"

# Build / compile (referenced by ~/.config/zsh/40-darwin.zsh)
brew "binutils"
brew "bison"
brew "rlwrap"

# Casks
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
cask "orbstack"        # Docker / K8s / Linux VMs — drop-in for Docker Desktop

# Manual installers — NOT available via Homebrew. Install separately on a fresh
# machine if you need them (see ~/.config/zsh/40-darwin.zsh for PATH setup):
#   - GVM         https://github.com/moovweb/gvm
#   - Metasploit  https://www.metasploit.com/
#   - LM Studio   https://lmstudio.ai/
#   - Windsurf    https://codeium.com/windsurf
#   - Sliver C2   https://github.com/BishopFox/sliver
#   - pdtm        https://github.com/projectdiscovery/pdtm
#   - Android SDK via Android Studio
#
# Optional snacks.nvim image-rendering deps (skipped — heavy installs):
#   brew "tectonic"           # LaTeX math rendering (~200 MB)
#   brew "mermaid-cli"        # Mermaid diagrams (pulls Chromium ~150 MB)
#                             # or: npm install -g @mermaid-js/mermaid-cli
