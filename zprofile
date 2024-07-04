if [ -d "${HOME}/.profile.d" ] ; then
  for script in "${HOME}"/.profile.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi

if [ -d "${HOME}/.zsh.d" ] ; then
  for script in "${HOME}"/.zsh.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi


