# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Use the stable SSH agent socket maintained by .bash_profile, so this shell
# keeps reaching a live forwarded agent even after screen is reattached over a
# new SSH connection (the symlink is re-pointed on each login).
if [ -S "$HOME/.ssh/ssh_auth_sock" ] || [ -L "$HOME/.ssh/ssh_auth_sock" ]; then
	export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
fi

# History: keep lots of it, drop dupes/space-prefixed commands, timestamp
# entries, and flush after every command so parallel screen windows don't
# clobber each other's history on exit.
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth
HISTTIMEFORMAT='%F %T '
shopt -s histappend cmdhist
PROMPT_COMMAND='history -a'

# Programmable completion for git, systemctl, etc. (guarded for portability
# across hosts that may not have bash-completion installed).
if ! shopt -oq posix && [ -r /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
fi

# If ~/bin/ exists, add it to $PATH
if [[ ":$PATH:" != *":$HOME/bin:"* && ":$PATH:" != *":~/bin:"* ]] && [[ -d ~/bin/ ]]; then
    export PATH=$PATH:~/bin
fi

# If ~/.local/bin/ exists, add it to $PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* && ":$PATH:" != *":~/.local/bin:"* ]] && [[ -d ~/.local/bin/ ]]; then
    export PATH=$PATH:~/.local/bin
fi

# Npm is local
export NPM_CONFIG_PREFIX=$HOME/.local/

# Put your fun stuff here.
alias sudo='sudo '
alias please='sudo $(history -p !!)'
alias ll='ls -lh'
alias la='ls -la'
alias d1='du -h --max-depth=1'
alias ifconfig='sudo ifconfig'
# alias sudo='sudo ' # Allow aliases to be used with sudo. See http://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
alias tb="nc termbin.com 9999"

# If vim is installed, use it as the default editor
if [[ -e /usr/bin/vim ]] ; then
	export EDITOR='/usr/bin/vim'
fi


# Set the prompts:
PS1="\[\033[01;37m\]\$? \$(if [[ \$? == 0 ]]; then echo \"\[\033[01;32m\];)\"; else echo \"\[\033[01;31m\];(\"; fi) $(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;31m\]\h'; else echo '\[\033[01;32m\]\u@\h'; fi)\[\033[01;35m\] \w \$\[\033[00m\] "

# Apply the dircolors settings
eval "$(dircolors ~/.dircolors)"

# Add possibility to add local .bashrc extensions
if [[ -d ~/.bashrc.d ]]; then
	for SCRIPT in ~/.bashrc.d/*
	do
		if [ -f $SCRIPT ]
		then
			source $SCRIPT
		fi
	done
fi

# Check if a .bashrc for the specific host exist
LOCALFILE="${HOME}/.shellcustomization/.bashrc_$(hostname -f)"
if [[ -e ${LOCALFILE} && -f ${LOCALFILE} ]] ; then
	# Local file exists, now source it
	source ${LOCALFILE}
fi

# opencode
export PATH=/home/tom/.opencode/bin:$PATH
export LIBVIRT_DEFAULT_URI=qemu:///system
