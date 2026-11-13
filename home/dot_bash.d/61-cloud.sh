# shellcheck shell=bash
# Profile pickers for cloud CLIs.

aws-configure() {
  local selected
  selected="$(aws configure list-profiles | peco)"
  if [ -n "$selected" ]; then
    export AWS_PROFILE="$selected"
  fi
}

usacloud-configure() {
  local selected
  selected="$(usacloud config list | grep -v '\* ' | peco)"
  if [ -n "$selected" ]; then
    usacloud config use "$selected"
  fi
}

# Google Cloud SDK installed under ~/opt.
for f in "$HOME/opt/google-cloud-sdk/path.bash.inc" "$HOME/opt/google-cloud-sdk/completion.bash.inc"; do
  if [ -r "$f" ]; then
    . "$f"
  fi
done
unset f
