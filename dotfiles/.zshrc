#{{{1 Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt auto_cd beep extended_glob no_match notify no_beep share_history
setopt inc_append_history extended_history interactive_comments
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
alias f='find . -type f'
alias fin='find . -type f -iname'
alias fn='find . -type f -name'
alias fd='find . -type d'
alias fmd='find . -maxdepth'
alias loc='locate'
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
alias vimr='vim -S =(cat ~/periodic_session.vis)'
alias gvims='gvim -S ~/session.vis'
alias h='head'
alias t='tail'
alias svnadd="svn st | \grep '^?' | awk '{print \$2}' | s | xargs svn add"
alias svnrevert="svn st | \grep '^M' | awk '{print \$2}' | s | xargs svn revert"
alias svnrm="svn st | \grep '^?' | awk '{print \$2}' | s | xargs rm -r"
alias svnst="svn st | g -v '\.git'"
alias svndi="svnst | awk '{print \$2}' | s | xargs svn di"
alias svnexport="svn st | \grep '^[MA]' | awk '{print \$2}' | xargs -I {} cp --parents {}"
alias ec='echo'
alias scrn='screen -R'
alias tmx='tmux attach || tmux new'
alias bell='echo -ne "\007"'
alias ls='ls -h --color=auto'
alias ll='ls -lsh'
alias lls='ls -lshrt'
alias lla='ls -lshA --color=auto --sort=none'
alias llas='ls -lshrtA --color=auto --sort=none'
alias llsa='ls -lshrtA --color=auto --sort=none'
alias hist='history 1'
alias csc='find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \
    | sed "s/.*/\"&\"/g" > csc.files ; cscope -R -b -i csc.files ; rm csc.files'
alias ag="ag --color-line-number=';33' -S"
alias psg='ps aux | grep -i'
alias a='ag'
alias awkp2="awk '{print \$2}'"
alias mktags='ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .'
alias so='source'

#{{{1 Global aliases
alias -g LL='ls -lshrtA'
alias -g GG='grep --color=auto'
alias -g GI='grep --color=auto -i'
alias -g FFR='**/*(D.)'
alias -g FF='*(D.)'
alias -g TEST='&& echo "yes" || echo "no"'

#{{{1 Suffix aliases
vim_or_cd() { [[ -d "$1" ]] && cd "$1" || vim "$1" }
alias -s vim=vim_or_cd
alias -s h=vim
alias -s hpp=vim
alias -s c=vim
alias -s cpp=vim
alias -s m=vim

#{{{1 Key bindings
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
bindkey '^S' history-incremental-search-forward
bindkey -M isearch '^E' accept-search
bindkey -M isearch '^M' accept-search
# Ctrl + arrow keys
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

vi-last-line() {
    zle end-of-buffer-or-history
    zle vi-first-non-blank
}
zle -N vi-last-line
bindkey -M vicmd 'G' vi-last-line

self-insert-no-autoremove() { LBUFFER="$LBUFFER$KEYS" }
zle -N self-insert-no-autoremove
bindkey '|' self-insert-no-autoremove

#{{{1 Functions
b2h() {
    awk 'function human(x) { s=" kMGTEPYZ"; while (x>=1000 && length(s)>1) \
        {x/=1024; s=substr(s,2)} return int(x+0.5) substr(s,1,1) }{ \
            gsub(/^[0-9]+/, human($1)); print}'
}

bigdirs() {
    find . -type d -not -name "." -exec du -b {} + | sort -n \
        | tail -n $(( $(tput lines) - 4 )) | b2h
}

bigfiles() {
    find . -type f -exec du -b {} + | sort -n \
        | tail -n $(( $(tput lines) - 4 )) | b2h
}

cygyank() {
    CUTBUFFER=$(cat /dev/clipboard | sed 's/\x0//g')
    zle yank
}
zle -N cygyank
cyg-vi-yank() {
    zle vi-yank
    echo $CUTBUFFER | tr -d '\n' > /dev/clipboard
}
zle -N cyg-vi-yank
cyg-vi-yank-eol() {
    zle vi-yank-eol
    echo $CUTBUFFER | tr -d '\n' > /dev/clipboard
}
zle -N cyg-vi-yank-eol

