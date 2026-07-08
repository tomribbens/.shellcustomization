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

  # Warn if this host's sshd won't actually read authorized_keys2. Prefer the
  # effective config (sshd -T, needs root); fall back to grepping the config
  # files. An empty result means AuthorizedKeysFile is unset, so the built-in
  # default (which includes authorized_keys2) applies and we stay quiet.
  AKF=$(sshd -T 2>/dev/null | grep -i '^authorizedkeysfile ')
  if [ -z "${AKF}" ]; then
    AKF=$(grep -rhiE '^[[:space:]]*AuthorizedKeysFile' \
      /etc/ssh/sshd_config /etc/ssh/sshd_config.d/ 2>/dev/null)
  fi
  if [ -n "${AKF}" ] && ! echo "${AKF}" | grep -q 'authorized_keys2'; then
    echo "WARNING: sshd on $(hostname -f) does not list authorized_keys2 in" >&2
    echo "         AuthorizedKeysFile, so host-specific keys in" >&2
    echo "         ~/.ssh/authorized_keys2 will be IGNORED." >&2
    echo "         Effective setting: ${AKF}" >&2
    echo "         Add authorized_keys2 to /etc/ssh/sshd_config (needs root)" >&2
    echo "         and reload sshd to enable them." >&2
  fi
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
