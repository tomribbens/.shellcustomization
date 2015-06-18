#!/bin/bash

if [ -e ~/.ssh ];
then
  if [ -d ~/.ssh ];
  then
    ln -is ~/.shellcustomization/authorized_keys ~/.ssh/
  else
    echo "~/.ssh exists, but is not a directory"
  fi
else
  mkdir ~/.ssh
  ln -is ~/.shellcustomization/authorized_keys ~/.ssh/
fi

# Link files
ln -is ~/.shellcustomization/.bashrc ~/
ln -is ~/.shellcustomization/.bash_profile ~/
ln -is ~/.shellcustomization/.screenrc ~/
ln -is ~/.shellcustomization/.gitconfig ~/

# Make directory for screenlogs
mkdir ~/.screenlogs