xclipyank() {
    CUTBUFFER=$(xclip -o | sed 's/\x0//g')
    if [ -z $CUTBUFFER ]; then
        CUTBUFFER=$(xclip -o -sel b | sed 's/\x0//g')
    fi
    zle yank
}
zle -N xclipyank
xclip-vi-yank() {
    zle vi-yank
    echo $CUTBUFFER | tr -d '\n' | xclip -i -sel p -f | xclip -i -sel c
}
zle -N xclip-vi-yank
xclip-vi-yank-eol() {
    zle vi-yank-eol
    echo $CUTBUFFER | tr -d '\n' | xclip -i -sel p -f | xclip -i -sel c
}
zle -N xclip-vi-yank-eol

if type xclip >& /dev/null ; then
    vibindkey '^V' xclipyank
    bindkey -M vicmd 'y' xclip-vi-yank
    bindkey -M vicmd 'Y' xclip-vi-yank-eol
else
    vibindkey '^V' cygyank
    bindkey -M vicmd 'y' cyg-vi-yank
    bindkey -M vicmd 'Y' cyg-vi-yank-eol
fi

md() { mkdir -p "$@" && cd "$@" }

rationalise-dot() { [[ $LBUFFER == *.. ]] && LBUFFER+=/.. || LBUFFER+=. }
zle -N rationalise-dot
bindkey . rationalise-dot
bindkey -M isearch . self-insert

force-logout() {
    zle vi-kill-line
    [[ -o login ]] && logout || exit
}
zle -N force-logout
vibindkey '^D' force-logout

fg-job() {
    fg; zle reset-prompt; zle redisplay
    tmux set-window -q automatic-rename on
}
zle -N fg-job; vibindkey '^Z' fg-job;

autoload -Uz add-zsh-hook
# Ring bell after long commands finish
if [[ -o interactive ]] && zmodload zsh/datetime; then
    zbell_duration=5
    zbell_ignore=(vi vim vims view vimdiff gvim gvims gview gvimdiff man \
        more less e ez tmux tmx)
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

tmux-name-win() {
    if [[ -n $TMUX ]] && [[ -z $(jobs) ]]; then
        print -n "\033k/${${PWD/#$HOME/\~}##*/}/\033\\"
    fi
}
tmux-name-auto() {
    [[ -n $TMUX ]] && tmux set-window -q automatic-rename on
}
add-zsh-hook precmd tmux-name-win
add-zsh-hook preexec tmux-name-auto

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

#{{{1 Environment variables
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    vim -R -c 'set ft=man nomod noma nolist' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""
export DIRSTACKSIZE=10
export KEYTIMEOUT=5
vimblacklist=(syntastic vimshell processing over flake8 easymotion tmux-complete)
export VIMBLACKLIST=${(j:,:)vimblacklist}
if [ -e ~/.dircolors ]; then
    eval $(dircolors -b ~/.dircolors)
fi

#{{{1 Completion Stuff
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

#{{{1 Prompt stuff
# Show vi input mode
autoload -U colors && colors
setopt PROMPT_SUBST
vim_ins_mode="%{$fg[black]%}%{$bg[cyan]%}i%{$reset_color%}"
vim_cmd_mode="%{$fg[black]%}%{$bg[yellow]%}n%{$reset_color%}"
vim_mode=$vim_ins_mode

zle-keymap-select() {
    vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
    zle reset-prompt
}
zle -N zle-keymap-select

zle-line-finish() { vim_mode=$vim_ins_mode }
zle -N zle-line-finish

TRAPINT() {
    vim_mode=$vim_ins_mode
    return $(( 128 + $1 ))
}

# Ctrl-F opens Vim as command editor
autoload edit-command-line
zle -N edit-command-line
vibindkey '^F' edit-command-line

_lineup=$'\e[1A'
_linedown=$'\e[1B'

PROMPT="
%{$fg[blue]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%} %{$fg[cyan]%}%d%{$reset_color%}
[zsh %{$fg[cyan]%}%1~%{$reset_color%} %{$fg[red]%}%1(j,+ ,)%{$reset_color%}\${vim_mode}]%# "
RPROMPT="%{${_lineup}%}%{$fg_bold[green]%}%T%{$reset_color%}"
RPROMPT=${RPROMPT}" !%{$fg[red]%}%!%{$reset_color%}%{${_linedown}%}"

#{{{1 Machine-specific settings

source ~/.zshrclocal

# vim: set fdm=marker fdl=1 et sw=4:
