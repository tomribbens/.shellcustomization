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

# Link host-specific authorized keys as authorized_keys2, if a file for this
# host exists. sshd reads both files by default (AuthorizedKeysFile setting).
HOSTKEYS=~/.shellcustomization/authorized_keys_$(hostname -f)
if [ -e "${HOSTKEYS}" ]; then
  ln -is "${HOSTKEYS}" ~/.ssh/authorized_keys2
fi

# Link files
ln -is ~/.shellcustomization/.bashrc ~/
ln -is ~/.shellcustomization/.bash_profile ~/
ln -is ~/.shellcustomization/.screenrc ~/
ln -is ~/.shellcustomization/.gitconfig ~/
ln -is ~/.shellcustomization/.vimrc ~/

# Make directory for screenlogs
mkdir ~/.screenlogs

# Make directories for vim undo/swap/backup files (see .vimrc)
mkdir -p ~/.vim/undo ~/.vim/swap ~/.vim/backup
