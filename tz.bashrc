
# my bashrc

# recommended softwares:
# apt-get install colordiff less cdargs psmisc bash-completion
# https://github.com/account-login/pager_wrapper/
# https://github.com/account-login/packer
# jq rg fd


# begin bashrc begins
umask 022

# handle crlf on windows
set -o igncr 2>/dev/null || :
# turn off history substitution
set +H
# show failed return code in a pipeline
set -o pipefail
export SHELLOPTS

# python output encoding
export PYTHONIOENCODING=utf-8

# avoid confusing date time format
export LC_TIME=C

function have_cmd() { which "$@" &>/dev/null; }
function run_if_have() { have_cmd "$@" && "$@"; }
function source_if_have() {
    while [ -n "$1" ]
    do
        [ -r "$1" ] && . "$1"
        shift
    done
}

# bash-completion
source_if_have /etc/bash_completion
source_if_have /usr/share/bash-completion/bash_completion

function tilde() {
    case "$1" in
    "$HOME"|"$HOME"/*)
        local hl=${#HOME}
        echo "~${1:$hl}"
        ;;
    *)
        echo "$1"
        ;;
    esac
}

# overridable hostname for ps1 and title
ALT_HOST_NAME="${ALT_HOST_NAME:-$HOSTNAME}"

# TTY & PTS
if tty -s; then
    TTY="$(tty)"
    PTS="${TTY##/dev/}"
    if [ "$PTS" == "$TTY" ]; then
        unset PTS
    fi
fi

PROMPT_COMMAND=":"

function title() { echo -en "\033]2;$*\007"; }  # set term title

PROMPT_COMMAND="$PROMPT_COMMAND ; "'title "$PTS@$ALT_HOST_NAME:"`tilde "$PWD"`"" "($LINENO)"'

# have_cmd dircolors && eval "`dircolors`"

# ls, add -l if non-option arg <= 3 && >0
unalias ls 2>/dev/null
ls() {
    local extra_opt v c=0 maxfile=3 allarg=0

    for v in "$@"; do
        case "$v" in
        --)
            allarg=1
            ;;
        *)
            if [[ $allarg == 0 ]] && [[ "$v" == -* ]]; then
                continue
            fi

            (( c++ ))
            if [ "$c" -gt "$maxfile" ]; then
                break 2
            fi
            if [ -d "$v" ]; then
                c=100
                break 2
            fi
            ;;
        esac
    done
    if [ "$c" -le "$maxfile" ] && [ "$c" -gt 0 ]; then
        extra_opt='-l'
    fi
    command ls --color=auto --time-style="+%Y-%m-%d %H:%M:%S" -v $extra_opt "$@"
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
if type _longopt >/dev/null 2>&1; then
    complete -F _ls l{,s,l,t,a,h,.} d
fi

#shopt -s autocd    # cd into dir by type dir without cd
alias ..='cd ..'
alias ....='cd ../..'
alias md='mkdir -pv'
alias du1='du --max-depth=1'

alias grep="grep --color=auto"
alias g="grep -P"

# Some more alias to show mistakes:
alias rm='rm -v --one-file-system'
alias cp='cp -iv'
alias mv='mv -iv'
alias ln='ln -iv'
alias rd='rm -rfv --one-file-system'

alias chmod='chmod --preserve-root --changes'
alias chown='chown --preserve-root --changes'
alias chgrp='chgrp --preserve-root --changes'

#alias wget='wget --continue'
alias ngrep='ngrep -W byline -e -qt'
alias ng=ngrep
alias myip='echo $(curl -s bot.whatismyipaddress.com)'
alias ping='ping -n'
alias rg='rg --path-separator=/'
alias fd='fd --path-separator=/'

# less
have_cmd lesspipe && eval "$(lesspipe)"

# pager
PAGER="more"
if have_cmd less; then
    if have_cmd pager_wrapper; then
        PAGER="pager_wrapper"
    else
        PAGER="less"
    fi
    # display color and verbose prompt
    LESS="-R -M"
    # tabstop=4
    LESS="$LESS -x4"
    # don't clear screen when quit, mouse wheel not working
    #LESS="$LESS --no-init"
    # quit if the entire file can be displayed on the first screen, must be used with --no-init
    #LESS="$LESS --quit-if-one-screen"
    export LESS
fi
export PAGER
# unicode support for less
export LESSCHARSET=utf-8

# termcap terminfo
# mb      blink     start blink
# md      bold      start bold
# me      sgr0      turn off bold, blink and underline
# so      smso      start standout (reverse video)
# se      rmso      stop standout
# us      smul      start underline
# ue      rmul      stop underline

# less colors
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[0;30;48;5;118m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;33m'
export GROFF_NO_SGR=1   # for colored man pages

# git aliases
alias gits='git status'
function gitc() { git commit -am "$*"; }    # arguments of gitc will be joined
alias gitamend='git commit -a --amend --no-edit'
alias gitd='git diff'
alias gitl='git log'

# colordiff
have_cmd colordiff && alias diff='colordiff'

# PATH
export PATH="$PATH:~/scripts"

# cdargs
source_if_have /usr/share/doc/cdargs/examples/cdargs-bash.sh    # debian
source_if_have /usr/share/cdargs/cdargs-lib.sh      # cygwin
source_if_have /usr/share/cdargs/cdargs-alias.sh    # cygwin
alias cv=cdb && export CDARGS_BASH_ALIASES='cdb cv'
source_if_have /usr/share/cdargs/cdargs-bash-completion.sh  # cygwin


# battery
source_if_have /root/scripts/battery.sh

# history
HISTFILESIZE=20000
HISTSIZE=20000
HISTCONTROL=ignorespace:erasedups:ignoredups    # remove duplicate histories
shopt -s histappend
shopt -s histverify # edit b4 run cmd
# read history every time is dangerous, up arrow will not work as expected.
# PROMPT_COMMAND="$PROMPT_COMMAND ; history -a; history -c; history -r"
# write history after every command.
PROMPT_COMMAND="$PROMPT_COMMAND ; history -a"
# backup history file
function _ts_fmt() {
    date +'%Y-%m-%d %H:%M:%S.%3N'
}
function _backup_history() {
    echo "$(_ts_fmt) $(printf "% 11s" \[pid:$$]) [pwd:$PWD] $(history 1)" >>~/.shell_history.log
}
PROMPT_COMMAND="$PROMPT_COMMAND ; _backup_history"

# remove redundant histories
if [ -n "$HISTFILE" ]; then (
    set -o pipefail
    export LC_ALL=C
    echo 'echo can not source/execute bash_history; exit' >"$HISTFILE".pid$$
    tac "$HISTFILE" |nl |sort -uk 2 |sort -h |sed -r 's/^ +[0-9]+\t+//' \
        |tac >>"$HISTFILE".pid$$ &&
    command mv -f "$HISTFILE".pid$$ "$HISTFILE"
)
fi

# tabstop=4
tabs 4 &>/dev/null
#alias less='less -x4'

# expand **
shopt -s globstar

# ulimit
ulimit -c unlimited

# pstree
function pst() {
    pstree -halG "$@" |grep --color=never -oP '^.*\S(?=\s*$)'
}

# colors
COLOR_YELLOW=$'\e[1;33m'
COLOR_RED=$'\e[1;31m'
COLOR_GREEN=$'\e[1;32m'
COLOR_NO=$'\e[m'

function cygdrive_to_win() {
    local path="$1"

    case "$path" in
    /cygdrive/?)
        path="${path}/" # /cygdrive/h -> /cygdrive/h/
    esac

    case "$path" in
    /cygdrive/?/*)
        local path="${path#/cygdrive/}" # /cygdrive/h/abc/xyz -> h/abc/xyz
        path="${path/\//:\\}"   # h/abc/xyz -> h:\abc/xyz
        path="${path//\//\\}"   # h:\abc/xyz -> h:\abc\xyz
        path="${path^?}"        # h:\abc\xyz -> H:\abc\xyz
    esac

    echo "$path"
}

function _ps1_middle() {
    local rcode=$?
    local signal=
    if [ $rcode -gt 128 ]; then
        # get signal name from return code
        signal=$(builtin kill -l $rcode 2>/dev/null)
        if [ x"$signal" != x ]; then
            signal=':'${signal#SIG}
        fi
    fi
    # `@` symbol or last return code
    if [ $rcode != 0 ]; then
        echo -n "[${COLOR_RED}$rcode${COLOR_YELLOW}$signal${COLOR_NO}]"
    else
        echo -n "@"
    fi
}

# prompt
PS1=''
# user_name
PS1="$PS1"'${COLOR_YELLOW}\u${COLOR_NO}'
# @
PS1="$PS1"'$(_ps1_middle)'
# screen
if [ -n "$STY" ]; then
    PS1="$PS1"'${COLOR_GREEN}${STY#*.}${COLOR_NO}|'
fi
# host
PS1="$PS1"'${COLOR_GREEN}${ALT_HOST_NAME}${COLOR_NO}'
# :pwd
PS1="$PS1"':${COLOR_GREEN}$(tilde "$(cygdrive_to_win "$PWD")")${COLOR_NO}'
# $
if [ $EUID == 0 ]; then
    PS1="$PS1"$'\n￥'
else
    PS1="$PS1"$'\n$ '
fi

# site specific bashrc
if [ -r ~/site.bashrc ]; then
    . ~/site.bashrc
fi
