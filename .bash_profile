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

# Start screen
screen -xRR
