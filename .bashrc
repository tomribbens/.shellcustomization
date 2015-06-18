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


# Put your fun stuff here.
alias sudo='source ~/.ssh/ssh_env_vars; sudo'
alias git='source ~/.ssh/ssh_env_vars; git'
alias ssh='source ~/.ssh/ssh_env_vars; ssh'
alias please='sudo $(history -p !!)'
alias ll='ls -lh'
alias la='ls -la'
alias d1='du -h --max-depth=1'
alias ifconfig='source ~/.ssh/ssh_env_vars; sudo ifconfig'

# If vim is installed, use it as the default editor
if [[ -e /usr/bin/vim ]] ; then
	export EDITOR='/usr/bin/vim'
fi


# Set the prompts:
PS1="\[\033[01;37m\]\$? \$(if [[ \$? == 0 ]]; then echo \"\[\033[01;32m\];)\"; else echo \"\[\033[01;31m\];(\"; fi) $(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;31m\]\h'; else echo '\[\033[01;32m\]\u@\h'; fi)\[\033[01;34m\] \w \$\[\033[00m\] "

# Add possibility to add local .bashrc extensions
if [[ -d ~/.bashrc.d ]]; then
	for SCRIPT in ~/.bashrc.d/*
	do
		if [ -f $SCRIPT ]
		then
			$SCRIPT
		fi
	done
fi
