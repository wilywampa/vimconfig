#{{{1 Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt auto_cd beep extended_glob no_match notify no_beep
setopt share_history inc_append_history
# End of lines configured by zsh-newuser-install

#{{{1 Lines added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit -C
# End of lines added by compinstall

#{{{1 Basic settings
# Automatically use directory stack
setopt auto_pushd pushd_minus pushd_silent pushd_to_home pushd_ignoredups

# Be able to use ^S and ^Q
stty -ixon -ixoff

# Try to correct misspelled commands
setopt CORRECT

#{{{1 Aliases
alias sz='source ~/.zshrc'
alias ez='vim ~/.zshrc'
alias EXIT='exit'
alias grep='grep --color=auto'
alias egrep='grep -E'
alias fgrep='grep -F'
alias g='grep'
alias gi='grep -i'
alias f='find "`pwd`" -type f'
alias fd='find "`pwd`" -type d'
alias fmd='find "`pwd`" -maxdepth'
alias s="sed 's/.*/\"&\"/'"
alias fs='f | s'
alias fsg='fs | grep'
alias fsxg='fs | xargs grep'
alias fsa='fs | ag'
alias fsxa='fs | xargs ag'
alias d='dirs -v'
alias view='vim -R'
alias e='vim'
alias vims='vim -S ~/session.vis'
alias h='head'
alias t='tail'
alias svnadd="svn st | \grep '^?' | awk '{print \$2}' | s | xargs svn add"
alias svnrevert="svn st | \grep '^M' | awk '{print \$2}' | s | xargs svn revert"
alias svnrm="svn st | \grep '^?' | awk '{print \$2}' | s | xargs rm -r"
alias svnst="svn st | g -v '\.git'"
alias svndi="svnst | awk '{print \$2}' | s | xargs svn di"
alias ec='echo'
alias scrn='screen -R'
alias tmx='tmux attach || tmux new'
alias bell='echo -ne "\007"'
alias ls='ls -h --color=auto'
alias ll='ls -lsh'
alias lls='ls -lshrt'
alias lla='ls -lshA'
alias llas='ls -lshrtA'
alias llsa='ls -lshrtA'
alias hist='history 1'
alias csc='find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \
    | sed "s/.*/\"&\"/g" > csc.files ; cscope -R -b -i csc.files ; rm csc.files'
alias ag="ag --color-line-number=';33' -S"
alias psg='ps aux | grep -i'
hash ack >& /dev/null && alias a='ack'
hash ag >& /dev/null && alias a='ag'
alias awkp2="awk '{print \$2}'"
alias mktags='ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .'

#{{{1 Global aliases
alias -g LL='ls -lshrtA'
alias -g GG='grep --color=auto'
alias -g GI='grep --color=auto -i'
alias -g FFR='**/*(D.)'
alias -g FF='*(D.)'
alias -g TEST='&& echo "yes" || echo "no"'

#{{{1 Suffix aliases
alias -s vim='vi'

