export PATH="$HOME/bin:$PATH"

if [ -d $HOME/.profile.d ]; then
  for i in $HOME/.profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

if [[ -f ~/.bashrc ]] ; then
    . ~/.bashrc
fi

# AsyncAPI CLI Autocomplete

ASYNCAPI_AC_BASH_SETUP_PATH=/Users/gkuga/Library/Caches/@asyncapi/cli/autocomplete/bash_setup && test -f $ASYNCAPI_AC_BASH_SETUP_PATH && source $ASYNCAPI_AC_BASH_SETUP_PATH; # asyncapi autocomplete setup


