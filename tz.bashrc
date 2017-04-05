
# my bashrc

# prerequisites:
# apt-get install colordiff less most cdargs psmisc bash-completion
# pip install diff-highlight

# todo:
# test with non-root user


# some functions for fun
function assert() {
    local exp="$1"
    local msg="$2"

    if ! eval "$exp"; then
        echo "Assertion failed: exp='$exp', msg='$msg'" 1>&2
    fi
}

function strlen() {
    local str="$1"
    echo "${#str}"
}

function strchr() {
    local str="$1"
    local chr="$2"
    assert "[[ \$(strlen "$chr") == 1 ]]" "Illegal char='$chr'"
    local -i len=$(strlen "$str")

    local -i n
    for n in $(seq 0 $(( $len - 1 )) ); do
        if [[ "${str:$n:1}" == "$chr" ]]; then
            echo $n
            return
        fi
    done
    echo -1
}

function strstr() {
    local s1="$1"
    local s2="$2"
    assert "[[ -n '$s2' ]]" "\$s2 shoud not be empty"
    local -i end=$(( $(strlen "$s1") - $(strlen "$s2") ))
    local -i len2=$(strlen "$s2")

    local -i n
    for n in $(seq 0 $end); do
        if [[ "${s1:$n:$len2}" == "$2" ]]; then
            echo $n
            return
        fi
    done
    echo -1;
}

# begin bashrc begins
umask 022

have_cmd() { which "$@" &>/dev/null; }
run_if_have() { have_cmd "$@" && "$@"; }
source_if_have() {
    while [ -n "$1" ]
    do
        [ -r "$1" ] && . "$1"
        shift
    done
}

# bash-completion
source_if_have /etc/bash_completion
source_if_have /usr/share/bash-completion/bash_completion

tilde() { echo "${1/$HOME/~}"; } # /home/xxx/a -> ~/a

# TTY & PTS
if tty -s; then
    TTY="$(tty)"
    PTS="${TTY##/dev/}"
    if [ "$PTS" == "$TTY" ]; then
        unset PTS
    fi
fi

PROMPT_COMMAND="${PROMPT_COMMAND:-:}" # : cmd

title() { echo -en "\033]2;$@\007"; } # set term title

PROMPT_COMMAND="$PROMPT_COMMAND ; "'title "$PTS@$HOSTNAME:"`tilde "$PWD"`"" "($LINENO)"'

# have_cmd dircolors && eval "`dircolors`"

LS_OPTIONS='--color=auto -v'
# ls, add -l if non-option arg <= 3 && >0
unalias ls 2>/dev/null
ls() {
    local extra_opt v c=0 maxfile=3 allarg=0

    for v in "$@"
    do
        case "$v" in
        --)
            allarg=1
            ;;
        *)
            if [[ $allarg == 0 ]] && [[ "$v" == -* ]]; then
                continue
            fi

            let c++
            if [ $c -gt $maxfile ]; then
                break 2
            fi
            if [ -d "$v" ]; then
                c=100
                break 2
            fi
            ;;
        esac
    done
    if [ $c -le $maxfile ] && [ $c -gt 0 ]; then
        extra_opt='-l'
    fi
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
if type _longopt 2>&1 >/dev/null; then
    complete -F _ls l{,s,l,t,a,h,.} d
fi

#shopt -s autocd    # cd into dir by type dir without cd
alias ..='cd ..'
alias ....='cd ../..'
alias md='mkdir -pv'
alias du1='du --max-depth=1'

GREP_OPTIONS='--color=auto'
alias grep="grep $GREP_OPTIONS"
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
alias ngrep='ngrep -W byline -e'
alias ng=ngrep
alias myip='echo $(curl -s bot.whatismyipaddress.com)'
alias ping='ping -n'

alias k=killall

# less
have_cmd lesspipe && eval "$(lesspipe)"

# pager
PAGER=more
if have_cmd less; then
    PAGER=less
    # display color
    LESS="-R"
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
export LESSCHARSET=utf-8 less

# colored manpage
if have_cmd most; then
    function man() { PAGER=most command man "$@"; }
fi

# git pager
if have_cmd diff-highlight; then
    export GIT_PAGER="diff-highlight | $PAGER"
    #export GIT_PAGER="diff-highlight | less" # most 效果不好
fi

# git aliases
alias gits='git status'
function gitc() { git commit -am "$(echo "$@")"; }  # arguments of gitc will be joined
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
HISTSIZE=1000
HISTCONTROL=erasedups:ignoredups # remove duplicate histories
shopt -s histappend
shopt -s histverify # edit b4 run cmd
# read history every time is dangerous, up arrow will not work as expected.
# PROMPT_COMMAND="$PROMPT_COMMAND ; history -a; history -c; history -r"
# write history after every command.
PROMPT_COMMAND="$PROMPT_COMMAND ; history -a"

# remove redundant histories
if [ -n "$HISTFILE" ]; then
    echo 'echo can not source/execute bash_history; exit' >"$HISTFILE".pid$$
    tac "$HISTFILE" |nl |sort -uk 2 |sort -h |sed -r 's/^ +[0-9]+\t+//' \
    |tac >>"$HISTFILE".pid$$ &&
    command mv -f "$HISTFILE".pid$$ "$HISTFILE"
fi

# tabstop=4
tabs 4 &>/dev/null
#alias less='less -x4'

# expand **
shopt -s globstar

pst() {
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

# prompt
PS1='${COLOR_YELLOW}\u${COLOR_NO}$(     # user name
        rcode=$?;   # return code of last command
        if [ $rcode -gt 128 ]; then
            # get signal name from return code
            signal=$(builtin kill -l $rcode 2>/dev/null)
            if [ x$signal != x ]; then
                signal=':'${signal:3}
            fi
        fi
        if [ $rcode != 0 ]; then
            echo -n "[${COLOR_RED}$rcode${COLOR_YELLOW}$signal${COLOR_NO}]"
        else
            echo -n "@"
        fi
    )$(
        if [ -n "$STY" ]; then
            sty="${COLOR_GREEN}${STY#*.}${COLOR_NO}"
            echo -n "$sty|"     # screen
        fi
    )${COLOR_GREEN}\h${COLOR_NO}:${COLOR_GREEN}$(   # host name
        cygdrive_to_win "$PWD"  # pwd
    )${COLOR_NO}\n$(
        if [ $EUID == 0 ]; then
            echo -n "￥"
        else
            echo -n "$ "
        fi
    )'

# site specific bashrc
if [ -r ~/site.bashrc ]; then
    . ~/site.bashrc
fi
