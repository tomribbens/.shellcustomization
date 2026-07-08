# /etc/skel/.bash_profile

# Keep a stable path to the forwarded SSH agent socket.
#
# Every new SSH connection creates a fresh $SSH_AUTH_SOCK (e.g.
# /tmp/ssh-XXXX/agent.NNN). Shells running inside a long-lived screen session
# captured the *old* path when they started, so after reattaching over a new
# connection they point at a dead socket. Re-point a stable symlink at the
# current live socket; .bashrc makes every shell use that stable path instead.
if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
fi

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Compress finished screen logs in the background on every login. Never blocks
# the login; the script is idempotent and skips logs still open by a window.
if [ -x ~/.shellcustomization/compress-screenlogs.sh ]; then
	~/.shellcustomization/compress-screenlogs.sh >/dev/null 2>&1 &
	disown
fi

# Start screen, unless this host opts out. Create ~/.no_auto_screen (e.g. on a
# local workstation where you want the dotfiles but not the auto screen login).
if [ ! -e ~/.no_auto_screen ]; then
	screen -xRR
fi
