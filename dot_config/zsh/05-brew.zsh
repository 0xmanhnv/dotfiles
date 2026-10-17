# Homebrew (macOS + Linuxbrew). Loads before 20-tools.zsh on purpose:
# version managers (gvm, jenv) must prepend their shims/GOROOT on TOP of
# brew's bin. The other way round, brew's `go` (or keg-only openjdk) shadows
# the gvm/jenv-selected one while GOROOT / JAVA_HOME still point at it —
# `go build` then fails with "compile: version go1.X does not match go tool".

for _p in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [[ -x "$_p/bin/brew" ]]; then
    BREW_PREFIX="$_p"
    break
  fi
done
unset _p

if [[ -n "${BREW_PREFIX:-}" ]]; then
  # Same exports as `brew shellenv zsh`, without forking brew (~15-20ms).
  export HOMEBREW_PREFIX="$BREW_PREFIX" HOMEBREW_CELLAR="$BREW_PREFIX/Cellar"
  if [[ -d "$BREW_PREFIX/Homebrew" ]]; then
    export HOMEBREW_REPOSITORY="$BREW_PREFIX/Homebrew"   # Intel / Linuxbrew
  else
    export HOMEBREW_REPOSITORY="$BREW_PREFIX"            # Apple Silicon
  fi
  path=("$BREW_PREFIX/bin" "$BREW_PREFIX/sbin" $path)
  fpath=("$BREW_PREFIX/share/zsh/site-functions" $fpath)
  [[ -z "${MANPATH-}" ]] || export MANPATH=":${MANPATH#:}"
  export INFOPATH="$BREW_PREFIX/share/info:${INFOPATH:-}"

  # Keg-only formulae: point at the version-independent opt/ symlink (never
  # a Cellar/<version> path) so `brew upgrade` doesn't break PATH.
  # Prepended so they win over the macOS system copies.
  # python@3.13/libexec/bin holds the unversioned python3 / pip3 links
  # (bin/ only has python3.13, so python3 would resolve to brew's newest).
  for _d in python@3.13/libexec/bin node@24/bin ruby@3.4/bin openjdk@25/bin \
            bison/bin openvpn/sbin; do
    [[ -d "$BREW_PREFIX/opt/$_d" ]] && export PATH="$BREW_PREFIX/opt/$_d:$PATH"
  done
  unset _d
fi
