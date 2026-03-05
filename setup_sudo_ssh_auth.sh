#!/bin/bash
# Sets up sudo authentication via SSH agent key forwarding.
# Detects the current distro (Debian/Ubuntu or Gentoo), installs the
# required PAM module, and configures PAM and sudoers accordingly.

set -e

PAM_SUDO="/etc/pam.d/sudo"
SUDOERS_DROP="/etc/sudoers.d/ssh_agent_auth"
PAM_MODULE_LINE=$'auth\tsufficient\tpam_ssh_agent_auth.so\tfile=~/.ssh/authorized_keys'

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Detect distro
if [[ -f /etc/debian_version ]]; then
    DISTRO="debian"
elif [[ -f /etc/gentoo-release ]]; then
    DISTRO="gentoo"
else
    echo "Unsupported distro. Only Debian/Ubuntu and Gentoo are supported." >&2
    exit 1
fi

echo "Detected distro: ${DISTRO}"

# Install the PAM SSH agent auth package
if [[ "${DISTRO}" == "debian" ]]; then
    apt-get update -q
    apt-get install -y libpam-ssh-agent-auth
elif [[ "${DISTRO}" == "gentoo" ]]; then
    emerge --ask=n sys-auth/pam_ssh_agent_auth
fi

# Configure PAM: insert pam_ssh_agent_auth before the first auth line in
# /etc/pam.d/sudo so SSH agent keys are tried first (sufficient).
if grep -q 'pam_ssh_agent_auth' "${PAM_SUDO}"; then
    echo "pam_ssh_agent_auth is already configured in ${PAM_SUDO}, skipping."
else
    # Back up the original PAM sudo config before modifying it.
    cp "${PAM_SUDO}" "${PAM_SUDO}.bak"

    # Insert the new auth line before the first existing 'auth' line using
    # awk to avoid delimiter conflicts present with sed.
    awk -v line="${PAM_MODULE_LINE}" \
        'inserted==0 && /^auth/ { print line; inserted=1 } { print }' \
        "${PAM_SUDO}.bak" > "${PAM_SUDO}"

    echo "Updated ${PAM_SUDO} with pam_ssh_agent_auth (backup: ${PAM_SUDO}.bak)."
fi

# Configure sudoers to preserve SSH_AUTH_SOCK
if [[ -f "${SUDOERS_DROP}" ]]; then
    echo "Sudoers drop-in ${SUDOERS_DROP} already exists, skipping."
else
    SUDOERS_TMP=$(mktemp)
    echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > "${SUDOERS_TMP}"
    # Validate the file syntax before installing it.
    if visudo -c -f "${SUDOERS_TMP}"; then
        install -m 0440 "${SUDOERS_TMP}" "${SUDOERS_DROP}"
        echo "Created ${SUDOERS_DROP} to preserve SSH_AUTH_SOCK."
    else
        echo "Sudoers syntax check failed; ${SUDOERS_DROP} was not created." >&2
        rm -f "${SUDOERS_TMP}"
        exit 1
    fi
    rm -f "${SUDOERS_TMP}"
fi

echo "Done. SSH agent key forwarding authentication for sudo is now configured."
