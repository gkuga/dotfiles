# mise shims, so that non-interactive shells (scripts, IDEs, AI agents) get the
# same tool versions. Interactive shells additionally run `mise activate`
# (see ~/.bash.d/90-mise.sh).
path_prepend "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