#{{{1 Key bindings
bindkey -v
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^?" backward-delete-char
bindkey          '^[[3~' delete-char
bindkey          '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey          '^[[B' down-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey          '^[OA' up-line-or-beginning-search
bindkey -M viins '^[OA' up-line-or-beginning-search
bindkey -M vicmd '^[OA' up-line-or-beginning-search
bindkey          '^[OB' down-line-or-beginning-search
bindkey -M viins '^[OB' down-line-or-beginning-search
bindkey -M vicmd '^[OB' down-line-or-beginning-search
bindkey -M vicmd 'gg' beginning-of-buffer-or-history
bindkey '^R' history-incremental-search-backward
bindkey '^N' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' history-incremental-search-forward
bindkey -M isearch '^E' accept-search
# Ctrl + arrow keys
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

function vi-last-line()
{
    zle end-of-buffer-or-history
    zle vi-first-non-blank
}
zle -N vi-last-line
bindkey -M vicmd 'G' vi-last-line

function self-insert-no-autoremove()
{
    LBUFFER="$LBUFFER$KEYS"
}
zle -N self-insert-no-autoremove
bindkey '|' self-insert-no-autoremove

function fg-job(){ fg }; zle -N fg-job; bindkey '^Z' fg-job

#{{{1 Functions
function kb2h()
{
    read IN
    while [ $IN ]; do
        SLIST="KB,MB,GB,TB,PB,EB,ZB,YB"
        POWER=1
        SIZE=$(echo $IN | cut -f1)
        NAME=$(echo $IN | cut -f2)
        VAL=$( echo "scale=2; $SIZE / 1" | bc)
        VINT=$( echo $VAL / 1024 | bc )
        while [ $VINT -gt 0 ]
        do
            let POWER=POWER+1
            VAL=$( echo "scale=2; $VAL / 1024" | bc)
            VINT=$( echo $VAL / 1024 | bc )
        done
        printf "%-10s %s\n" $VAL$( echo $SLIST | cut -f$POWER -d, ) $NAME
        read IN
    done
}

function bigdirs()
{
    find . -type d -not -name "." -exec du -k {} + | sort -n \
        | tail -n ${1:-$(echo $(tput lines)-4 | bc)} | kb2h
}

function cygyank()
{
    CUTBUFFER=$(cat /dev/clipboard | sed 's/\x0//g')
    zle yank
}
zle -N cygyank

function xclipyank()
{
    CUTBUFFER=$(xclip -o | sed 's/\x0//g')
    if [ -z $CUTBUFFER ]; then
        CUTBUFFER=$(xclip -o -sel b | sed 's/\x0//g')
    fi
    zle yank
}
zle -N xclipyank

if type xclip >& /dev/null ; then
    bindkey '^V' xclipyank
else
    bindkey '^V' cygyank
fi

function bigfiles()
{
    find . -type f -exec du -ak {} + | sort -n \
        | tail -n ${1:-$(echo $(tput lines)-4 | bc)} | kb2h
}

function md()
{
    mkdir -p "$@" && cd "$@";
}

function rationalise-dot()
{
    if [[ $LBUFFER = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}
zle -N rationalise-dot
bindkey -M viins . rationalise-dot
bindkey -M isearch . self-insert

function force-logout()
{
    zle vi-kill-line
    if [[ -o login ]]; then; logout; else; exit; fi
}
zle -N force-logout
bindkey '^D' force-logout
bindkey -M viins '^D' force-logout
bindkey -M vicmd '^D' force-logout

#{{{1 Environment variables
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    vim -X -R -c 'set ft=man nomod nolist' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""
export DIRSTACKSIZE=10
export KEYTIMEOUT=5
export VIMBLACKLIST="syntastic,vimshell,processing,scriptease,over,flake8"
if [ -e ~/.dircolors ]; then
    eval $(dircolors ~/.dircolors)
fi

#{{{1 Completion Stuff
[[ -z "$modules[zsh/complist]" ]] && zmodload zsh/complist

# Use shift-tab to select previous completion
bindkey               '^[[Z' reverse-menu-complete
bindkey -M viins      '^[[Z' reverse-menu-complete
bindkey -M vicmd      '^[[Z' reverse-menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Bring up completion menu after pressing tab once
setopt AUTO_MENU

# Enter executes line instead of exiting menu
bindkey -M menuselect '^M' .accept-line

# Ctrl-E accepts current completion
bindkey -M menuselect '^E' accept-search

# Faster! (?)
zstyle ':completion::complete:*' use-cache 1

# case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
#zstyle ':completion:*' completer _oldlist _expand _force_rehash _complete
zstyle ':completion:*' completer _expand _force_rehash _complete _approximate _ignored

# generate descriptions with magic.
zstyle ':completion:*' auto-description 'specify: %d'

# Don't prompt for a huge list, page it!
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Don't prompt for a huge list, menu it!
zstyle ':completion:*:default' menu 'select=0'

unsetopt LIST_AMBIGUOUS
setopt  COMPLETE_IN_WORD

# Separate man page sections.  Neat.
zstyle ':completion:*:manuals' separate-sections true

# complete with a menu for xwindow ids
zstyle ':completion:*:windows' menu on=0
zstyle ':completion:*:expand:*' tag-order all-expansions

# more errors allowed for large words and fewer for small words
zstyle ':completion:*:approximate:*' max-errors 'reply=(  $((  ($#PREFIX+$#SUFFIX)/3  ))  )'

# Errors format
zstyle ':completion:*:corrections' format '%B%d (errors %e)%b'

# Don't complete stuff already on the line
zstyle ':completion::*:(rm|vi):*' ignore-line true

# Don't complete directory we are already in (../here)
zstyle ':completion:*' ignore-parents parent pwd

zstyle ':completion::approximate*:*' prefix-needed false

# Faster path completion
zstyle ':completion:*' accept-exact '*(N)'

_force_rehash()
{
    (( CURRENT == 1 )) && rehash
    return 1  # Because we didn't really complete anything
}

# Display files with colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Process ID completion
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# Don't suggest _functions
zstyle ':completion:*:functions' ignored-patterns '_*'

#{{{1 Prompt stuff
# Show vi input mode
autoload -U colors && colors
setopt PROMPT_SUBST
vim_ins_mode="%{$fg[black]%}%{$bg[cyan]%}i%{$reset_color%}"
vim_cmd_mode="%{$fg[black]%}%{$bg[yellow]%}n%{$reset_color%}"
vim_mode=$vim_ins_mode

function zle-keymap-select()
{
    vim_mode="${${KEYMAP/(vicmd|opp)/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
    zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-finish()
{
    vim_mode=$vim_ins_mode
}
zle -N zle-line-finish

function TRAPINT()
{
    vim_mode=$vim_ins_mode
    return $(( 128 + $1 ))
}

# Ctrl-F opens Vim as command editor
autoload edit-command-line
zle -N edit-command-line
bindkey '^F' edit-command-line
bindkey -M viins '^F' edit-command-line
bindkey -M vicmd '^F' edit-command-line

_lineup=$'\e[1A'
_linedown=$'\e[1B'

PROMPT='
%{$fg[blue]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%} %{$fg[cyan]%}%d%{$reset_color%}
[zsh %{$fg[cyan]%}%1~%{$reset_color%} %{$fg[red]%}%1(j,+ ,)%{$reset_color%}${vim_mode}]%# '
RPROMPT='%{${_lineup}%}%{$fg_bold[green]%}%T%{$reset_color%} !%{$fg[red]%}%!%{$reset_color%}%{${_linedown}%}'

#{{{1 Machine-specific settings

source ~/.zshrclocal

# vim: set fdm=marker fdl=1:
