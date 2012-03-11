# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Save SSH_* environment variables to be used in screen.
env | grep SSH_ | sed -e 's/=/="/' -e 's/SSH_/export SSH_/' -e 's/$/"/'> ~/.ssh/ssh_env_vars

# Start screen
screen -xRR
