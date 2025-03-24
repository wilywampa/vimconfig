#[[[1 Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=99999
SAVEHIST=50000
setopt autocd beep extended_glob no_match notify no_beep share_history
setopt inc_append_history extended_history interactive_comments
setopt hist_expire_dups_first hist_ignore_dups hist_ignore_space
# End of lines configured by zsh-newuser-install

#[[[1 Lines added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit -C
# End of lines added by compinstall

#[[[1 Basic settings
# Automatically use directory stack
setopt auto_pushd pushd_minus pushd_silent pushd_to_home pushd_ignore_dups

# Be able to use ^S and ^Q and rebind ^W
stty -ixon -ixoff
stty werase undef

# Try to correct misspelled commands
setopt correct

#[[[1 Aliases
# zsh
alias sz='source ~/.zshrc'
alias EXIT='exit'
alias s="sed 's/.*/\"&\"/'"
alias so='source'
alias wh='whence'
alias reset='reset; source ~/.zshrc'
alias com='command'
alias killbg='kill ${${(v)jobstates#*:*:}%=*}'
alias whence='whence -f'

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
alias ffn='find . -type f -iname'
alias ffa='find . -type f | ag'
alias fn='find . -iname'
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

# vim
if (( $+commands[vim] )) && command vim --version |
    command grep '+clientserver' >& /dev/null; then
    alias vim='vim --servername $VIMSERVER --cmd "set history=5000"'
else
    alias vim='vim --cmd "set history=5000"'
fi
alias vit='vim --remote-tab'
alias view='vim -R'
alias e='vim'
alias vims='vim -S ~/session.vis'
alias vimr='vim -S =(<~/periodic_session.vis)'
alias gvims='gvim -S ~/session.vis'
alias ez='vim ${~${:-~/.zshrc}:A}'
alias vno='vim $VIMOPTIONS'

# svn
alias svnadd="svn st | grep '^?' | awk '{print \$2}' | s | xargs svn add"
alias svnrevert="svn st | grep '^M' | awk '{print \$2}' | s | xargs svn revert"
alias svnrm="svn st | grep '^?' | awk '{print \$2}' | s | xargs rm -r"
alias svnst="svn st | g -v '\.git'"
alias svndi="svnst | awk '{print \$2}' | s | xargs svn di"
alias slog="svn log -r 1:HEAD"
alias srm="svn rm"
local cmds=''"'"'+/^Index:'"'"' "+1" =(svn di --diff-cmd diff)'
alias svndiff='vim -c "set buftype=nowrite" '$cmds
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
alias gdic='git diff --cached'
alias gdt='git difftool'
alias gpu='git pull'
alias gco='git checkout'
alias gst='git status'
alias gstu='git status -uno'
alias gad='git add'
alias glog='git log'
alias glogv='git log --stat'
alias gls='git ls-files'
alias gg='git grep'
alias grm='git rm'
alias gfom='git fetch origin master'
alias gpom='git pull origin master'
alias gurl='git config --get remote.origin.url'
local cmds=''"'"'+/^diff --git'"'"' "+1" =(git diff --no-ext-diff)'
alias gdiff='vim -c "set buftype=nowrite" '$cmds
local cmds=''"'"'+/^diff --git'"'"' "+1" =(git diff --cached --no-ext-diff)'
alias gdiffc='vim -c "set buftype=nowrite" '$cmds
local cmds=''"'"'+/^diff --git'"'"' "+1" =(git diff --no-ext-diff origin)'
alias gnew='vim -c "set buftype=nowrite" '$cmds
local cmds=''"'"'+/^diff --git'"'"' "+1" =(hg diff --git)'
alias hgdiff='vim -c "set buftype=nowrite" '$cmds

# ls
alias l='ls -h --color=auto'
alias ls='ls -h --color=auto'
alias la='ls -hA --color=auto'
alias ll='ls -lsh --color=auto'
alias lls='ls -lshrt --color=auto'
alias lla='ls -lshA --color=auto'
alias llas='ls -lshrtA --color=auto'
alias llsa='ls -lshrtA --color=auto'
alias lu='ls -1U --color=auto'
alias llu='ls -1lUsh --color=auto'
alias llua='ls -1lUshA --color=auto'
alias llau='ls -1lUshA --color=auto'

