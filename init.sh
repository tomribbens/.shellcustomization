#!/bin/bash

# ---------------------------------------------------------------------------
# Dependency check: make sure the tools these dotfiles rely on are installed.
# If any are missing, print the install command for the detected package
# manager and offer to run it (never installs without asking).
# ---------------------------------------------------------------------------
REQUIRED_CMDS=(git screen vim gzip lsof)

# Gentoo needs category/name atoms; every other package manager below uses the
# bare command name, which matches the package name for all of these tools.
emerge_atom() {
  case "$1" in
    git)    echo dev-vcs/git ;;
    screen) echo app-misc/screen ;;
    vim)    echo app-editors/vim ;;
    gzip)   echo app-arch/gzip ;;
    lsof)   echo sys-process/lsof ;;
    *)      echo "$1" ;;
  esac
}

missing=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing required tools: ${missing[*]}" >&2

  if command -v emerge >/dev/null 2>&1; then
    atoms=()
    for c in "${missing[@]}"; do atoms+=("$(emerge_atom "${c}")"); done
    install_cmd="sudo emerge --ask ${atoms[*]}"
  elif command -v apt-get >/dev/null 2>&1; then
    install_cmd="sudo apt-get install ${missing[*]}"
  elif command -v dnf >/dev/null 2>&1; then
    install_cmd="sudo dnf install ${missing[*]}"
  elif command -v yum >/dev/null 2>&1; then
    install_cmd="sudo yum install ${missing[*]}"
  elif command -v pacman >/dev/null 2>&1; then
    install_cmd="sudo pacman -S ${missing[*]}"
  elif command -v zypper >/dev/null 2>&1; then
    install_cmd="sudo zypper install ${missing[*]}"
  elif command -v apk >/dev/null 2>&1; then
    install_cmd="sudo apk add ${missing[*]}"
  else
    install_cmd=""
  fi

  if [ -n "${install_cmd}" ]; then
    echo "Suggested install command:" >&2
    echo "    ${install_cmd}" >&2
    read -r -p "Run it now? [y/N] " ans
    case "${ans}" in
      [yY]|[yY][eE][sS]) eval "${install_cmd}" ;;
      *) echo "Skipping install; continuing with setup." >&2 ;;
    esac
  else
    echo "No known package manager detected; please install the tools manually." >&2
  fi
fi

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

# Pull the shared SSH client defaults (ssh_config) into ~/.ssh/config via an
# Include line, without clobbering host-specific entries already there. Also
# create the connection-multiplexing control dir with safe perms.
mkdir -p ~/.ssh/control
chmod 700 ~/.ssh ~/.ssh/control 2>/dev/null
INCLUDE_LINE="Include ~/.shellcustomization/ssh_config"
if [ ! -e ~/.ssh/config ] || ! grep -qxF "${INCLUDE_LINE}" ~/.ssh/config; then
  { echo "${INCLUDE_LINE}"; echo; cat ~/.ssh/config 2>/dev/null; } > ~/.ssh/config.new
  mv ~/.ssh/config.new ~/.ssh/config
  chmod 600 ~/.ssh/config
  echo "Added '${INCLUDE_LINE}' to ~/.ssh/config."
fi

# Link files
link ~/.shellcustomization/.bashrc ~/.bashrc
link ~/.shellcustomization/.bash_profile ~/.bash_profile
link ~/.shellcustomization/.screenrc ~/.screenrc
link ~/.shellcustomization/.gitconfig ~/.gitconfig
link ~/.shellcustomization/.vimrc ~/.vimrc
link ~/.shellcustomization/.inputrc ~/.inputrc
link ~/.shellcustomization/.dircolors ~/.dircolors
link ~/.shellcustomization/.gitignore_global ~/.gitignore_global

# Make directory for screenlogs
mkdir -p ~/.screenlogs

# Make directories for vim undo/swap/backup files (see .vimrc)
mkdir -p ~/.vim/undo ~/.vim/swap ~/.vim/backup
