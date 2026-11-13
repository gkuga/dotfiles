#!/bin/bash

DOT_FILES=(bashrc zshrc screenrc gitconfig vimrc zsh.d zsh_completions profile.d zprofile)

for file in ${DOT_FILES[@]}
do
  ln -fs $PWD/$file $HOME/.$file
done

SCRIPTS=(git-completion.sh hub.bash_completion.sh)
SCRIPTS_HOME=$HOME/.bash.d/

mkdir -p $SCRIPTS_HOME
for file in ${SCRIPTS[@]}
do
  ln -fs $HOME/dotfiles/$file $SCRIPTS_HOME/$file
done


