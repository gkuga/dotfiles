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
