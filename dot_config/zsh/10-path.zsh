# Common PATH entries (cross-OS). Each guarded so missing dirs are skipped.

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/go/bin" ]]      && export PATH="$PATH:$HOME/go/bin"
