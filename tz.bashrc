# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
umask 022

have_run() { have "$@" && "$@"; }
have_source()
{
	while [ -n "$1" ]
	do
		[ -r "$1" ] && . "$1"
		shift
	done
}

# bash-completion
have_source /etc/bash_completion
have_source /usr/share/bash-completion/bash_completion

have() { which "$@" &>/dev/null; }	# this function must be after bash_completion

tilde() { echo "${1/$HOME/~}"; } # /home/xxx/a -> ~/a

# TTY & PTS
if tty -s; then
	TTY=`tty`
	PTS=${TTY##/dev/}
	[ "$PTS" == "$TTY" ] && unset PTS
fi

PROMPT_COMMAND="${PROMPT_COMMAND:-:}" # : cmd

title() { echo -en "\033]2;$@\007"; } # set term title

#PROMPT_COMMAND="$PROMPT_COMMAND ; "'title "$HOSTNAME:`basename "$PWD"`" "($LINENO)"'
PROMPT_COMMAND="$PROMPT_COMMAND ; "'title "$PTS@$HOSTNAME:"`tilde "$PWD"`"" "($LINENO)"'

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto -v'
have dircolors && eval "`dircolors`"
#alias ls='ls $LS_OPTIONS'

# ls, add -l if non-option arg <= 3 && >0
unalias ls 2>/dev/null
ls()
{
	local extra_opt v c=0 maxfile=3

	for v in "$@"
	do
		case "$v" in
			-*)
				;;
			*)
				let c++
				[ $c -gt $maxfile ] &&
					break 2
				[ -d "$v" ] &&
					c=100 && break 2
				;;
		esac
	done
	[ $c -le $maxfile ] && [ $c -gt 0 ] &&
		extra_opt='-l'
	command ls $LS_OPTIONS $extra_opt "$@"
}

alias ll='ls -la'
alias  l='ls -th'
alias lt='ls -t'
alias la='ls -A'
alias lh='ls -lh'
alias l.='ls -d .*'
alias  d='ls -dA */ .*/'
# l* alias completion
_ls() { shift; _longopt ls "$@"; }
complete -F _ls l{,s,l,t,a,h,.} d

shopt -s autocd	# cd into dir by type dir w/o cd
alias ..='cd ..'
alias ....='cd ../..'
alias md='mkdir -pv'
alias du1='du --max-depth=1'

export GREP_OPTIONS='--color=auto'
alias g='LC_ALL=C grep -P'

# Some more alias to show mistakes:
alias rm='rm -v --one-file-system'
alias cp='cp -iv'
alias mv='mv -iv'
alias ln='ln -iv'
alias rd='rm -rfv --one-file-system'
#complete -F _longopt rd

alias chmod='chmod --preserve-root --changes'
alias chown='chown --preserve-root --changes'
alias chgrp='chgrp --preserve-root --changes'

alias wget='wget --continue'
alias ngrep='ngrep -W byline -e'
alias ng=ngrep
alias myip='echo $(curl -s bot.whatismyipaddress.com)'
alias ping='ping -n'

alias k=killall

# less
have lesspipe && eval "$(lesspipe)"

# PATH
export PATH="$PATH:~/scripts"

# colorgcc
have colorgcc && alias gcc='colorgcc -Wall'

# cdargs
have_source /usr/share/doc/cdargs/examples/cdargs-bash.sh	# debian
have_source /usr/share/cdargs/cdargs-lib.sh	# cygwin
have_source /usr/share/cdargs/cdargs-alias.sh	# cygwin
alias cv=cdb &&
export CDARGS_BASH_ALIASES='cdb cv'
have_source /usr/share/cdargs/cdargs-bash-completion.sh	# cygwin


# battery
have_source /root/scripts/battery.sh

# history
HISTFILESIZE=20000
HISTSIZE=1000
HISTCONTROL=erasedups:ignoredups # remove duplicate histories
shopt -s histappend
shopt -s histverify # edit b4 run cmd
PROMPT_COMMAND="$PROMPT_COMMAND ; history -a; history -c; history -r"

# remove redundant histories
if [ -n "$HISTFILE" ]; then
	tac "$HISTFILE" |nl |sort -uk 2 |sort -h |sed -r 's/^ +[0-9]+\t+//' \
	|tac >"$HISTFILE".pid$$ &&
	\mv -f "$HISTFILE".pid$$ "$HISTFILE"
fi

# tabstop=4
tabs 4 &>/dev/null
alias less='less -x4'

# expand **
shopt -s globstar

pst()
{
  pstree -halG "$@"|grep --color=never -oP '^.*\S(?=\s*$)'
}

#if [ $EUID == 0 ]; then
#	PS1='\e[1;33m\u\e[m$(rcode=$?; [ $rcode != 0 ] && echo -n "\e[m[\e[1;31m$rcode\e[m]" ||echo -n "@")\e[m\e[1;32m\h\e[m:\e[1;32m\w\e[m\n\$ '
#else
#	PS1='\e[1;32m\u\e[m$(rcode=$?; [ $rcode != 0 ] && echo -n "\e[m[\e[1;31m$rcode\e[m]" ||echo -n "@")\e[m\e[1;32m\h\e[m:\e[1;32m\w\e[m\n\$ '
#fi

PS1='\e[1;33m\u\e[m$(rcode=$?;
	[ $rcode -gt 128 ] &&
		signal=$(builtin kill -l $rcode 2>/dev/null) &&
		[ x$signal != x ] &&
			signal=':'${signal:3};
	[ $rcode != 0 ] &&
		echo -n "\e[m[\e[1;31m$rcode\e[1;33m$signal\e[m]" ||
		echo -n "@")$(
	[ -n "$STY" ] &&
		sty="\e[m\e[1;32m${STY#*.}\e[m" &&
		echo -n "$sty"@
	)\e[m\e[1;32m\h\e[m:\e[1;32m\w\e[m\n$(
	[ $EUID == 0 ] &&
		echo -n "￥" ||
		echo -n "$ "
	)'

if [ -r ~/site.bashrc ]; then
	. ~/site.bashrc
fi



