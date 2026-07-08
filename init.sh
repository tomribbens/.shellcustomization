#!/bin/bash

# Create symlink $2 -> $1 idempotently: do nothing if it already points at the
# right place (so re-running init.sh is silent), otherwise create it, prompting
# before clobbering anything that already exists and isn't our link.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    return
  fi
  ln -is "$src" "$dst"
}

if [ -e ~/.ssh ];
then
  if [ -d ~/.ssh ];
  then
    link ~/.shellcustomization/authorized_keys ~/.ssh/authorized_keys
  else
    echo "~/.ssh exists, but is not a directory"
  fi
else
  mkdir ~/.ssh
  link ~/.shellcustomization/authorized_keys ~/.ssh/authorized_keys
fi

# Link host-specific authorized keys as authorized_keys2, if a file for this
# host exists. sshd reads both files by default (AuthorizedKeysFile setting).
HOSTKEYS=~/.shellcustomization/authorized_keys_$(hostname -f)
if [ -e "${HOSTKEYS}" ]; then
  link "${HOSTKEYS}" ~/.ssh/authorized_keys2

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
link ~/.shellcustomization/.bashrc ~/.bashrc
link ~/.shellcustomization/.bash_profile ~/.bash_profile
link ~/.shellcustomization/.screenrc ~/.screenrc
link ~/.shellcustomization/.gitconfig ~/.gitconfig
link ~/.shellcustomization/.vimrc ~/.vimrc
link ~/.shellcustomization/.inputrc ~/.inputrc
link ~/.shellcustomization/.dircolors ~/.dircolors

# Make directory for screenlogs
mkdir -p ~/.screenlogs

# Make directories for vim undo/swap/backup files (see .vimrc)
mkdir -p ~/.vim/undo ~/.vim/swap ~/.vim/backup
