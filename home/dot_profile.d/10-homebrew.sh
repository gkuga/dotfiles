# Homebrew (macOS). Static equivalent of `brew shellenv`, to avoid spawning brew
# on every shell start.
[ "$(uname -s)" = Darwin ] || return 0

for HOMEBREW_PREFIX in /opt/homebrew /usr/local; do
  [ -x "$HOMEBREW_PREFIX/bin/brew" ] && break
done
[ -x "$HOMEBREW_PREFIX/bin/brew" ] || { unset HOMEBREW_PREFIX; return 0; }

export HOMEBREW_PREFIX
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
if [ "$HOMEBREW_PREFIX" = /opt/homebrew ]; then
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
else
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
fi
path_prepend "$HOMEBREW_PREFIX/sbin"
path_prepend "$HOMEBREW_PREFIX/bin"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Prefer GNU tools and keg-only formulae when they are installed.
for d in \
  opt/gnu-sed/libexec/gnubin \
  opt/gawk/libexec/gnubin \
  opt/make/libexec/gnubin \
  opt/e2fsprogs/bin \
  opt/e2fsprogs/sbin \
  opt/mysql-client@8.0/bin; do
  path_prepend "$HOMEBREW_PREFIX/$d"
done
unset d
# binutils shadows the macOS toolchain, so append it instead.
[ -d "$HOMEBREW_PREFIX/opt/binutils/bin" ] && PATH="$PATH:$HOMEBREW_PREFIX/opt/binutils/bin"