# misc
alias ec='echo'
alias scrn='screen -R'
alias tmx='tmux attach || tmux new'
alias tma='tmux attach'
alias bell='echo -ne "\007"'
alias hist='history 1'
alias csc='cscope -b $(ag -g "" --cc --silent $PWD) $(ag -g "" --cpp --silent $PWD)'
alias ag="ag --color-line-number=';33' -S"
alias a='ag'
alias psg='ps aux | grep -i'
alias awkp2="awk '{print \$2}'"
alias mktags='ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q --python-kinds=-i .'
alias info='info --vi-keys'
alias remake='make clean && make'
alias d='dirs -v'
alias h='head'
alias t='tail'
alias rename='export NOAUTONAME=1; tmux rename-window'
alias pdb="vim -c 'Pyclewn pdb'"
alias pyclewn="vim -c 'Pyclewn'"
alias loc='locate --regex -i'
alias ipy='ipython'
alias pip='noglob pip'
alias hoogle='hoogle --color'
alias ssh='ssh -o EscapeChar=none'

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
insbindkey() {
    bindkey -M viins "$@"
    bindkey -M isearch "$1" self-insert
    bindkey -M command "$1" self-insert
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
bindkey -M isearch '^R' history-incremental-search-backward
bindkey -M isearch '^S' history-incremental-search-forward
bindkey -M isearch '^K' history-incremental-search-backward
bindkey -M isearch '^J' history-incremental-search-forward
bindkey -M isearch '^E' accept-search
bindkey -M isearch '^M' accept-search
bindkey -M isearch '^[' accept-search
bindkey -M isearch '/' accept-search
vibindkey '^T' transpose-words
# Ctrl + arrow keys
vibindkey '^[[1;5A' up-line-or-beginning-search
vibindkey '^[[1;5B' down-line-or-beginning-search
vibindkey '^[[1;5C' forward-word
vibindkey '^[[1;5D' backward-word
# Focus events
vibindkey '^[[I' redisplay
vibindkey '^[[O' redisplay
bindkey -M viins '^J' self-insert
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^B' vi-beginning-of-line
bindkey -M viins '^E' vi-end-of-line
bindkey -M viins '^X^U' undo
bindkey -M viins '^X' undefined-key  # Ensure ^X is not bound to self-insert
bindkey -M viopp -s '_' 't_'
bindkey -M viopp -s '\-' 'T_'

_vi-last-line() {
    zle end-of-buffer-or-history
    zle vi-first-non-blank
}
zle -N _vi-last-line; bindkey -M vicmd 'G' _vi-last-line

self-insert-no-autoremove() { LBUFFER="$LBUFFER$KEYS" }
zle -N self-insert-no-autoremove; bindkey '|' self-insert-no-autoremove

_previous-dir() {
    if [[ $BUFFER =~ '^[0-9]+$' ]]; then
        cd "${${dirstack[$(( $BUFFER )) ]}:-$OLDPWD}"
        BUFFER=
    else
        cd "$OLDPWD"
    fi
    zle reset-prompt
}
zle -N _previous-dir
vibindkey '^^' _previous-dir

# Enable built-in surround plugin and text objects
autoload -Uz is-at-least
if is-at-least 5.0.8; then
    autoload -Uz surround
    autoload -Uz select-bracketed
    autoload -Uz select-quoted
    zle -N delete-surround surround
    zle -N add-surround surround
    zle -N change-surround surround
    zle -N select-bracketed
    zle -N select-quoted
    bindkey -a cs change-surround
    bindkey -a ds delete-surround
    bindkey -a gs add-surround
    for m in visual viopp; do
        for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
            bindkey -M $m $c select-bracketed
        done
        for c in {a,i}{\',\",\`}; do
            bindkey -M $m $c select-quoted
        done
        bindkey -M $m S add-surround
    done
fi

# Load other zsh functions
unalias run-help >& /dev/null
autoload -Uz run-help
autoload -Uz run-help-git
autoload -Uz run-help-svn
bindkey -a '?' run-help
autoload -Uz replace-string
zle -N replace-string
vibindkey '^X^S' replace-string
autoload -Uz send-invisible
zle -N send-invisible
vibindkey '^X ' send-invisible

#[[[1 Abbreviations
typeset -Ag abbrevs
abbrevs=(
'g'     'git'
'gci'   'git commit'
'gcl'   'git clone'
'gfe'   'git fetch'
'gdi'   'git diff'
'gd'    'git diff'
'gdic'  'git diff --cached'
'gdt'   'git difftool'
'gdivp' 'git diff | vimpager'
'gpu'   'git pull'
'gst'   'git status'
'gstu'  'git status -uno'
'gco'   'git checkout'
'ga'    'git add'
'gad'   'git add'
'gadd'  'git add'
'glg'   'git lg'
'glog'  'git log'
'glogd' 'git log --stat'
'gls'   'git ls-files'
'gg'    'git grep'
'grm'   'git rm'
'gpom'  'git pull origin master'
'gurl'  'git config --get remote.origin.url'
'ga.'   'git add .'
'gfo'   'git fetch origin'
'gfu'   'git fetch upstream'
'gdo'   'git diff origin/master'
'gdu'   'git diff upstream/master'
'gsm'   'git submodule'
'com'   'command'
'sdi'   'svn diff'
'sad'   'svn add'
'sadd'  'svn add'
'sco'   'svn checkout'
'sci'   'svn commit'
'sup'   'svn update'
'sst'   'svn status'
'sre'   'svn revert'
'slog'  'svn log -r 1:HEAD'
'srm'   'svn rm'
'surl'  'info=$(svn info); echo ${${info[(fr)URL: *]}[(w)-1]}'
'ec'    'printf "%s\n"'
'so'    'source'
'ez'    'vim ${~${:-~/.zshrc}:A}'
'sz'    'source ~/.zshrc'
'szv'   'source ~/.zshrc; vims'
'wh'    'whence'
'w'     'whence'
'gi'    'grep -i'
'f'     'noglob find .'
'fn'    'noglob find . -iname'
'fa'    'noglob find . | a'
'ff'    'noglob find . -type f'
'ffa'   'noglob find . -type f | a'
'ffn'   'noglob find . -type f -iname'
'fd'    'noglob find . -type d'
'fda'   'noglob find . -type d | a'
'fdn'   'noglob find . -type d -iname'
'fmd'   'noglob find . -maxdepth'
'loc'   'locate --regex -i'
'co'    './configure'
'cop'   './configure --prefix=$HOME/.local'
'.co'   '../configure'
'.cop'  '../configure --prefix=$HOME/.local'
'm'     'make'
'min'   'make install'
'mcl'   'make clean'
'mdcl'  'make distclean'
'rem'   'make clean && make'
'remin' 'make clean && make install'
'xa'    'xargs'
'c'     'copy'
'p'     'path'
'gid'   'gdiff'
'gidc'  'gdiffc'
'svd'   'svndiff'
'hgd'   'hgdiff'
'vc'    'cd $VIMCONFIG'
'vcb'   'cd $VIMCONFIG/vimfiles/bundle'
'v'     'vim'
'e'     'vim'
'vno'   'vim $VIMOPTIONS'
'vp'    'vimpager -f'
'vr'    'vimr'
'vs'    'vims'
'ipy'   'ipython'
'xt'    'xclip -o >& /dev/null || echo -n "not "; echo connected'
'vba'   'vim-blacklist-add'
'vbr'   'vim-blacklist-remove'
'k'     'kill'
'o'     'open'
'pp'    'python *.py(om[1])'
'py'    'python'
'ex'    'export'
'ip'    'python $VIMCONFIG/misc/python/ipython_monitor.py &; ipython console'
'h'     'head'
't'     'tail'
'd'     'du -sh'
'pyc'   'pyclewn'
'cpu'   'cpundo'
'mvu'   'mvundo'
'rmu'   'rmundo'
)

# Post-modifier abbreviations
typeset -Ag pmabbrevs
pmabbrevs=(
'g'     'grep --color=auto'
'grep'  'grep --color=auto'
'egrep' 'grep --color=auto -E'
'fgrep' 'grep --color=auto -F'
'gi'    'grep --color=auto -i'
'ls'    'ls --color=auto -h'
'la'    'ls -hA --color=auto'
'll'    'ls --color=auto -lsh'
'lla'   'ls --color=auto -lshA'
'llsa'  'ls --color=auto -lshrtA'
'lls'   'ls --color=auto -lshrt'
'llas'  'ls --color=auto -lshrtA'
'lu'    'ls -1U --color=auto'
'llu'   'ls -1lUsh --color=auto'
'llua'  'ls -1lUshA --color=auto'
'llau'  'ls -1lUshA --color=auto'
'ag'    'ag -S'
'a'     'ag -S'
)

typeset -Ag globalabbrevs
globalabbrevs=(
'H'    '| head -n'
'T'    '| tail -n'
'VC'   '$VIMCONFIG'
'VCB'  '$VIMCONFIG/vimfiles/bundle'
'AG'   'ag -S'
'/dn'  '/dev/null'
'/DN'  '/dev/null'
'DN'   '/dev/null'
'DR'   '--dry-run'
'@@'   'jacob.niehus@gmail.com'
'NEW'  '*(om[1])'
'NEWD' '*(/om[1])'
'NEWF' '*(.om[1])'
)

magic-abbrev-expand() {
    local left pre shellmods mods prevword lastidx doabbrev=0 dopostmod=0
    local lbuffer_start ins_space=0
    if [[ $KEYMAP == 'vicmd' ]]; then
        LBUFFER=$BUFFER
        RBUFFER=
    fi
    lbuffer_start=$LBUFFER
    [[ $KEYS == $(echo '\t') && $RBUFFER[1] =~ [[:alnum:]_] ]] && ins_space=1
    if [[ $LBUFFER[-1] != " " && $ins_space == 1 || ( ${LBUFFER[-1]} != " " &&  ! $RBUFFER[1] =~ [[:alnum:]_] ) ]]; then
        # Get index of last space, pipe, semicolon, or $( before last word
        lastidx=${LBUFFER[(I) ]}
        (( ${LBUFFER[(I)\|]} > $lastidx )) && lastidx=${LBUFFER[(I)\|]}
        (( ${LBUFFER[(I);]} > $lastidx )) && lastidx=${LBUFFER[(I);]}
        if [[ $LBUFFER == *\ $\(* ]]; then
            (( $((${LBUFFER[(I)$\(]}+1)) > $lastidx )) && lastidx=$((${LBUFFER[(I)$\(]}+1))
        fi
        pre=${LBUFFER[$lastidx+1,-1]}
        left=${LBUFFER[1,$lastidx]}
        prevword=${left[(w)-1]}
        shellmods=('time' 'noglob' 'nocorrect' 'exec' '&&' '||' 'command')
        if (( ${shellmods[(i)$prevword]} <= ${#shellmods} )); then
            doabbrev=1
        fi
        mods=('xargs' 'unbuffer' 'nohup' 'sudo')
        [[ ${LBUFFER[(w)1]} == "zargs" ]] && mods+=('--' '..')
        [[ ${LBUFFER[(w)-3]} == "xargs" ]] && mods+=('-0')
        # Previous word is a modifier
        if (( ${mods[(i)$prevword]} <= ${#mods} )); then
            doabbrev=1; dopostmod=1
        fi
        # Only one word in buffer
        (( ${(w)#LBUFFER} < 2 )) && doabbrev=1
        # Preceded by a pipe, semicolon, or $(
        [[ ${prevword[-1]} == '|' ]] && doabbrev=1
        [[ ${prevword[-1]} == ';' ]] && doabbrev=1
        [[ ${prevword[-2,-1]} == '$(' ]] && doabbrev=1
        if [[ ${prevword[-2,-1]} == '$(' ]] && [[ $pre =~ ^wh?$ ]]; then
            LBUFFER=$left'whence -p'
        elif [[ ${prevword[-1]} == '|' ]] && [[ $pre == 'g' ]]; then
            LBUFFER=$left'grep -i'
        elif [[ $dopostmod == 1 ]] && [[ ${pmabbrevs[(i)$pre]} == $pre ]]; then
            LBUFFER=$left${pmabbrevs[$pre]:-$pre}
        elif [[ $doabbrev == 1 ]] && [[ ${abbrevs[(i)$pre]} == $pre ]]; then
            LBUFFER=$left${abbrevs[$pre]:-$pre}
        else
            LBUFFER=$left${globalabbrevs[$pre]:-$pre}
        fi
    fi
    if [[ $KEYS == " " ]] && (is-at-least 5.1.1 || [[ $RBUFFER == "" ]]); then
        zle magic-space # Add space or do history expansion
    else
        [[ ! $KEYS =~ "[$(echo '\015')$(echo '\t')]" ]] && LBUFFER=$LBUFFER$KEYS
    fi
    [[ $ins_space == 1 ]] && LBUFFER=${LBUFFER}' '
    [[ $LBUFFER == $lbuffer_start ]] && return 1 || {zle split-undo; return 0}
}

no-magic-abbrev-expand() { LBUFFER+=' ' }

magic-abbrev-expand-or-complete-word() {
    magic-abbrev-expand || zle complete-word
}
zle -N magic-abbrev-expand-or-complete-word
vibindkey '^I' magic-abbrev-expand-or-complete-word

accept-line_() { magic-abbrev-expand; zle reset-prompt; zle accept-line }
zle -N accept-line_; vibindkey '^M' accept-line_
zle -N magic-abbrev-expand
zle -N no-magic-abbrev-expand
insbindkey " " magic-abbrev-expand
insbindkey "/" magic-abbrev-expand
insbindkey "|" magic-abbrev-expand
insbindkey ";" magic-abbrev-expand
bindkey -M viins "^O" no-magic-abbrev-expand

# Define split-undo for old versions of zsh
(( $+widgets[split-undo] )) || {split-undo() {}; zle -N split-undo}

#[[[1 Functions
b2h() {
    awk 'function human(x) { s=" kMGTEPYZ"; while (x>=1000 && length(s)>1) \
        {x/=1024; s=substr(s,2)} return int(x+0.5) substr(s,1,1) }{ \
            gsub(/^[0-9]+/, human($1)); print}'
}

echo "test" | sort -h >& /dev/null
if [ $? -eq 0 ]; then
    bigdirs() {
        du -h ${PWD:A} | sort -h | tail -n ${1:-$(( $LINES - 6 ))}
    }
    bigfiles() {
        find ${PWD:A} -type f -exec du -h {} + | sort -h \
            | tail -n ${1:-$(( $LINES - 6 ))}
    }
else
    bigdirs() {
        du --block-size=1 ${PWD:A} | sort -n | tail -n ${1:-$(( $LINES - 6 ))} | b2h
    }
    bigfiles() {
        find ${PWD:A} -type f -exec du -b {} + | sort -n \
            | tail -n ${1:-$(( $LINES - 6 ))} | b2h
    }
fi

_cygyank() {
    CUTBUFFER=$(< /dev/clipboard | sed 's/\x0//g')
    zle yank
}
zle -N _cygyank
_cyg-vi-yank() {
    zle vi-yank
    printf "%s" "${CUTBUFFER}" > /dev/clipboard
}
zle -N _cyg-vi-yank
_cyg-vi-yank-eol() {
    zle vi-yank-eol
    printf "%s" "${CUTBUFFER}" > /dev/clipboard
}
zle -N _cyg-vi-yank-eol
_cyg-list-expand-or-copy-cwd() {
    if [[ $BUFFER =~ \\* ]]; then
        zle list-expand
    else
        printf "%s" "${PWD}" > /dev/clipboard
    fi
}
zle -N _cyg-list-expand-or-copy-cwd
_cyg-path() {
    printf "%s" "${1:A}" > /dev/clipboard
}
_cyg-copy() {
    printf "%s" "$@" > /dev/clipboard
}

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
    printf "%s" "${CUTBUFFER}" | xclip -i -sel p -f | xclip -i -sel c
}
zle -N _xclip-vi-yank
_xclip-vi-yank-eol() {
    zle vi-yank-eol
    printf "%s" "${CUTBUFFER}" | xclip -i -sel p -f | xclip -i -sel c
}
zle -N _xclip-vi-yank-eol
_xclip-list-expand-or-copy-cwd() {
    if [[ $BUFFER =~ \\* ]]; then
        zle list-expand
    else
        printf "%s" "${PWD}" | xclip -i -sel p -f | xclip -i -sel c
    fi
}
zle -N _xclip-list-expand-or-copy-cwd
_xclip-path() {
    printf "%s" "${1:A}" | xclip -i -sel p -f | xclip -i -sel c
}
_xclip-copy() {
    printf "%s" "$@" | xclip -i -sel p -f | xclip -i -sel c
}


vibindkey '^V' _xclipyank
bindkey -M vicmd 'y' _xclip-vi-yank
bindkey -M vicmd 'Y' _xclip-vi-yank-eol
vibindkey '^G' _xclip-list-expand-or-copy-cwd
path() {_xclip-path "$@"}
copy() {_xclip-copy "$@"}

_escalate-kill() {
    r="^ *kill"
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

_escalate-whence() {
    r="^ *wh"
    if [[ ! $BUFFER =~ $r ]] && [[ $history[$((HISTCMD-1))] =~ $r ]]; then
        BUFFER=$history[$((HISTCMD-1))]
    elif [[ ! $BUFFER =~ $r ]]; then
        return
    fi
    if [[ $BUFFER =~ ${r}"ence [^- ]" ]]; then
        BUFFER=${BUFFER/whence /whence -p }
    elif [[ $BUFFER =~ ${r}"ence -p" ]]; then
        BUFFER=${BUFFER/whence -p /whence -a }
    elif [[ $BUFFER =~ ${r}"ence -a" ]]; then
        BUFFER=${BUFFER/whence -a /which }
    elif [[ $BUFFER =~ ${r}"ich" ]] && [[ ! $BUFFER =~ ${r}"ere" ]]; then
        BUFFER=${BUFFER/which /where }
    fi
    CURSOR=$#BUFFER
}
zle -N _escalate-whence

_escalate-rm() {
    r="^ *rm"
    if [[ ! $BUFFER =~ ${r} ]] && [[ $history[$((HISTCMD-1))] =~ ${r} ]]; then
        BUFFER=$history[$((HISTCMD-1))]
    elif [[ ! $BUFFER =~ ${r} ]]; then
        return
    fi
    if [[ $BUFFER =~ ${r}" [^- ]" ]]; then
        BUFFER=${BUFFER/rm /rm -r }
    elif [[ $BUFFER =~ ${r}" -r" ]]; then
        BUFFER=${BUFFER/rm -r /rm -f }
    elif [[ $BUFFER =~ ${r}" -f" ]]; then
        BUFFER=${BUFFER/rm -f /rm -rf }
    fi
    CURSOR=$#BUFFER
}
zle -N _escalate-rm

_escalate() {
    if [[ $BUFFER =~ "^ *wh" ]]; then
        _escalate-whence
    elif [[ $BUFFER =~ "^ *rm" ]]; then
        _escalate-rm
    elif [[ $BUFFER =~ "^ *kill" ]]; then
        _escalate-kill
    elif [[ $BUFFER =~ "^ *(noglob )?find ." ]]; then
        BUFFER=${BUFFER/find ./find \$PWD}; CURSOR=$(($CURSOR+3))
    elif [[ ${history[$((HISTCMD-1))]} =~ "^ *wh" ]]; then
        _escalate-whence
    elif [[ ${history[$((HISTCMD-1))]} =~ "^ *rm" ]]; then
        _escalate-rm
    elif [[ ${history[$((HISTCMD-1))]} =~ "^ *kill" ]]; then
        _escalate-kill
    fi
}
zle -N _escalate; vibindkey '^K' _escalate

_backward-kill-WORD () {
    local WORDCHARS=${WORDCHARS}"\"\`'\@,:"
    zle backward-kill-word
}
zle -N _backward-kill-WORD; vibindkey '÷' _backward-kill-WORD  # <M-w>

_backward-kill-to-slash () {
    local WORDCHARS=${WORDCHARS//\//}
    zle backward-kill-word
}
zle -N _backward-kill-to-slash; vibindkey '^@' _backward-kill-to-slash

_backward-kill-to-_ () {
    local WORDCHARS=${WORDCHARS//_/}
    zle backward-kill-word
}
zle -N _backward-kill-to-_; vibindkey '–' _backward-kill-to-_  # <M-->

md() { mkdir -p "$@" && cd "$@" }

rationalise-dot() { [[ $LBUFFER == *.. ]] && LBUFFER+=/.. || LBUFFER+=. }
zle -N rationalise-dot; bindkey . rationalise-dot
bindkey -M isearch . self-insert

_time-command() {
    BUFFER="time ( "$BUFFER" )"
    CURSOR=$(( $CURSOR + 7 ))
}
zle -N _time-command; vibindkey '^X^T' _time-command

_vim-args() {
    local pat literal
    # Try to set vim's search pattern if opening files from ag command
    if [[ ${BUFFER[(w)1]} =~ ^ag?$ ]]; then
        # Append "-l" if it's not present
        [[ ! $BUFFER =~ ' -l( |$)' ]] && BUFFER=${BUFFER}' -l'
        # Extract string between quotes
        [[ $BUFFER =~ "'(.*)'" ]]; pat=${${match[1]}:-""}
        [[ $BUFFER == *-Q* || $BUFFER == *-F* ]]; literal=$?
        if [[ ! $literal == 0 ]]; then
            pat=${${pat//</\\<}//>/\\>}; pat=${pat//\\b/(<|>)}
        fi
        if [[ -z $pat ]]; then
            # If BUFFER is of the form 'ag pattern -l', extract pattern
            if (( ${(w)#BUFFER} == 3 )) && [[ ${BUFFER[(w)-1]} == "-l" ]]; then
                pat=${BUFFER[(w)2]}
            fi
        fi
        if [[ -n $pat ]]; then
            if [[ $BUFFER == *-Q* ]]; then
                BUFFER="vim +/'\\V$pat' \$( "$BUFFER" )"
            else
                BUFFER="vim +/'\\v$pat' \$( "$BUFFER" )"
            fi
            CURSOR=$(( $CURSOR + 14 + ${#pat} ))
            return
        fi
    fi
    BUFFER="vim \$( "$BUFFER" )"
    CURSOR=$(( $CURSOR + 7 ))
}
zle -N _vim-args; vibindkey 'å' _vim-args  # <M-e>

_use-as-args() {
    BUFFER=" \$( "$BUFFER" )"
    CURSOR=0
}
zle -N _use-as-args; bindkey '^A' _use-as-args

_vim-pipe() {
    BUFFER="vim =("${BUFFER}" 2>&1 | tee \$(tty)) -c 'set ft='"
    CURSOR=$(( ${#BUFFER} - 27 ))
}
zle -N _vim-pipe; bindkey 'ð' _vim-pipe  # <M-p>

_fg-job-or-yank() {
    if [[ -z $BUFFER && -n $(jobs) ]]; then
        _set-block-cursor
        _disable-focus
        fg
        zle reset-prompt
        _tmux-name-auto
    else
        zle yank
    fi
}
zle -N _fg-job-or-yank; vibindkey '^Z' _fg-job-or-yank

autoload -Uz add-zsh-hook
# Ring bell after long commands finish
if [[ -o interactive ]] && zmodload zsh/datetime; then
    zbell_lasttime=0
    zbell_duration=5
    zbell_ignore=(vi vim vims view vimdiff gvim gvims gview gvimdiff man \
        more less e ez tmux tmx matlab vimr)
    zbell_begin() {
        zbell_timestamp=${zbell_timestamp:-$EPOCHSECONDS}
        zbell_lastcmd=$1
    }
    zbell_end() {
        if [ $zbell_timestamp ]; then
            zbell_lasttime=$(( $EPOCHSECONDS - $zbell_timestamp ))
            unset zbell_timestamp
            ran_long=$(( $zbell_lasttime >= $zbell_duration ))
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
        fi
    }
    add-zsh-hook preexec zbell_begin
    add-zsh-hook precmd zbell_end
fi

_tmux-name-win() {
    if [[ -n $TMUX ]] && [[ -z $(jobs) ]] && [[ -z $NOAUTONAME ]]; then
        if [[ $(tmux display-message -p -t $TMUX_PANE '#{window_panes}') -eq 1 ]]; then
            name=$(print -n "/${${PWD/#$HOME/\~}##*/}/")
            if [[ ${#name} -gt 25 ]]; then; name=${name[1,10]}…${name[-10,-1]}; fi
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

_reset-saved-buffer() { BUFSAVE=; }
add-zsh-hook precmd _reset-saved-buffer
_list-choices-or-logout() {
    [[ -z $BUFFER ]] && { [[ -o login ]] && logout || exit; }
    if [[ -n $BUFSAVE ]]; then
        if [[ $BUFSAVE == "$BUFFER" ]]; then
            zle vi-kill-line
            [[ -o login ]] && logout || exit
        fi
    fi
    BUFSAVE=$BUFFER
    zle list-choices
}
zle -N _list-choices-or-logout; vibindkey '^D' _list-choices-or-logout

tmux-next() { tmux next >& /dev/null }
zle -N tmux-next; vibindkey '^[[27;5;9~' tmux-next
tmux-prev() { tmux prev >& /dev/null }
zle -N tmux-prev; vibindkey '^[[27;6;9~' tmux-prev

typeset -TUgx VIMBLACKLIST vimblacklist ,
vimblacklist=(vimshell tmux-complete jedi clang_complete haskellmode ghcmod \
    neco-ghc haskell deoplete neocomplete)

vim-blacklist-add() {
    for i in "$@"; do
        vimblacklist=($vimblacklist "$i")
    done
}

vim-blacklist-remove() {
    for i in "$@"; do
        vimblacklist[${vimblacklist[(i)$i]}]=()
    done
}

zmodload -i zsh/parameter
insert-last-command-output() { LBUFFER+="$(eval $history[$((HISTCMD-1))])" }
zle -N insert-last-command-output
bindkey '^X^O' insert-last-command-output

unalias ipython >& /dev/null
ipython() {
    export LINES
    export COLUMNS
    command ipython "$@" --pylab --autocall 1
}

_remove-for-vared() {
    zle self-insert
    if [[ $LBUFFER == "vared !$" ]]; then
        zle expand-history
        LBUFFER=${LBUFFER/\$/}
    fi
}
zle -N _remove-for-vared; insbindkey '$' _remove-for-vared

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 0
zstyle ':completion:*:*:cdr:*:*' menu selection
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':completion:*' recent-dirs-insert true

_repeat-prev-command() {
    if [[ $LBUFFER == "@" ]]; then
        LBUFFER=$history[$((HISTCMD-1))]
        zle accept-line
    else
        zle self-insert
    fi
}
zle -N _repeat-prev-command; insbindkey ':' _repeat-prev-command

_check-previous-exit-code() {
    if [[ $BUFFER == '&' ]]; then
        BUFFER='[ $? -eq 0 ] &&'
        CURSOR=${#BUFFER}
    else
        zle self-insert
    fi
}
zle -N _check-previous-exit-code; bindkey '&' _check-previous-exit-code

_insert-home() {
    if [[ $LBUFFER[-1] == '$' ]]; then
        LBUFFER=${LBUFFER[1,-2]}$HOME
    else
        LBUFFER+=\~
    fi
}
zle -N _insert-home; insbindkey '~' _insert-home

za() {
    ag "$@" -- "${$(man -w zsh):A:h}"/z*(.)
}

# Ctrl-F opens Vim as command editor
_edit-command-line() {
    local tmpfile=${TMPPREFIX:-/tmp/zsh}ecl$$
    _disable-focus
    _set-block-cursor
    print -R - "$PREBUFFER$BUFFER" >$tmpfile
    exec </dev/tty
    vim $VIMOPTIONS --cmd 'ino <C-s> <Esc>:wqa!<CR>' --cmd 'nn <C-s> :wqa!<CR>' $tmpfile
    print -Rz - "$(<$tmpfile)"
    command rm -f $tmpfile
    _enable-focus
    _set-bar-cursor
    zle send-break  # Force reload from the buffer stack
}
zle -N _edit-command-line; vibindkey '^F' _edit-command-line

# Use zsh's builtin edit-command-line with <M-f>
autoload edit-command-line
zle -N edit-command-line
vibindkey 'æ' edit-command-line  # <M-f>

_vared-vipe() {
    LBUFFER='export '${LBUFFER//=/}'="$(echo $'${LBUFFER//=/}' | vipe)"'
    zle accept-line
}
zle -N _vared-vipe; vibindkey 'Å' _vared-vipe  # <M-E>

# Append to history file
_log-command() {
    if [[ "$1" != " "* ]]; then
        local -a lines
        lines=(${(f)1})
        printf "%s;%s" "$PWD" "${lines[1]}" >> $HOME/.directory_history
        for line in ${lines[2,-1]}; do
            printf '\\\n%s' "$line" >> $HOME/.directory_history
        done
        printf "\n" >> $HOME/.directory_history
    fi
}
add-zsh-hook preexec _log-command

awkp() {
    awk "{print \$$1}"
}

_glob-newest() {
    LBUFFER=${LBUFFER}'(om[1])'
}
zle -N _glob-newest; insbindkey 'î' _glob-newest  # <M-n>

undo() {
    if [[ "$1" == *.un~ ]]; then
        printf %s "${1:h}"/"${${${1:t}#.}%.un~}"
    else
        printf %s "${1:h}"/."${1:t}".un~
    fi
}

badundo() {
    if [[ ! -e "$(undo ${REPLY:-$1})" ]]; then; return 1; fi
    vim -u NONE -i NONE -N -Es "${REPLY:-$1}" <<< 'set undofile
    redir => status
    execute "rundo ".fnameescape(undofile(expand("%:p")))
    redir END | if status =~# "Finished reading undo file" | cquit! | endif
    qall!'
}

now() {
    printf '%s' $(date +'%Y_%m_%d_%H%M%Z')
}
_insert-now() {
    zle split-undo
    LBUFFER=${LBUFFER}'$(now)'
}
zle -N _insert-now; bindkey '^Xd' _insert-now
zle -N _insert-now; bindkey '^XD' _insert-now
today() {
    printf '%s' ${${$(date +$DATEFMT)[(w)2]}#0##}
}
_insert-today() {
    zle split-undo
    LBUFFER=${LBUFFER}'$(today)'
}
zle -N _insert-today; bindkey '^X^D' _insert-today

autoload -Uz zargs
autoload -Uz zmv

dirdiff() { vim -c "DirDiff $1 $2" }
compdef '_path_files -/' dirdiff

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
if (( $+commands[vimpager] )); then
    export PAGER=vimpager
else
    export VIMPAGER="/bin/sh -c \"unset PAGER;col -b -x | \
        vim -R -c 'set ft=man nomod noma nolist' \
        -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""
    export PAGER=
    alias man='PAGER=$VIMPAGER man'
fi
export DIRSTACKSIZE=10
export KEYTIMEOUT=5
[[ -e ~/.dircolors ]] && eval $(dircolors -b ~/.dircolors)
export FPATH
export EDITOR=vim
export DATEFMT='%a %d%b%Y %T'
export VIMSERVER=${VIMSERVER:-VIM}
export TAR_OPTIONS='-k'
export INPUTRC=$HOME/.inputrc
_vim_maps=(
"nnoremap @! :<C-u><C-r><C-r>:<Home><C-Right>!<CR>"
"nnoremap @? :<C-u><C-r><C-r>:<Home>verbose <CR>"
"cnoremap <C-p> <Up>"
"cnoremap <C-n> <Down>"
"nnoremap <S-Tab> <C-o>zv"
"nnoremap <Leader>a ggVG"
"vnoremap <Leader>a <Esc>ggVG"
"nnoremap Y y$"
"nnoremap <C-v> \"+gP"
"cnoremap <C-v> <C-r>=substitute(@+, '\n', '', 'g')<CR>"
"inoremap <C-v> <C-r>+"
"inoremap <C-b> <Home>"
"inoremap <C-e> <End>"
"inoremap <C-f> <C-e>"
"nnoremap <C-s> :<C-u>update<CR>"
"inoremap <C-s> <Esc>:<C-u>update<CR>"
"xnoremap <C-s> <Esc>:<C-u>update<CR>"
"nnoremap _ -"
)
VIMOPTIONS=('-u' 'NONE' '-i' 'NONE' '-N' \
    "--cmd" $'set <C-Left>=\e[1;5D' "--cmd" $'set <C-Right>=\e[1;5C' \
    "--cmd" "set ai bs=indent,eol,start cb=unnamed,unnamedplus et gd hid hls \
    ic is nosmd nosol nowrap nf=hex nu rnu sc si sm sts=4 sw=4 wmnu \
    wim=longest:full,full" "--cmd" ${(j:|:)_vim_maps})

#[[[1 Completion Stuff
[[ -z "$modules[zsh/complist]" ]] && zmodload zsh/complist

# Use shift-tab to select previous completion
vibindkey '^[[Z' reverse-menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Cycle completions with <C-n>/<C-p>
bindkey -M menuselect '^N' complete-word
bindkey -M menuselect '^P' reverse-menu-complete

# Bring up completion menu after pressing tab once
setopt auto_menu

# Enter executes line instead of exiting menu
bindkey -M menuselect '^M' .accept-line

# Ctrl-E accepts current completion
bindkey -M menuselect '^E' accept-search
bindkey -M menuselect '/' accept-search
bindkey -M menuselect '^[' accept-search

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

unsetopt list_ambiguous
setopt complete_in_word

# Separate man page sections. Neat.
zstyle ':completion:*:manuals' separate-sections true

# complete with a menu for xwindow ids
zstyle ':completion:*:windows' menu on=0

# Insert all expansions first but give a menu with individual expansions
zstyle ':completion:*:expand:*' tag-order 'all-expansions expansions'
zstyle ':completion:*:expand:*' group-order all-expansions expansions

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
zstyle ':completion:*:kill:*' command 'ps --forest -u $USER -o pid,tty,cputime,command'

# Don't suggest _functions
zstyle ':completion:*:functions' ignored-patterns '_*'

# Fast completion for files only
# Use menu immediately and include hidden files to avoid refreshing file list
zle -C complete-files complete-word _generic
zstyle ':completion:complete-files:*' completer _files _tilde
zstyle ':completion:complete-files:*' file-patterns '*(D):all-files'
zstyle ':completion:complete-files:*' menu 'yes=0' 'select=0'
vibindkey '^]' complete-files
bindkey -M menuselect '^]' complete-word  # cycle through menu with <C-]>

# Don't expand ~ or $param at the start of a word
zstyle ':completion:*' keep-prefix true

# Load keeper functions
autoload -U keeper && {
keeper
bindkey -M viins '^X^K' insert-kept-result
bindkey -M viins '^Xk'  expand-kept-result
bindkey -M menuselect '^K' complete-word
zstyle ':completion:insert-kept-result:*' insert-kept menu
}

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
setopt prompt_subst
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

    # Fix disappearing terminal lines
    # See oh-my-zsh/plugins/vi-mode/vi-mode.plugin.zsh
    if (( $+terminfo[smkx] && $+terminfo[rmkx] )); then
        case "$0" in
            (zle-line-init)
                # Enable terminal application mode.
                echoti smkx
                ;;
            (zle-line-finish)
                # Disable terminal application mode.
                echoti rmkx
                ;;
        esac
    fi

    zle reset-prompt
    zle -R
}
zle -N zle-keymap-select
zle-line-finish() { _vim_mode=$_vim_ins_mode }
zle -N zle-line-finish
TRAPINT() {
    _vim_mode=$_vim_ins_mode
    return $(( 128 + $1 ))
}
_lineup=$'\e[1A'
_linedown=$'\e[1B'
[[ -n $SSH_CLIENT ]] && _hostcolor=9 || _hostcolor=3
PROMPT="
%{$fg[blue]%}%n%{$reset_color%}@%F{$_hostcolor}%m%f %{$fg[cyan]%}\$(_short-pwd)%{$reset_color%}
[zsh %{$fg[cyan]%}%1~%{$reset_color%} %{$fg[red]%}%(?..:( )%1(j,+ ,)%{$reset_color%}\${_vim_mode}]%# "

# Right prompt
_svn_prompt_info() {
    local info
    info=$(svn info) 2> /dev/null

    if [[ -n $info ]]; then
        echo -ne '%F{4}(%F{10}svn %F{2}'$(_svn_current_branch_name $info)
        echo -ne '%F{1}:%F{3}'$(_svn_current_revision $info)'%F{4})%f'
    fi
}

_svn_current_branch_name() {
    url=$(echo ${1[(fr)URL: *]})
    wcopy=$(echo ${1[(fr)Working *]})/trunk
    if [[ $url =~ trunk ]] && [[ -n $wcopy ]]; then
        root=${wcopy[(ws:/:)-1]}
        if [[ $root == 'trunk' ]]; then
            echo ${wcopy[(ws:/:)-2]}
        else
            echo $root
        fi
    else
        if [[ $url =~ branches ]]; then
            last=$(echo ${url[${url[(i)branches]}+9,-1]})
        elif [[ $url =~ tags ]]; then
            last=$(echo ${url[${url[(i)tags]}+5,-1]})
        elif [[ $url =~ svn ]]; then
            last=$(echo ${url[${url[(i)svn]}+4,-1]})
        else
            last=${url[(ws:/:)-1]}
        fi
        echo ${last[(ws:/:)1]}
    fi
}

_svn_current_revision() {
    rev=$(echo ${1[(fr)Revision: *]})
    echo ${rev[(w)-1]}
}

zstyle ':vcs_info:*' actionformats '%F{4}(%F{10}%s %F{2}%r%F{1}:%F{3}%b %F{1}%a%u%c%F{4})%f'
zstyle ':vcs_info:*' formats       '%F{4}(%F{10}%s %F{2}%r%F{1}:%F{3}%b%u%c%F{4})%f'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r%f'
zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes 0
zstyle ':vcs_info:*' stagedstr "%F{2} ●"
zstyle ':vcs_info:*' unstagedstr '%F{9} !'

autoload -Uz vcs_info
_prompt-update() {
    vcs_info
    psvar[1]=${vcs_info_msg_0_}
    [[ -z $psvar[1] ]] && psvar[1]=$(_svn_prompt_info)
    local zero='%([BSUbfksu]|([FB]|){*})'
    export _PSVARLEN=${#${(S%%)psvar[1]//$~zero/}}
}
add-zsh-hook precmd _prompt-update
if [[ -n $(battery 2> /dev/null) ]]; then
    RPROMPT="%{${_lineup}%}%{$fg[yellow]%}[\${\$(battery)//%%/%%}] "
else
    RPROMPT="%{${_lineup}%}"
fi
RPROMPT=${RPROMPT}"%{$reset_color%}\$psvar[1]%1(V, ,)"
RPROMPT=${RPROMPT}"%{$fg_bold[green]%}%T%{$reset_color%}"
RPROMPT=${RPROMPT}" !%{$fg[red]%}\${zbell_lasttime}s%{$reset_color%}%{${_linedown}%}"

# Auto-correct prompt
SPROMPT="Correct $fg[red]%R$reset_color to $fg[green]%r$reset_color? (Yes, No, Abort, Edit) "

# Update prompt after TMOUT seconds and after hitting enter
TMOUT=10
TRAPALRM() { [[ -z $BUFFER ]] && [[ -z $WIDGET ]] && zle reset-prompt }

# vared setup
zle -N _set-bar-cursor
_vared_red="%{$fg[red]%}vared%{$reset_color%}"
vared() {
    _vared_var="%{$fg[yellow]%}${argv[-1]}%{$reset_color%}"
    builtin vared -i _set-bar-cursor -p \
        $(echo '\n')'[${_vared_red} ${_vared_var} ${_vim_mode}]%# ' ${argv[-1]}
}

#[[[1 Cygwin settings
if [[ $OSTYPE == 'cygwin' ]]; then
    export GROFF_NO_SGR=1
    alias man='MANWIDTH=$(( $COLUMNS - 6 )) man'

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

    # Use Cygwin clipboard in case X11 is not running
    vibindkey '^V' _cygyank
    bindkey -M vicmd 'y' _cyg-vi-yank
    bindkey -M vicmd 'Y' _cyg-vi-yank-eol
    vibindkey '^G' _cyg-list-expand-or-copy-cwd
    path() {_cyg-path "$@"}
    copy() {_cyg-copy "$@"}

    # cygdrive shortcuts
    hash -d c=/cygdrive/c
    hash -d d=/cygdrive/d
    hash -d e=/cygdrive/e
    hash -d f=/cygdrive/f
    hash -d j=/cygdrive/j
    hash -d l=/cygdrive/l
    hash -d u=/cygdrive/u
    hash -d z=/cygdrive/z
fi

#[[[1 Machine-specific settings
[[ -e ~/.zshrclocal ]] && source ~/.zshrclocal

# Check if important variables have been set
_unset=()
typeset -U _unset
for _var in VIMCONFIG FPATH FZF_RUBY_EXEC FZF_DEFAULT_OPTS FZF_DEFAULT_COMMAND; do
    [[ -z $(eval echo "\${$_var}") ]] && _unset+=($_var)
done
[[ ! $FPATH =~ 'misc' ]] && _unset+=(FPATH)
[[ -n $_unset ]] && echo "Unset variables:" ${(j/, /)_unset}

[[ -z $VIMCONFIG ]] && export VIMCONFIG=$HOME/vimconfig || :
[[ -e $VIMCONFIG ]] && source $VIMCONFIG/misc/extract.plugin.zsh || :
[[ -d $VIMCONFIG/misc ]] && fpath=($VIMCONFIG/misc $fpath)

# vim: set fdm=marker fdl=1 et sw=4 fmr=[[[,]]]:
