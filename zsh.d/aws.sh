export PATH=$PATH:$HOME/opt/aws-sam-cli
function aws-configure() {
  local selected_profile=$(aws configure list-profiles | peco)
  if [ -n "$selected_profile" ]; then
    export AWS_PROFILE=$selected_profile
  fi
}
