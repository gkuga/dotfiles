# shellcheck shell=bash
# Must be loaded last: `mise activate` hooks into PROMPT_COMMAND, which
# 40-prompt.sh assigns.

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi
