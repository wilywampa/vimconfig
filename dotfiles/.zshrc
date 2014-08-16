#[[[1 Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt auto_cd beep extended_glob no_match notify no_beep share_history
setopt inc_append_history extended_history interactive_comments
setopt hist_expire_dups_first
# End of lines configured by zsh-newuser-install

#[[[1 Lines added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit -C
# End of lines added by compinstall

#[[[1 Basic settings
# Automatically use directory stack
setopt auto_pushd pushd_minus pushd_silent pushd_to_home pushd_ignoredups

# Be able to use ^S and ^Q
stty -ixon -ixoff

# Try to correct misspelled commands
setopt CORRECT

#[[[1 Aliases
# zsh
alias sz='source ~/.zshrc'
alias EXIT='exit'
alias s="sed 's/.*/\"&\"/'"
alias so='source'
alias wh='whence'
alias reset='reset; source ~/.zshrc'
alias com='command'

# grep
alias grep='grep --color=auto'
alias egrep='grep -E'
alias fgrep='grep -F'
alias g='grep'
alias gi='grep -i'

# find
alias f='find .'
alias fa='find . | ag'
alias ff='find . -type f'
alias ffa='find . -type f | ag'
alias fn='find . -type f -iname'
alias fnc='find . -type f -name'
alias fnr='find . -type f -iregex'
alias fnrc='find . -type f -regex'
alias fd='find . -type d'
alias fda='find . -type d | ag'
alias fdn='find . -type d -iname'
alias fmd='find . -maxdepth'
alias fs='f | s'
alias fsg='fs | grep'
alias fsgi='fs | grep -i'
alias fsxg='fs | xargs grep'
alias fsa='fs | ag'
alias fsxa='fs | xargs ag'

# locate
alias loc='locate --regex'
alias locate='locate --regex'

# vim
alias vim='vim --servername VIM'
alias vit='vim --servername VIM --remote-tab'
alias view='vim -R'
alias e='vim'
alias vims='vim -S ~/session.vis'
alias vimr='vim -S =(<~/periodic_session.vis)'
alias gvims='gvim -S ~/session.vis'
alias ez='vim ~/.zshrc'

# svn
alias svnadd="svn st | grep '^?' | awk '{print \$2}' | s | xargs svn add"
alias svnrevert="svn st | grep '^M' | awk '{print \$2}' | s | xargs svn revert"
alias svnrm="svn st | grep '^?' | awk '{print \$2}' | s | xargs rm -r"
alias svnst="svn st | g -v '\.git'"
alias svndi="svnst | awk '{print \$2}' | s | xargs svn di"
svnexport() {
    mkdir -p "$1"
    svn st | grep '^[MA]' | awk '{print $2}' | xargs -I {} cp --parents {} "$1"
}

# hg
alias hgadd="hg st | grep '^?' | awk '{print \$2}' | s | xargs hg add"
alias hgrevert="hg st | grep '^M' | awk '{print \$2}' | s | xargs hg revert"
alias hgrm="hg st | grep '^?' | awk '{print \$2}' | s | xargs rm -r"
alias hgst="hg st | g -v '\.git'"
alias hgdi="hgst | awk '{print \$2}' | s | xargs hg di"
hgexport() {
    mkdir -p "$1"
    hg st | grep '^[MA]' | awk '{print $2}' | xargs -I {} cp --parents {} "$1"
}

# git
alias gci='git commit'
alias gcl='git clone'
alias gfe='git fetch'
alias gdi='git diff'
alias gdit='git difftool'
alias gpu='git pull'
alias gst='git status'
alias gadd='git add'
alias glog='git log --reverse'

# ls
alias l='ls -h --color=auto'
alias ls='ls -h --color=auto'
alias ll='ls -lsh'
alias lls='ls -lshrt'
alias lla='ls -lshA --color=auto'
alias llas='ls -lshrtA --color=auto'
alias llsa='ls -lshrtA --color=auto'

# misc
alias ec='echo'
alias scrn='screen -R'
alias tmx='tmux attach || tmux new'
alias tma='tmux attach'
alias bell='echo -ne "\007"'
alias hist='history 1'
alias csc='find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \
    | sed "s/.*/\"&\"/g" > csc.files ; cscope -R -b -i csc.files ; rm csc.files'
alias ag="ag --color-line-number=';33' -S"
alias a='ag'
alias psg='ps aux | grep -i'
alias awkp2="awk '{print \$2}'"
alias mktags='ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .'
alias info='info --vi-keys'
alias remake='make clean && make -j'
alias d='dirs -v'
alias h='head'
alias t='tail'
alias rename='export NOAUTONAME=1; tmux rename-window'

#[[[1 Global aliases
alias -g LL='ls --color=auto -lsh'
alias -g LLS='ls --color=auto -lshrtA'
alias -g GG='grep --color=auto'
alias -g GI='grep --color=auto -i'
alias -g FFR='**/*(D.)'
alias -g FF='*(D.)'
alias -g TEST='&& echo "yes" || echo "no"'
alias -g AG="ag --color-line-number=';33' -S"

#[[[1 Suffix aliases
_vim_or_cd() { [[ -d "$1" ]] && cd "$1" || vim "$1" }
alias -s vim=_vim_or_cd
alias -s h=vim
alias -s hpp=vim
alias -s c=vim
alias -s cpp=vim
alias -s m=vim

#[[[1 Key bindings
vibindkey() {
    bindkey -M viins "$@"
    bindkey -M vicmd "$@"
}
compdef _bindkey vibindkey
bindkey -v
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey   '^?'    backward-delete-char
bindkey   '^[[3~' delete-char
vibindkey '^[[A'  up-line-or-beginning-search
bindkey   '^P'    up-line-or-beginning-search
vibindkey '^[[B'  down-line-or-beginning-search
bindkey   '^N'    down-line-or-beginning-search
vibindkey '^[OA'  up-line-or-beginning-search
vibindkey '^[OB'  down-line-or-beginning-search
bindkey -M vicmd 'gg' beginning-of-buffer-or-history
bindkey -M vicmd 'gu' vi-oper-swap-case
bindkey -M vicmd 'gcc' vi-pound-insert
bindkey -M vicmd 'Y' vi-yank-eol
bindkey -M vicmd 'yy' vi-yank-whole-line
bindkey '^R' history-incremental-search-backward
bindkey 'ò' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey -M isearch '^R' history-incremental-search-backward
bindkey -M isearch '^S' history-incremental-search-forward
bindkey -M isearch '^K' history-incremental-search-backward
bindkey -M isearch '^J' history-incremental-search-forward
bindkey -M isearch '^E' accept-search
bindkey -M isearch '^M' accept-search
bindkey -M isearch '^[' accept-search
# Ctrl + arrow keys
vibindkey '^[[1;5A' up-line-or-beginning-search
vibindkey '^[[1;5B' down-line-or-beginning-search
vibindkey '^[[1;5C' forward-word
vibindkey '^[[1;5D' backward-word
# Focus events
vibindkey '^[[I' redisplay
vibindkey '^[[O' redisplay

_vi-last-line() {
    zle end-of-buffer-or-history
    zle vi-first-non-blank
}
zle -N _vi-last-line; bindkey -M vicmd 'G' _vi-last-line

self-insert-no-autoremove() { LBUFFER="$LBUFFER$KEYS" }
zle -N self-insert-no-autoremove; bindkey '|' self-insert-no-autoremove

#[[[1 Functions
b2h() {
    awk 'function human(x) { s=" kMGTEPYZ"; while (x>=1000 && length(s)>1) \
        {x/=1024; s=substr(s,2)} return int(x+0.5) substr(s,1,1) }{ \
            gsub(/^[0-9]+/, human($1)); print}'
}

sort -h >& /dev/null <<< "test"
if [ $? -eq 0 ]; then
    bigdirs() {
        du -h . | sort -h | tail -n ${1:-$(( $LINES - 6 ))}
    }
    bigfiles() {
        find . -type f -exec du -h {} + | sort -h \
            | tail -n ${1:-$(( $LINES - 6 ))}
    }
else
    bigdirs() {
        du --block-size=1 . | sort -n | tail -n ${1:-$(( $LINES - 6 ))} | b2h
    }
    bigfiles() {
        find . -type f -exec du -b {} + | sort -n \
            | tail -n ${1:-$(( $LINES - 6 ))} | b2h
    }
fi

_cygyank() {
    CUTBUFFER=$(cat /dev/clipboard | sed 's/\x0//g')
    zle yank
}
zle -N _cygyank
_cyg-vi-yank() {
    zle vi-yank
    echo $CUTBUFFER | tr -d '\n' > /dev/clipboard
}
zle -N _cyg-vi-yank
_cyg-vi-yank-eol() {
    zle vi-yank-eol
    echo $CUTBUFFER | tr -d '\n' > /dev/clipboard
}
zle -N _cyg-vi-yank-eol
_cyg-list-expand-or-copy-cwd() {
    if [[ $BUFFER =~ \\* ]]; then
        zle list-expand
    else
        tr -d '\n' <<< $PWD > /dev/clipboard
    fi
}
zle -N _cyg-list-expand-or-copy-cwd

_xclipyank() {
    CUTBUFFER=$(xclip -o -sel c | sed 's/\x0//g')
    if [[ -z $CUTBUFFER ]]; then
        CUTBUFFER=$(xclip -o -sel b | sed 's/\x0//g')
    fi
    zle yank
}
zle -N _xclipyank
_xclip-vi-yank() {
    zle vi-yank
    echo $CUTBUFFER | tr -d '\n' | xclip -i -sel p -f | xclip -i -sel c
}
zle -N _xclip-vi-yank
_xclip-vi-yank-eol() {
    zle vi-yank-eol
    echo $CUTBUFFER | tr -d '\n' | xclip -i -sel p -f | xclip -i -sel c
}
zle -N _xclip-vi-yank-eol
_xclip-list-expand-or-copy-cwd() {
    if [[ $BUFFER =~ \\* ]]; then
        zle list-expand
    else
        tr -d '\n' <<< $PWD | xclip -i -sel p -f | xclip -i -sel c
    fi
}
zle -N _xclip-list-expand-or-copy-cwd

if type xclip >& /dev/null ; then
    vibindkey '^V' _xclipyank
    bindkey -M vicmd 'y' _xclip-vi-yank
    bindkey -M vicmd 'Y' _xclip-vi-yank-eol
    vibindkey '^G' _xclip-list-expand-or-copy-cwd
else
    vibindkey '^V' _cygyank
    bindkey -M vicmd 'y' _cyg-vi-yank
    bindkey -M vicmd 'Y' _cyg-vi-yank-eol
    vibindkey '^G' _cyg-list-expand-or-copy-cwd
fi

path() {
    echo $(readlink -f "$1") | tr -d '\n' | xclip -i -sel p -f | xclip -i -sel c
}

_escalate-kill() {
    r="^kill"
    if [[ ! $BUFFER =~ $r ]] && [[ $history[$((HISTCMD-1))] =~ $r ]]; then
        BUFFER=$history[$((HISTCMD-1))]
    elif [[ ! $BUFFER =~ $r ]]; then
        return
    fi
    if [[ $BUFFER =~ $r" -2" ]]; then
        BUFFER=${BUFFER/-2/-15}
    elif [[ $BUFFER =~ $r" -15" ]]; then
        BUFFER=${BUFFER/-15/-9}
    elif [[ $BUFFER =~ $r ]] && [[ ! $BUFFER =~ $r" -[0-9]" ]]; then
        BUFFER=${BUFFER/kill/kill -15}
    fi
    CURSOR=$#BUFFER
}
zle -N _escalate-kill

_escalate_whence() {
    if [[ ! $BUFFER =~ "^wh" ]] && [[ $history[$((HISTCMD-1))] =~ "^wh" ]]; then
        BUFFER=$history[$((HISTCMD-1))]
    elif [[ ! $BUFFER =~ "^wh" ]]; then
        return
    fi
    if [[ $BUFFER =~ "^wh [^- ]" ]]; then
        BUFFER=${BUFFER/wh /wh -a }
    elif [[ $BUFFER =~ "^wh -a" ]]; then
        BUFFER=${BUFFER/wh -a/wh -f}
    elif [[ $BUFFER =~ "^wh -f" ]]; then
        BUFFER=${BUFFER/wh -f /which }
    elif [[ $BUFFER =~ "^which" ]] && [[ ! $BUFFER =~ "^which -a" ]]; then
        BUFFER=${BUFFER/which /which -a }
    fi
    CURSOR=$#BUFFER
}
zle -N _escalate_whence

_escalate() {
    r="^kill"
    if [[ $BUFFER =~ "^wh" ]]; then
        _escalate_whence
    elif [[ $BUFFER =~ $r ]]; then
        _escalate-kill
    elif [[ $history[$((HISTCMD-1))] =~ "^wh" ]]; then
        _escalate_whence
    elif [[ $history[$((HISTCMD-1))] =~ $r ]]; then
        _escalate-kill
    fi
}
zle -N _escalate; vibindkey '^K' _escalate

_backward-delete-WORD () {
    local WORDCHARS=${WORDCHARS}"\"\`'\@"
    zle backward-delete-word
}
zle -N _backward-delete-WORD; vibindkey '÷' _backward-delete-WORD

_backward-delete-to-slash () {
  local WORDCHARS=${WORDCHARS//\//}
  zle backward-delete-word
}
zle -N _backward-delete-to-slash; vibindkey '^^' _backward-delete-to-slash

md() { mkdir -p "$@" && cd "$@" }

rationalise-dot() { [[ $LBUFFER == *.. ]] && LBUFFER+=/.. || LBUFFER+=. }
zle -N rationalise-dot; bindkey . rationalise-dot
bindkey -M isearch . self-insert

_time-command() {
    BUFFER="time ( "$BUFFER" )"
    CURSOR=$(( $CURSOR + 7 ))
}
zle -N _time-command; vibindkey '^T' _time-command

_vim-args() {
    BUFFER="vim \$( "$BUFFER" )"
    CURSOR=$(( $CURSOR + 7 ))
}
zle -N _vim-args; vibindkey '^E' _vim-args

_use-as-args() {
    BUFFER=" \$( "$BUFFER" )"
    CURSOR=0
}
zle -N _use-as-args; bindkey '^A' _use-as-args

_fg-job() {
    if [[ -n $(jobs) ]]; then
        _set-block-cursor
        _disable-focus
        fg
        zle reset-prompt
        _tmux-name-auto
    fi
}
zle -N _fg-job; vibindkey '^Z' _fg-job

autoload -Uz add-zsh-hook
# Ring bell after long commands finish
if [[ -o interactive ]] && zmodload zsh/datetime; then
    zbell_duration=5
    zbell_ignore=(vi vim vims view vimdiff gvim gvims gview gvimdiff man \
        more less e ez tmux tmx matlab vimr)
    zbell_timestamp=$EPOCHSECONDS
    zbell_begin() {
        zbell_timestamp=$EPOCHSECONDS
        zbell_lastcmd=$1
    }
    zbell_end() {
        ran_long=$(( $EPOCHSECONDS - $zbell_timestamp >= $zbell_duration ))
        has_ignored_cmd=0
        for cmd in ${(s:;:)zbell_lastcmd//|/;}; do
            words=(${(z)cmd})
            util=${words[1]}
            if (( ${zbell_ignore[(i)$util]} <= ${#zbell_ignore} )); then
                has_ignored_cmd=1
                break
            fi
        done
        if (( ! $has_ignored_cmd )) && (( ran_long )); then
            print -n "\a"
        fi
    }
    add-zsh-hook preexec zbell_begin
    add-zsh-hook precmd zbell_end
fi

_tmux-name-win() {
    if [[ -n $TMUX ]] && [[ -z $(jobs) ]] && [[ -z $NOAUTONAME ]]; then
        if [[ $(tmux display-message -p -t $TMUX_PANE '#{window_panes}') -eq 1 ]]; then
            name=$(print -n "/${${PWD/#$HOME/\~}##*/}/")
            if [[ ${#name} -gt 23 ]]; then; name=${name[1,9]}...${name[-9,-1]}; fi
            tmux rename-window -t $TMUX_PANE $name
        fi
    fi
}
_tmux-name-auto() {
    if [[ -n $TMUX ]] && [[ -z $NOAUTONAME ]]; then
        if [[ $(tmux display-message -p -t $TMUX_PANE '#{window_panes}') -eq 1 ]]; then
            tmux set-window -q -t $TMUX_PANE automatic-rename on
        fi
    fi
}
add-zsh-hook precmd _tmux-name-win
add-zsh-hook preexec _tmux-name-auto

_reset-saved-buffer() { export BUFSAVE=; }
add-zsh-hook precmd _reset-saved-buffer
_list-choices-or-logout() {
    [[ -z $BUFFER ]] && { [[ -o login ]] && logout || exit; }
    if [[ -n $BUFSAVE ]]; then
        if [[ $BUFSAVE == "$BUFFER" ]]; then
            zle vi-kill-line
            [[ -o login ]] && logout || exit
        fi
    fi
    export BUFSAVE=$BUFFER
    zle list-choices
}
zle -N _list-choices-or-logout; vibindkey '^D' _list-choices-or-logout

tmux-next() { tmux next >& /dev/null }
zle -N tmux-next; vibindkey '^[[27;5;9~' tmux-next
tmux-prev() { tmux prev >& /dev/null }
zle -N tmux-prev; vibindkey '^[[27;6;9~' tmux-prev

vim-blacklist-add() {
    vimblacklist=($vimblacklist "$1")
    export VIMBLACKLIST=${(j:,:)vimblacklist}
}

vim-blacklist-remove() {
    vimblacklist[${vimblacklist[(i)$1]}]=()
    export VIMBLACKLIST=${(j:,:)vimblacklist}
}

zmodload -i zsh/parameter
insert-last-command-output() { LBUFFER+="$(eval $history[$((HISTCMD-1))])" }
zle -N insert-last-command-output
bindkey '^X' insert-last-command-output

# https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/plugins/extract/extract.plugin.zsh
[[ -e ~/.zsh/extract.plugin.zsh ]] && source ~/.zsh/extract.plugin.zsh

make() {
    if [[ $# == 0 ]]; then
        command make -j
    else
        command make "$@"
    fi
}

#[[[1 Focus/cursor handling
_cursor_block="\033[1 q"
_cursor_bar="\033[5 q"
_focus_enable="\033[?1004h"
_focus_disable="\033[?1004l"

_set-block-cursor() { [[ -z $MOBILE ]] && echo -ne $_cursor_block }
_set-bar-cursor()   { [[ -z $MOBILE ]] && echo -ne $_cursor_bar }
_disable-focus()    { [[ -z $MOBILE ]] && echo -ne $_focus_disable }
_enable-focus()     {
    if [[ -z $MOBILE ]]; then
        stty -echoctl # Prevents '^[[I' showing up on screen
        echo -ne $_focus_enable
        stty echoctl
    fi
}

vibindkey '^[[O' redisplay
vibindkey '^[[I' zle-keymap-select
bindkey -M main '^[[O' redisplay
bindkey -M main '^[[I' zle-keymap-select
add-zsh-hook precmd _enable-focus
add-zsh-hook preexec _disable-focus
add-zsh-hook precmd _set-bar-cursor
add-zsh-hook preexec _set-block-cursor
_set-bar-cursor

#[[[1 Environment variables
export VIMPAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    vim -R -c 'set ft=man nomod noma nolist' --servername VIM \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""
export PAGER=
alias man='PAGER=$VIMPAGER man'
export DIRSTACKSIZE=10
export KEYTIMEOUT=5
vimblacklist=(syntastic vimshell processing over flake8 tmux-complete svndiff \
    signify vcscommand fugitive)
export VIMBLACKLIST=${(j:,:)vimblacklist}
[[ -e ~/.dircolors ]] && eval $(dircolors -b ~/.dircolors)
[[ -d ~/vimconfig/misc ]] && fpath=(~/vimconfig/misc $fpath)
export FPATH
export EDITOR=vim

#[[[1 Completion Stuff
[[ -z "$modules[zsh/complist]" ]] && zmodload zsh/complist

# Use shift-tab to select previous completion
vibindkey '^[[Z' reverse-menu-complete
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
zstyle ':completion:*' matcher-list '' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

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
setopt COMPLETE_IN_WORD

# Separate man page sections. Neat.
zstyle ':completion:*:manuals' separate-sections true

# complete with a menu for xwindow ids
zstyle ':completion:*:windows' menu on=0
zstyle ':completion:*:expand:*' tag-order all-expansions

# more errors allowed for large words and fewer for small words
zstyle ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) )'

# Errors format
zstyle ':completion:*:corrections' format '%B%d (errors %e)%b'

# Don't complete stuff already on the line
zstyle ':completion::*:(rm|vi):*' ignore-line true

# Don't complete directory we are already in (../here)
zstyle ':completion:*' ignore-parents parent pwd

zstyle ':completion::approximate*:*' prefix-needed false

# Faster path completion
zstyle ':completion:*' accept-exact '*(N)'

_force_rehash() {
    (( CURRENT == 1 )) && rehash
    return 1 # Because we didn't really complete anything
}

# Display files with colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Process ID completion
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors \
    "=(#b) #([0-9]#) #([^ ]#) #([^ ]#)*=33=31=32=34"
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,tty,cputime,command'

# Don't suggest _functions
zstyle ':completion:*:functions' ignored-patterns '_*'

# Fast completion for files only
zle -C complete-files menu-complete _generic
zstyle ':completion:complete-files:*' completer _files
zstyle ':completion:complete-files:*' menu 'select=0'
bindkey '^@' complete-files

#[[[1 Prompt stuff
export _PSVARLEN=0
local userhost=$(print -P "%n@%m")
export _USERHOSTLEN=${#userhost}
_short-pwd() {
    maxlen=$(($COLUMNS - 22 - $_USERHOSTLEN - $_PSVARLEN))
    if [[ ${#PWD} -gt $maxlen ]]; then
        newpwd=$(print -P "%~")
        parts=(${(s:/:)newpwd})
        trunc=0
        while [[ $trunc -lt $((${#parts} - 1)) ]]; do
            ((trunc++))
            parts[$trunc]=${parts[$trunc][1]}
            newpwd=${(j:/:)parts}
            if [[ ${#newpwd} -lt $maxlen ]]; then
                break
            fi
        done
        if [[ $newpwd[1] != '~' ]]; then
            newpwd=/$newpwd
        fi
        echo $newpwd
    else
        echo $PWD
    fi
}
# Show vi input mode
autoload -U colors && colors
setopt PROMPT_SUBST
_vim_ins_mode="%{$fg[black]%}%{$bg[cyan]%}i%{$reset_color%}"
_vim_cmd_mode="%{$fg[black]%}%{$bg[yellow]%}n%{$reset_color%}"
_vim_mode=$_vim_ins_mode
zle-keymap-select() {
    _vim_mode="${${KEYMAP/vicmd/${_vim_cmd_mode}}/(main|viins)/${_vim_ins_mode}}"
    if [[ $KEYMAP =~ "viins|main" ]]; then
        _set-bar-cursor
    else
        _set-block-cursor
    fi
    zle reset-prompt
}
zle -N zle-keymap-select
zle-line-finish() { _vim_mode=$_vim_ins_mode }
zle -N zle-line-finish
TRAPINT() {
    _vim_mode=$_vim_ins_mode
    return $(( 128 + $1 ))
}
# Ctrl-F opens Vim as command editor
autoload edit-command-line
zle -N edit-command-line
vibindkey '^F' edit-command-line
_lineup=$'\e[1A'
_linedown=$'\e[1B'
PROMPT="
%{$fg[blue]%}%n%{$reset_color%}@%{$fg[yellow]%}%m %{$fg[cyan]%}\$(_short-pwd)%{$reset_color%}
[zsh %{$fg[cyan]%}%1~%{$reset_color%} %{$fg[red]%}%1(j,+ ,)%{$reset_color%}\${_vim_mode}]%# "
RPROMPT="%{${_lineup}%}%{$fg_bold[green]%}%T%{$reset_color%}"
RPROMPT=${RPROMPT}" !%{$fg[red]%}%!%{$reset_color%}%{${_linedown}%}"
SPROMPT="Correct $fg[red]%R$reset_color to $fg[green]%r?$reset_color (Yes, No, Abort, Edit) "
# Update prompt after TMOUT seconds and after hitting enter
TMOUT=10
TRAPALRM() { [[ -z $BUFFER ]] && zle reset-prompt }
_accept-line() { zle reset-prompt; zle accept-line }
zle -N _accept-line; vibindkey '^M' _accept-line

# vared setup
zle -N _set-bar-cursor
VAREDPROMPT='
[$fg[red]vared $fg[yellow]VAR ${_vim_mode}]%# '
vared() {
    builtin vared -i _set-bar-cursor -p ${VAREDPROMPT/VAR/${argv[-1]}} ${argv[-1]}
}

#[[[1 Cygwin settings
if [[ $OSTYPE == 'cygwin' ]]; then
    export GROFF_NO_SGR=1
    alias man='export MANWIDTH=$(( $COLUMNS - 6 )); man'

    zstyle ':completion:*:kill:*' command 'ps -u $USER -s'
    zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#) #([^ ]#)*=33=31=34"

    alias tmx='tmux attach 2> /dev/null || ( rm -r /tmp/tmux* >& /dev/null ; tmux new )'
    alias open='cygstart'
    alias cyg='cygpath'

    export DISPLAY=localhost:0.0

    # Open file browser with F4
    _cygstart_dir() {
        cygstart $PWD
    }
    zle -N _cygstart_dir; vibindkey '^[OS' _cygstart_dir

    # Synchronize X11 PRIMARY and CLIPBOARD selections
    if [[ ! $(ps) =~ 'autocutsel' ]] && (( $+commands[autocutsel] )); then
        autocutsel -selection PRIMARY -fork
        autocutsel -selection CLIPBOARD -fork
    fi
fi

#[[[1 Machine-specific settings
[[ -e ~/.zshrclocal ]] && source ~/.zshrclocal

# vim: set fdm=marker fdl=1 et sw=4 fmr=[[[,]]]:
