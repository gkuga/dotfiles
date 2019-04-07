#!/bin/bash

DOT_FILES=(bashrc screenrc gitconfig git-completion.bash vimrc)

for file in ${DOT_FILES[@]}
do
  ln -fs $HOME/dotfiles/$file $HOME/.$file
done
