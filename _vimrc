" {{{1 Vim built-in configuration

" Allow settings that are not vi-compatible
if &compatible | set nocompatible | endif

" Reset autocommands when vimrc is re-sourced
silent! autocmd! VimrcAutocmds

" Check if in read-only mode to disable unnecessary plugins
if !exists('s:readonly') | let s:readonly=&readonly | endif

set shiftwidth=4               " Number of spaces to indent
set expandtab                  " Use spaces instead of tabs
set tabstop=4                  " Length of indent
set softtabstop=4
set autoindent                 " Automatic indentation
set cinoptions+=N-s            " Don't indent namespaces in C++
set cinoptions+=(0             " Line up function arguments
set nowrap                     " Don't wrap lines
set lazyredraw                 " Don't update display during macro execution
set encoding=utf-8             " Set default file encoding
set backspace=indent,eol,start " Backspace through everything in insert mode
set whichwrap+=<,>,[,]         " Cursor keys wrap to previous/next line
set hlsearch                   " Highlight search terms
set incsearch                  " Incremental searching
set ignorecase                 " Make search case-insensitive and smart
set smartcase
set showcmd                    " Show information about running command
set showmode                   " Show current mode
set nrformats-=octal           " Don't treat numbers as octal when incrementing/decrementing
set shortmess+=t               " Truncate filenames in messages when necessary
set showmatch                  " Show matching brace after inserting
set shiftround                 " Round indent to multiple of shiftwidth
set scrolloff=2                " Pad lines/columns with context around cursor
set sidescrolloff=5
set display+=lastline          " Show as much as possible of the last line in a window
set autoread                   " Automatically load file if changed outside of vim
set number                     " Turn on hybrid line numbers
sil! set relativenumber
set history=1000               " Remember more command history
set tabpagemax=20              " Allow more tabs
set hidden                     " Allow switching buffer without saving changes first
set wildmenu                   " Turn on autocompletion
set wildmode=longest:full,full
set visualbell                 " Use visual bell instead of sound
sil! set undofile              " Enable persistent undo
set undolevels=1000
sil! set undoreload=10000
set ttimeout                   " Make keycodes time out after a short delay
set ttimeoutlen=50
set laststatus=2               " Always show statusline
set keywordprg=:help           " Use Vim help instead of man to look up keywords
set splitright                 " Vertical splits open on the right
set splitbelow                 " Horizontal splits open on the bottom
set fileformats=unix,dos       " Always prefer unix format
sil! set fileformat=unix
set csqf=s-,c-,d-,i-,t-,e-     " Use quickfix list for cscope results
set foldopen+=jump             " Jumps open folds
set clipboard=unnamed          " Yank to system clipboard
set clipboard+=unnamedplus
set mouse=                     " Disable mouse integration
set cmdwinheight=15            " Increase command window height
set showbreak=↪                " Show character at start of wrapped lines

" Configure display of whitespace
set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:×,eol:¬

" Turn on filetype plugins and indent settings
filetype plugin indent on

" Turn on syntax highlighting
if !exists("syntax_on") | syntax enable | endif

" Use four spaces to indent vim file line continuation
let g:vim_indent_cont=4

" Session settings
set sessionoptions=buffers,curdir,folds,help,tabpages,winsize
nnoremap <silent> ,l :source ~/session.vis<CR>
if !s:readonly && !exists('g:no_session')
    augroup VimrcAutocmds
        au VimLeavePre * mks! ~/session.vis
        au VimEnter * mks! ~/periodic_session.vis
        au VimEnter * exe "au BufEnter,BufRead,BufWrite,CursorHold * silent! mks! ~/periodic_session.vis"
    augroup END
endif

" Enable matchit plugin
runtime! macros/matchit.vim

" {{{2 Switch to last active tab/window
let g:lastTab=1
func! s:SetLastWindow()
    for l:tab in range(1,tabpagenr('$'))
        for l:win in range(1,tabpagewinnr(l:tab,'$'))
            if gettabwinvar(l:tab,l:win,'last')
                call settabwinvar(l:tab,l:win,'last',0)
            endif
        endfor
    endfor
    let w:last=1
endfunc
func! s:LastActiveWindow()
    " Switch to last active window if it still exists
    for l:tab in range(1,tabpagenr('$'))
        for l:win in range(1,tabpagewinnr(l:tab,'$'))
            if gettabwinvar(l:tab,l:win,'last')
                exec 'tabn '.l:tab
                exec l:win.'wincmd w'
                return
            endif
        endfor
    endfor
    if winnr('$') > 1
        winc w
    else
        tabnext
    endif
endfunc
augroup VimrcAutocmds
    au TabLeave * let g:lastTab=tabpagenr()
    au WinEnter * let w:last=0
    au WinLeave * call <SID>SetLastWindow()
augroup END
nnoremap <silent> <expr> ` g:inCmdwin? ':q<CR>' : ':call <SID>LastActiveWindow()<CR>'
nnoremap <silent> <Leader>l :exe "tabn ".g:lastTab<CR>
nnoremap <silent> ' `
nnoremap <silent> <M-'> '

" {{{2 Platform-specific configuration
let hasMac=has("mac")
let hasWin=has("win16") || has("win32") || has("win64")
let hasSSH=!empty($SSH_CLIENT)
let iPadSSH=hasMac && hasSSH && $SSH_CLIENT =~ '154'

if hasWin
    " Change where backups are saved
    if !isdirectory("C:\\temp\\vimtmp")
        call mkdir("C:\\temp\\vimtmp", "p")
    endif
    set backupdir=C:\temp\vimtmp,.
    set directory=C:\temp\vimtmp,.

    " Explore to current file
    nnoremap <silent> <F4> :call system('start explorer /select,\"'.expand('%:p').'\"')<CR>

    " Use Cygwin shell if present
    if system('where zsh') =~? 'zsh'
        set shell=zsh
    elseif system('where bash') =~? 'bash'
        set shell=bash
    else
        " Reset v:shell_error
        call system('echo')
    endif
    if &shell !~ 'cmd'
        set shellxquote=\" shellcmdflag=-c shellslash grepprg=grep\ -nH\ $*\ /dev/null
        nnoremap <silent> <F4> :call system('cygstart explorer /select,\"'
            \.substitute(expand('%:p'),'\/','\\','g').'\"')<CR>
    endif

    let s:hasvimtools=filereadable(expand("$VIM/vimfiles/autoload/vimtools.vim"))
else
    " Change swap file location for unix
    if !isdirectory(expand("~/.tmp"))
        call mkdir(expand("~/.tmp"), "p")
    endif
    set backupdir=~/.tmp
    set directory=~/.tmp
    if hasMac | sil! set undodir=~/.tmp | endif

    if hasMac
        " Reveal current file in Finder
        nnoremap <silent> <F4> :call system('reveal '.expand('%:p').' > /dev/null')<CR>

        " Enable use of option key as meta key
        sil! set macmeta
    else
        " Explore to current file from Cygwin vim
        nnoremap <silent> <F4> :call system('cygstart explorer /select,`cygpath -w "'.expand('%:p').'"`')<CR>
    endif

    let s:hasvimtools=filereadable(expand("$HOME/.vim/autoload/vimtools.vim"))
endif

" {{{2 Mappings
" Save current file if modified or execute command if in command window
nn <silent> <expr> <C-s> g:inCmdwin? '<CR>' : ':update<CR>'
ino <silent> <expr> <C-s> g:inCmdwin? '<CR>' : '<Esc>:update<CR>'
vn <silent> <C-s> <C-c>:update<CR>

" Redraw the screen and remove search highlighting
nn <silent> <C-l> :nohl<CR><C-l>

" Execute q macro
nm Q @q

" Execute q macro recursively
nn <silent> <Leader>q :set nows<CR>:let @q=@q."@q"<CR>:norm @q<CR>
    \:set ws<CR>:let @q=substitute(@q,'\(^.*\)@q','\1','')<CR>

" Toggle paste mode
nn <silent> <Leader>p :set paste!<CR>

" Select all
nn <Leader>a ggVG
vn <Leader>a <C-c>ggVG

" Toggle line numbers
nn <silent> <F2> :se nu!<bar>sil! let &rnu=&nu<CR>
vm <silent> <F2> <Esc><F2>gv
im <F2> <C-o><F2>

" Edit configuration files
if s:hasvimtools
    com! -nargs=1 SwitchToOrOpen call vimtools#SwitchToOrOpen(<f-args>)
else
    com! -nargs=1 SwitchToOrOpen tab drop <args>
endif
nn <silent> ,ea :<C-u>SwitchToOrOpen ~/.ackrc<CR>
nn <silent> ,eb :<C-u>SwitchToOrOpen ~/.bashrc<CR>
nn <silent> ,ec :<C-u>SwitchToOrOpen ~/.cshrc<CR>
nn <silent> ,es :<C-u>SwitchToOrOpen ~/.screenrc<CR>
nn <silent> ,et :<C-u>SwitchToOrOpen ~/.tmux.conf<CR>
nn <silent> ,ev :<C-u>SwitchToOrOpen $MYVIMRC<CR>
nn <silent> ,ex :<C-u>SwitchToOrOpen ~/.Xdefaults<CR>
nn <silent> ,ez :<C-u>SwitchToOrOpen ~/.zshrc<CR>

" Source vimrc
nn <silent> ,sv :so $MYVIMRC<CR>

" Shortcuts for switching buffer
nn <silent> <C-p> :bp<CR>
nn <silent> <C-n> :bn<CR>

" Search recursively or non-recursively
nn ,gr :vim // **/*<C-Left><C-Left><Right>
nn ,gn :vim // *<C-Left><C-Left><Right>
nn ,go :call setqflist([])<CR>:silent! Bufdo vimgrepa // %<C-Left><C-Left><Right>
nn <Leader>gr :grep **/*(D.) -e ''<Left>
nn <Leader>gn :grep *(D.) -e ''<Left>
nn <Leader>go :call setqflist([])<CR>:silent! Bufdo grepa '' %<C-Left><C-Left><Right>

" Delete trailing whitespace
nn <silent> ,ws :keepj sil!%s/\s\+$\\|\v$t^//g<CR>
    \:call histdel('/','\V$t^')<CR>:let @/=histget('/',-1)<CR>

" Open tag in vertical split with Alt-]
nn <M-]> <C-w><C-]><C-w>L

" <Esc> alternatives - <Nul> is <C-Space> in terminal
ino <C-c> <NOP>
ino <C-Space> <Esc>
nno <C-Space> <Esc>
cno <C-Space> <Esc>
ino <Nul> <Esc>
nno <Nul> <Esc>
cno <Nul> <Esc>
ino jk <Esc>
ino kj <Esc>

" Shortcuts for switching tab, including closing command window if it's open
nn <silent> <expr> <C-Tab>   g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <C-S-Tab> g:inCmdwin? ':q<CR>gT' : 'gT'
nn <silent> <expr> <M-l>     g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <M-h>     g:inCmdwin? ':q<CR>gT' : 'gT'
nn <silent> <expr> <F15>     g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <F16>     g:inCmdwin? ':q<CR>gT' : 'gT'

" Open new tab
nn <silent> <M-t> :tabnew<CR>
nn <silent> <M-T> :tab split<CR>

" Print number of occurences of last search
nn <silent> <M-n> :%s///gn<CR>
vn <silent> <M-n> :s///gn<CR>

" Delete without yank by default, and <M-d> for delete with yank
nn c "_c|nn <M-c> c|nn \\c c|vn c "_c|vn <M-c> c|vn \\c c
nn C "_C|nn <M-C> C|nn \\C C|vn C "_C|vn <M-C> C|vn \\C C
nn d "_d|nn <M-d> d|nn \\d d|vn d "_d|vn <M-d> d|vn \\d d
nn D "_D|nn <M-D> D|nn \\D D|vn D "_D|vn <M-D> D|vn \\D D
nn s "_s|nn <M-s> s|nn \\s s|vn s "_s|vn <M-s> s|vn \\s s
nn S "_S|nn <M-S> S|nn \\S S|vn S "_S|vn <M-S> S|vn \\S S
nn x "_x|nn <M-x> x|nn \\x x|vn x "_x|vn <M-x> x|vn \\x x
nn X "_X|nn <M-X> X|nn \\X X|vn X "_X|vn <M-X> X|vn \\X X

" Copy full file path to clipboard on Ctrl-g
nn <silent> <C-g> <C-g>:let @+=expand('%:p')<CR>:let @*=@+<CR>:let @"=@+<CR>

" Change tab position
nn <silent> <C-w><C-e>     :tabm<CR>
nn <silent> <C-w>e         :tabm<CR>
nn <silent> <C-w><C-a>     :tabm0<CR>
nn <silent> <C-w>a         :tabm0<CR>
nn <silent> <C-w><C-Left>  :<C-u>exe 'tabm-'.v:count1<CR>
nn <silent> <C-w><Left>    :<C-u>exe 'tabm-'.v:count1<CR>
nn <silent> <C-w><C-Right> :<C-u>exe 'tabm+'.v:count1<CR>
nn <silent> <C-w><Right>   :<C-u>exe 'tabm+'.v:count1<CR>

" Insert result of visually selected expression
vn <C-e> c<C-o>:let @"=substitute(@",'\n','','g')<CR><C-r>=<C-r>"<CR><Esc>

" Make <C-c> cancel <C-w> instead of closing window
no <C-w><C-c> <NOP>

" Make <C-w><C-q>/<C-w>q close window except the last window
nn <silent> <expr> <C-w><C-q> g:inCmdwin? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w>q     g:inCmdwin? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w><C-w> g:inCmdwin? ':q<CR>' : '<C-w><C-w>'

" <C-k>/<C-j> inserts blank line above/below
nn <silent> <C-j> :set paste<CR>m`o<Esc>``:set nopaste<CR>
nn <silent> <C-k> :set paste<CR>m`O<Esc>``:set nopaste<CR>

" <M-k>/<M-j> deletes blank line above/below
nn <silent> <M-j> m`:sil +g/\m^\s*$/d<CR>``:noh<CR>:call
    \ histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>
nn <silent> <M-k> m`:sil -g/\m^\s*$/d<CR>``:noh<CR>:call
    \ histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>

" Backspace deletes visual selection
vn <BS> "_d

" Ctrl-c copies visual characterwise
vn <C-c> <Esc>'<0v'>g_y

" File explorer at current buffer with -
nn <silent> - :Explore<CR>

" Repeat last command with a bang
nn @! :<C-u><C-r>:<Home><C-Right>!<CR>

" Repeat last command with case of first character switched
nn @~ :<C-u><C-r>:<C-f>^~<CR>

" Use <C-q> to do what <C-v> used to do
noremap <C-q> <C-v>

" Show current line of diff at bottom of tab
nn <Leader>dl <C-w>t<C-w>s<C-w>J<C-w>t<C-w>l<C-w>s<C-w>J<C-w>t:res<CR><C-w>b

" Make Y behave like other capital letters
map Y y$

" Navigate windows/tabs with arrow keys
no <Down>  <C-w>j
no <Up>    <C-w>k
no <silent> <Left>  :let w=winnr()<CR><C-w>h:if w==winnr()\|exe "norm! gT"\|en<CR>
no <silent> <Right> :let w=winnr()<CR><C-w>l:if w==winnr()\|exe "norm! gt"\|en<CR>

" Change window size with control + arrow keys
no <C-Down>  <C-w>-
no <C-Up>    <C-w>+
no <C-Left>  <C-w><
no <C-Right> <C-w>>

" Stay in visual mode after indent change
vn < <gv
vn > >gv

" Copy WORD above/below cursor with <M-y>/<M-e>
ino <expr> <M-y> matchstr(getline(line('.')-1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')
ino <expr> <M-e> matchstr(getline(line('.')+1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')

" Make j/k work as expected on wrapped lines using <expr> map to minimize side effects
no <expr> j &wrap?'gj':'j'
no <expr> k &wrap?'gk':'k'

" ZZ and ZQ close buffer if it's not open in another window
nn <silent> ZQ :let b=bufnr('%')<CR>:call setbufvar(b,'&bh','delete')<CR>
    \:norm! ZQ<CR>:sil! call setbufvar(b,'&bh','')<CR>
nn <silent> ZZ :let b=bufnr('%')<CR>:call setbufvar(b,'&bh','delete')<CR>
    \:norm! ZZ<CR>:sil! call setbufvar(b,'&bh','')<CR>

" Save and quit all
nn <silent> ZA :while 1 \| exe "norm ZZ" \| endwhile<CR>

" Go up directory tree easily
cno <expr> . (getcmdtype()==':'&&getcmdline()=~'[/ ]\.\.$')?'/..':'.'

" Execute line under cursor
nn <silent> <Leader>x :exec getline('.')<CR>

" Close quickfix window/location list
nn <silent> <Leader>w :ccl\|lcl<CR>

" Switch to quickfix window
nn <silent> <C-w><Space> :copen<CR>

" Make current buffer a scratch buffer
nn <silent> <Leader>s :set bt=nofile<CR>

" Echo syntax name under cursor
nn <silent> <Leader>y :echo synIDattr(synID(line("."), col("."), 1), "name")<CR>

" Change directory
nn <silent> <Leader>cd :cd! %:p:h<CR>:pwd<CR>
nn <silent> ,cd :lcd %:p:h<CR>:pwd<CR>
nn <silent> <Leader>.. :cd ..<CR>:pwd<CR>
nn <silent> ,.. :lcd ..<CR>:pwd<CR>

" <CR> in insert mode creates undo point
ino <CR> <C-g>u<CR>

" Put from " register in insert mode
ino <M-p> <C-r>"

" Go to older position in jump list
nn <S-Tab> <C-o>

" Make <C-d>/<C-u> scroll 1/4 page
nn <silent> <C-d> :exe 'set scr='.(winheight('.')+1)/4<CR><C-d>
nn <silent> <C-u> :exe 'set scr='.(winheight('.')+1)/4<CR><C-u>
vn <silent> <C-d> :<C-u>exe 'set scr='.(winheight('.')+1)/4<CR>gv<C-d>
vn <silent> <C-u> :<C-u>exe 'set scr='.(winheight('.')+1)/4<CR>gv<C-u>

" Highlight word without moving cursor
nn <silent> <Leader>* :let @/='\<'.expand('<cword>').'\>'<CR>:set hls<CR>
nn <silent> <Leader>8 :let @/='\<'.expand('<cword>').'\>'<CR>:set hls<CR>
nn <silent> <Leader>g* :let @/=expand('<cword>')<CR>:set hls<CR>
nn <silent> <Leader>g8 :let @/=expand('<cword>')<CR>:set hls<CR>

" Use 'very magic' regex by default
nn / /\v
vn / /\v
nn ? ?\v
vn ? ?\v

" Move current line to 1/5 down from top or up from bottom
nn <expr> zh "zt".(winheight('.')/5)."\<C-y>"
nn <expr> zl "zb".(winheight('.')/5)."\<C-e>"

" {{{2 Abbreviations to open help
if s:hasvimtools
    com! -nargs=? -complete=help Help call vimtools#OpenHelp(<q-args>)
    cnorea <expr> ht ((getcmdtype()==':'&&getcmdpos()<=3)?'tab help':'ht')
    cnorea <expr> h ((getcmdtype()==':'&&getcmdpos()<=2)?'Help':'h')
    cnorea <expr> H ((getcmdtype()==':'&&getcmdpos()<=2)?'Help':'H')
    cnoremap <expr> <Up> ((getcmdtype()==':'&&getcmdline()=='h')?'<BS>H<Up>':'<Up>')
    nmap <silent> <expr> K g:inCmdwin? 'viwK' : ":exec
        \ 'Help '.vimtools#HelpTopic()<CR>"
    vnoremap <silent> <expr> K vimtools#OpenHelpVisual()
endif

" {{{2 Cscope configuration
" Abbreviations for cscope commands
cnorea <expr> csa ((getcmdtype()==':'&&getcmdpos()<=4)?'cs add'   :'csa')
cnorea <expr> csf ((getcmdtype()==':'&&getcmdpos()<=4)?'cs find'  :'csf')
cnorea <expr> csk ((getcmdtype()==':'&&getcmdpos()<=4)?'cs kill *':'csk')
cnorea <expr> csr ((getcmdtype()==':'&&getcmdpos()<=4)?'cs reset' :'csr')
cnorea <expr> css ((getcmdtype()==':'&&getcmdpos()<=4)?'cs show'  :'css')
cnorea <expr> csh ((getcmdtype()==':'&&getcmdpos()<=4)?'cs help'  :'csh')

" Mappings for cscope find commands
no <M-\>s :cs find s <C-r>=expand("<cword>")<CR><CR>
no <M-\>g :cs find g <C-r>=expand("<cword>")<CR><CR>
no <M-\>c :cs find c <C-r>=expand("<cword>")<CR><CR>
no <M-\>t :cs find t <C-r>=expand("<cword>")<CR><CR>
no <M-\>e :cs find e <C-r>=expand("<cword>")<CR><CR>
no <M-\>f :cs find f <C-r>=expand("<cfile>")<CR><CR>
no <M-\>i :cs find i ^<C-r>=expand("<cfile>")<CR>$<CR>
no <M-\>d :cs find d <C-r>=expand("<cword>")<CR><CR>
vm <M-\> <Esc><M-\>

" {{{2 Functions
" Like bufdo but return to starting buffer
func! Bufdo(command)
    let currBuff=bufnr("%")
    execute 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunc
com! -nargs=+ -complete=command Bufdo call Bufdo(<q-args>)

" Function to set key codes for terminals
func! s:KeyCodes()
    " Set key codes to work as meta key combinations
    let ns=range(65,90)+range(92,123)+range(125,126)
    for n in ns
        exec "set <M-".nr2char(n).">=\<Esc>".nr2char(n)
    endfor
    exec "set <M-\\|>=\<Esc>\\| <M-'>=\<Esc>'"
endfunc
nnoremap <silent> <Leader>k :call <SID>KeyCodes()<CR>

func! s:CmdwinMappings()
    " Make 'gf' work in command window
    nnoremap <silent> <buffer> gf :let cfile=expand('<cfile>')<CR>:q<CR>
        \:exe 'e '.cfile<CR>
    nnoremap <silent> <buffer> <C-w>gf :let cfile=expand('<cfile>')<CR>:q<CR>
        \:exe 'tabe '.cfile<CR>

    " Delete item under cursor from history
    nnoremap <silent> <buffer> DD :call histdel(g:cmdwinType,'\V\^'.
        \escape(getline('.'),'\').'\$')<CR>:norm! "_dd<CR>
endfunc

" Delete hidden buffers
func! s:DeleteHiddenBuffers()
    let tpbl=[]
    call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
    for l:buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
        silent! execute 'bd' l:buf
    endfor
endfunc
nnoremap <silent> <Leader>dh :call <SID>DeleteHiddenBuffers()<CR>

func! s:CleanEmptyBuffers()
    let buffers = filter(range(0, bufnr('$')), 'buflisted(v:val) && '
        \.'empty(bufname(v:val)) && bufwinnr(v:val)<0 && getbufvar(v:val,"&buftype")==""')
    if !empty(buffers)
        exe 'bw '.join(buffers, ' ')
    endif
endfunc
nnoremap <silent> <Leader>de :call <SID>CleanEmptyBuffers()<CR>

" Kludge to make first quickfix result unfold
func! s:ToggleFoldOpen()
    if &fdo != 'all'
        let s:fdoOld=&fdo
        set ut=1 fdo=all
        aug ToggleFoldOpen
            au CursorHold * call s:ToggleFoldOpen()
        aug END
    else
        exec 'set fdo='.s:fdoOld.' ut=4000'
        aug ToggleFoldOpen
            au!
        aug END
    endif
endfunc
autocmd VimrcAutocmds QuickFixCmdPost * call s:ToggleFoldOpen()

" Function to redirect output of ex command to clipboard
func! Redir(cmd)
    redir @" | execute a:cmd | redir END
    let @"=substitute(@","^\<NL>*",'','g')
    let @*=@"
    let @+=@"
endfunc
com! -nargs=+ -complete=command Redir call Redir(<q-args>)
nnoremap <Leader>r :<Up><Home>Redir <CR>

" Function to removing trailing carriage return from register
func! s:FixReg()
    let l:reg=nr2char(getchar())
    let l:str=getreg(l:reg)
    while l:str =~ "\<CR>\<NL>"
        let l:str=substitute(l:str,"\<CR>\<NL>","\<NL>",'')
    endwhile
    call setreg(l:reg, l:str)
endfunc
nnoremap <silent> <Leader>f :call <SID>FixReg()<CR>

" Make dot repeat ignore InsertEnter event
func! s:DotRepeat(count)
    let eventignore_save = &eventignore
    let &eventignore = 'InsertEnter'
    try
        exec "norm! ".(a:count ? a:count : "")."."
    finally
        let &eventignore = eventignore_save
    endtry
endfunc
nnoremap <silent> . :<C-u>call <SID>DotRepeat(v:count)<CR>

" Make q macro ignore InsertEnter event
func! s:QMacro(count)
    let eventignore_save = &eventignore
    let &eventignore = 'InsertEnter'
    " Prevent creating undo points during macro execution
    inoremap <buffer> <CR> <CR>
    try
        exec "norm ".(a:count ? a:count : "")."@q"
    finally
        let &eventignore = eventignore_save
        iunmap <buffer> <CR>
    endtry
endfunc
nnoremap <silent> Q :<C-u>call <SID>QMacro(v:count)<CR>

" Cycle search mode between regular, very magic, and very nomagic
func! s:CycleSearchMode()
    let l:cmd = getcmdline()
    let l:pos = getcmdpos()
    if l:cmd =~# '^\\v'
        let l:cmd = substitute(l:cmd,'^\\v','\\V','')
    elseif l:cmd =~# '^\\V'
        let l:cmd = substitute(l:cmd,'^\\V','','')
        call setcmdpos(l:pos - 2)
    else
        let l:cmd = '\v'.l:cmd
        call setcmdpos(l:pos + 2)
    endif
    return l:cmd
endfunc
cnoremap <C-x> <C-\>e<SID>CycleSearchMode()<CR>

" Make /<CR> and ?<CR> work when \v is added automatically
func! s:SearchCR()
    if getcmdtype() =~ '[/?]'
        if getcmdline() ==? '\v'
            return "\<End>\<C-u>\<CR>zv"
        else
            return "\<C-]>\<CR>zv"
        endif
    endif
    return "\<C-]>\<CR>"
endfunc
cnoremap <expr> <CR> <SID>SearchCR()

" Close other windows or close other tabs
func! s:CloseWinsOrTabs()
    let startwin = winnr()
    wincmd t
    if winnr() == winnr('$')
        tabonly
    else
        if winnr() != startwin | wincmd p | endif
        wincmd o
    endif
endfunc
nnoremap <silent> <C-w>o :call <SID>CloseWinsOrTabs()<CR>
nnoremap <silent> <C-w><C-o> :call <SID>CloseWinsOrTabs()<CR>

" <C-v> pastes from system clipboard
func! s:Paste()
    if @+ =~ "\<NL>"
        set paste
        set pastetoggle=<F10>
        return "\<C-r>+\<F10>"
    endif
    return "\<C-r>+"
endfunc
map <C-v> "+gP
cmap <C-v> <C-r>+
imap <expr> <C-v> <SID>Paste()
exe 'vnoremap <script> <C-v> '.paste#paste_cmd['v']

" Make last search a whole word
func! s:SearchWholeWord(dir)
    if @/[0:1] ==# '\v'
        let @/ = '\v<('.@/[2:].')>'
    elseif @/[0:1] ==# '\V'
        let @/ = '\V\<\('.@/[2:].'\)\>'
    else
        let @/='\<\('.@/.'\)\>'
    endif
    echo a:dir.@/
endfunc
nn <silent> <Leader>n :call <SID>SearchWholeWord('/')<CR>n
nn <silent> <Leader>N :call <SID>SearchWholeWord('?')<CR>N

" Search for first non-blank
func! s:FirstNonBlank()
    if getcmdline() == '^'
        return "\<BS>".'\(^\s*\)\@<='
    elseif getcmdline() ==# '\v^'
        return "\<BS>".'(^\s*)@<='
    elseif getcmdline() ==# '\V^'
        return "\<BS>".'\(\^\s\*\)\@\<\='
    else
        return '^'
    endif
endfunc
cnoremap <expr> ^ getcmdtype()=~'[/?]' ? <SID>FirstNonBlank() : '^'

" Don't delete the v/V at the start of a search
func! s:SearchCmdDelWord()
    if getcmdtype() =~ '[/?]' && getcmdline() =~? '^\\v\k*$'
        if getcmdline()[1] ==# 'v'
            return "\<C-w>v"
        else
            return "\<C-w>V"
        endif
    endif
    return "\<C-w>"
endfunc
cnoremap <expr> <C-w> <SID>SearchCmdDelWord()

" Fix up arrow in seach history when search starts with \v
func! s:OlderHistory()
    if getcmdtype() =~ '[/?]' && getcmdline() ==? '\v'
        return "\<C-u>\<Up>"
    elseif s:hasvimtools
        return ((getcmdtype()==':'&&getcmdline()=='h')?"\<BS>H\<Up>":"\<Up>")
    endif
    return "\<Up>"
endfunc
cnoremap <expr> <Up> <SID>OlderHistory()

" Make [[, ]], [], and ][ work when { is not in first column
func! s:SectionJump(type, v)
    let l:count = v:count1
    if a:v | exe "norm! gv" | endif
    while l:count
        if a:type == '[['
            call search('{','b',1)
            normal! w99[{
        elseif a:type == ']['
            call search('}','',line('$'))
            normal! b99]}
        elseif a:type == ']]'
            normal j0[[%
            call search('{','',line('$'))
        elseif a:type == '[]'
            normal k$][%
            call search('}','b',1)
        endif
        let l:count -= 1
    endwhile
endfunc
func! s:SectionJumpMaps()
    noremap  <silent> [[ :<C-u>call <SID>SectionJump('[[',0)<CR>
    noremap  <silent> ][ :<C-u>call <SID>SectionJump('][',0)<CR>
    noremap  <silent> ]] :<C-u>call <SID>SectionJump(']]',0)<CR>
    noremap  <silent> [] :<C-u>call <SID>SectionJump('[]',0)<CR>
    xnoremap <silent> [[ :<C-u>call <SID>SectionJump('[[',1)<CR>
    xnoremap <silent> ][ :<C-u>call <SID>SectionJump('][',1)<CR>
    xnoremap <silent> ]] :<C-u>call <SID>SectionJump(']]',1)<CR>
    xnoremap <silent> [] :<C-u>call <SID>SectionJump('[]',1)<CR>
endfunc
autocmd VimrcAutocmds FileType c,cpp call <SID>SectionJumpMaps()

" {{{2 GUI configration
if has('gui_running')
    " Disable most visible GUI features
    set guioptions=eAc

    if hasWin
        " Set font for gVim
        if hostname() ==? 'Jake-Desktop'
            " Big font for big TV
            set guifont=DejaVu_Sans_Mono_for_Powerline:h13:cANSI
        else
            set guifont=DejaVu_Sans_Mono_for_Powerline:h11:cANSI
        endif
    elseif hasMac
        " Set font for MacVim
        set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h15

        " Start in fullscreen mode
        autocmd VimrcAutocmds VimEnter * sil! set fullscreen
    else
        " Use text-only tabline (prevent resizing issues)
        set guioptions-=e

        " Set font for gVim
        set guifont=DejaVu\ Sans\ Mono\ for\ Powerline\ 11
    endif
else
    " Make control + arrow keys work in terminal
    exec "set <F13>=\<Esc>[A <F14>=\<Esc>[B <C-Right>=\<Esc>[C <C-Left>=\<Esc>[D"
    map <F13> <C-Up>
    map <F14> <C-Down>
    map! <F13> <C-Up>
    map! <F14> <C-Down>

    " Change tab in XTerm
    "         <C-Tab>              <C-S-Tab>
    exec "set <F15>=\<Esc>[27;5;9~ <F16>=\<Esc>[27;6;9~"

    " Use correct background color
    autocmd VimrcAutocmds VimEnter * set t_ut=|redraw!

    " Enable mouse for scrolling
    set mouse=nir
    for b in ["Left","Middle","Right"] | for m in ["","2","C","S","A"]
        execute 'map <'.m.(strlen(m)?'-':'').b.'Mouse> <NOP>'
    endfor | endfor
endif

" }}}2

" Abbreviations for diff commands
cnorea <expr> dt ((getcmdtype()==':'&&getcmdpos()<=3)?'windo diffthis':'dt')
cnorea <expr> do ((getcmdtype()==':'&&getcmdpos()<=3)?'windo diffoff \|
    \ windo set nowrap':'do')
cnorea <expr> du ((getcmdtype()==':'&&getcmdpos()<=3)?'diffupdate':'du')

" Increase time allowed for keycode mappings over SSH
if iPadSSH
    set ttimeoutlen=250
elseif hasSSH
    set ttimeoutlen=100
endif

augroup VimrcAutocmds
    " Don't auto comment new line made with 'o', 'O', or <CR>
    autocmd FileType * set formatoptions-=o
    autocmd FileType * set formatoptions-=r

    " Use line wrapping for plain text files (but not help files)
    autocmd FileType text setl wrap linebreak
    autocmd FileType help setl nowrap nolinebreak concealcursor=

    " Indent line continuation for conf files
    autocmd FileType conf setl indentexpr=getline(v:lnum-1)=~'\\\\$'?&sw:0

    " Prefer single-line style comments and fix shell script comments
    autocmd FileType cpp,arduino setl commentstring=//%s
    autocmd FileType * if &cms=='# %s' | setl cms=#%s | endif
    autocmd FileType dosbatch setl commentstring=REM%s
    autocmd FileType autohotkey setl commentstring=;%s

    " Highlight current line in active window but not in insert mode
    autocmd BufRead,BufNewFile,VimEnter * set cul
    autocmd InsertLeave,WinEnter * set cul
    autocmd InsertEnter,WinLeave * set nocul

    " Disable paste mode after leaving insert mode
    autocmd InsertLeave * set nopaste

    " Open quickfix window automatically if not empty
    autocmd QuickFixCmdPost * cw

    " Always make quickfix full-width on the bottom
    autocmd FileType qf wincmd J

    " Use to check if inside command window
    au VimEnter,CmdwinLeave * let g:inCmdwin=0
    au CmdwinEnter * let g:inCmdwin=1
    au CmdwinEnter / let g:cmdwinType='/'
    au CmdwinEnter ? let g:cmdwinType='?'
    au CmdwinEnter : let g:cmdwinType=':'
    au CmdwinEnter * call <SID>CmdwinMappings()

    " Load files with mixed line endings as DOS format
    autocmd BufReadPost * nested
        \ if !exists('b:reload_dos') && !&binary && &ff == 'unix'
        \       && (0 < search('\r$', 'nc')) |
        \     let b:reload_dos = 1 |
        \     e ++ff=dos |
        \ endif

    " Restore cursor position and open fold after loading a file
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \     exe "normal! g`\"" | let b:do_unfold = 1 |
        \ endif
    autocmd BufWinEnter * if exists('b:do_unfold') |
        \ exe "normal! zv" | unlet b:do_unfold | endif
augroup END

" {{{1 Plugin configuration

" Make empty list of disabled plugins
let g:pathogen_disabled=[]

" Only enable misc/shell in Windows
if !hasWin | call extend(g:pathogen_disabled, ['misc','shell']) | endif

" Disable some plugins if in read-only mode
if s:readonly
    call add(g:pathogen_disabled, 'neocomplete')
    call add(g:pathogen_disabled, 'neosnippet-snippets')
    call add(g:pathogen_disabled, 'syntastic')
    call add(g:pathogen_disabled, 'tabular')
    call add(g:pathogen_disabled, 'unite')
    call add(g:pathogen_disabled, 'vimfiler')
endif

" Set airline color scheme
let g:airline_theme='tomorrow'
au VimrcAutocmds TabEnter * sil! call airline#highlighter#highlight(['normal',&mod?'modified':''])

" Use powerline font unless in Mac SSH session or in old Vim
if iPadSSH || v:version < 703
    let g:airline_powerline_fonts=0
    let g:airline_left_sep=''
    let g:airline_right_sep=''
else
    let g:airline_powerline_fonts=1
endif

" Toggle warnings in airline
nnoremap <silent> <M-w> :AirlineToggleWhitespace<CR>

" Shortcut to force close buffer without closing window
nnoremap <silent> <Leader><Leader>bd :Bclose!<CR>

" Tagbar configuration
" Don't use Tagbar integration in airline until needed
if !exists('g:initialized_tagbar')
    sil! let g:airline_section_x='%{&ft}'
endif
func! s:TagbarToggle()
    if !exists('g:initialized_tagbar')
        call TagbarInit()
        let g:airline_section_x=airline#section#create_right(['tagbar', 'filetype'])
        exe 'AirlineToggle' | exe 'AirlineToggle'
    endif
    TagbarToggle
endfunc
nnoremap <silent> <Leader>t :sil! call <SID>TagbarToggle()<CR>
let g:tagbar_iconchars=['▶','▼']
let g:tagbar_sort=0
let g:tagbar_autofocus=1

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr=1
let OmniCpp_MayCompleteScope=1
autocmd VimrcAutocmds CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif

" Commentary configuration
xmap <Leader>c  <Plug>Commentary
nmap <Leader>c  <Plug>Commentary
omap <Leader>c  <Plug>Commentary
nmap <Leader>cc <Plug>CommentaryLine
nmap c<Leader>c <Plug>ChangeCommentary
nmap <Leader>cu <Plug>Commentary<Plug>Commentary
let g:commentary_map_backslash=0

" {{{2 Completion settings
if has('lua')
    call add(g:pathogen_disabled, 'supertab')

    " NeoComplete settings
    let g:neocomplete#enable_at_startup=1
    let g:neocomplete#enable_smart_case=1
    let g:neocomplete#max_list=200
    let g:neocomplete#min_keyword_length=3
    let g:neocomplete#enable_refresh_always=1
    let g:neocomplete#sources#buffer#cache_limit_size=3000000
    if !exists('g:neocomplete#same_filetypes')
        let g:neocomplete#same_filetypes={}
    endif
    let g:neocomplete#same_filetypes._='_'
    if !exists('g:neocomplete#force_omni_input_patterns')
        let g:neocomplete#force_omni_input_patterns={}
    endif
    let g:neocomplete#force_omni_input_patterns.matlab='\h\w*\.\w*'
    func! s:StartManualComplete(dir)
        " Indent if only whitespace behind cursor
        if getline('.')[col('.')-2] =~ '\S'
            return pumvisible() ? (a:dir ? "\<C-n>" : "\<C-p>")
                \: neocomplete#start_manual_complete()
        else
            return a:dir ? "\<Tab>" : "\<BS>"
        endif
    endfunc
    inoremap <expr> <Tab>   <SID>StartManualComplete(1)
    inoremap <expr> <S-Tab> <SID>StartManualComplete(0)
    inoremap <expr> <CR>    neocomplete#close_popup()."\<C-g>u\<CR>"
    inoremap <expr> <C-e>   neocomplete#close_popup()
    imap     <expr> <C-d>   neosnippet#expandable_or_jumpable()?
        \"\<Plug>(neosnippet_expand_or_jump)":
        \neocomplete#close_popup()
    inoremap <expr> <C-f>   neocomplete#cancel_popup()
    inoremap <expr> <C-l>   neocomplete#complete_common_string()
    if !exists('g:neocomplete#sources')
        let g:neocomplete#sources={}
    endif
    let g:neocomplete#sources._=['_']
    augroup VimrcAutocmds
        autocmd CmdwinEnter * inoremap <buffer> <expr> <Tab>   pumvisible() ? "\<C-n>"
            \ : neocomplete#start_manual_complete()
        autocmd CmdwinEnter * inoremap <buffer> <expr> <S-Tab> pumvisible() ? "\<C-p>"
            \ : neocomplete#start_manual_complete()
        autocmd InsertLeave * if &ft=='vim' | sil! exe 'NeoCompleteVimMakeCache' | en
    augroup END
else
    call add(g:pathogen_disabled, 'neocomplete')
    let g:SuperTabDefaultCompletionType="context"
endif

" {{{2 EasyMotion settings
map <S-Space> <Space>
map! <S-Space> <Space>
let g:EasyMotion_keys='ABCDEFGIMNOPQRSTUVWXYZLKJH'
let g:EasyMotion_use_upper=1
let g:EasyMotion_add_search_history=0
let g:EasyMotion_smartcase=1
let g:EasyMotion_enter_jump_first=1
map <Space> <Plug>(easymotion-s2)
map <Space>/ <Plug>(easymotion-sn)
map <Space><Space>f <Plug>(easymotion-bd-f)
map <Space><Space>t <Plug>(easymotion-bd-t)
map <Space><Space>w <Plug>(easymotion-bd-w)
map <Space><Space>W <Plug>(easymotion-bd-W)
map <Space><Space>e <Plug>(easymotion-bd-e)
map <Space><Space>E <Plug>(easymotion-bd-E)
map <Space><Space>n <Plug>(easymotion-bd-n)
autocmd VimrcAutocmds VimEnter * sil! unmap <Leader><Leader>

" {{{2 VimFiler settings
nnoremap <silent> - :VimFilerBufferDir -find<CR>
nnoremap <silent> <C-_> :VimFilerCurrentDir -find<CR>
let g:vimfiler_as_default_explorer=1
let g:loaded_netrwPlugin=1
nn <silent> gx :call netrw#NetrwBrowseX(expand("<cfile>"),0)<CR>
let g:vimfiler_tree_leaf_icon=' '
let g:vimfiler_file_icon='-'
let g:vimfiler_tree_opened_icon='▼'
let g:vimfiler_tree_closed_icon='▶'
let g:vimfiler_marked_file_icon='✓'
let g:vimfiler_restore_alternate_file=1
autocmd VimrcAutocmds FileType vimfiler call s:vimfiler_settings()
func! s:vimfiler_settings()
    nmap <buffer> m     <Plug>(vimfiler_toggle_mark_current_line)
    nmap <buffer> <M-m> <Plug>(vimfiler_move_file)
    nmap <buffer> e     <Plug>(vimfiler_execute)
    nmap <buffer> <BS>  <Plug>(vimfiler_close)
    nmap <buffer> -     <Plug>(vimfiler_switch_to_parent_directory)
    nmap <buffer> <F1>  <Plug>(vimfiler_help)
    nmap <buffer> <expr> <CR> vimfiler#smart_cursor_map(
        \"\<Plug>(vimfiler_expand_tree)","\<Plug>(vimfiler_edit_file)")
    exe "nunmap <buffer> <Space>" | exe "nunmap <buffer> L" | exe "nunmap <buffer> M"
    exe "nunmap <buffer> H" | exe "nunmap <buffer> <S-Space>" | exe "nunmap <buffer> ?"
endfunc

" {{{2 Unite settings
let g:unite_source_history_yank_enable=1
let g:unite_split_rule='botright'
let g:unite_enable_start_insert=1
let g:unite_marked_icon='✓'
let g:unite_cursor_line_highlight='CursorLine'
if executable('ag')
    let g:unite_source_grep_command='ag'
    let g:unite_source_grep_default_opts='--nogroup --nocolor --column'
    let g:unite_source_grep_recursive_opt=''
endif
let g:unite_source_grep_search_word_highlight='WarningMsg'
let g:unite_source_history_yank_save_clipboard=1
augroup VimrcAutocmds
    autocmd VimEnter * sil! call unite#filters#matcher_default#use(['matcher_regexp'])
    autocmd FileType unite setl conceallevel=0
    autocmd FileType unite call <SID>UniteMaps()
augroup END
func! s:UniteMaps()
    inor <silent> <buffer> <expr> <C-q> unite#do_action('delete')
    nnor <silent> <buffer> <expr> <C-q> unite#do_action('delete')
    inor <silent> <buffer> <expr> <C-s>= unite#do_action('split')
    nnor <silent> <buffer> <expr> <C-s>= unite#do_action('split')
    inor <silent> <buffer> <expr> <C-s>" unite#do_action('vsplit')
    nnor <silent> <buffer> <expr> <C-s>" unite#do_action('vsplit')
    imap <silent> <buffer> <expr> <C-d> <SID>UniteTogglePathSearch()."\<Esc>"
        \.'gg3\|"+YZQ'.":\<C-u>Unite -buffer-name=Buffers/NeoMRU "
        \."-unique buffer neomru/file\<CR>"."\<C-r>+"
    nmap <buffer> <expr> yy unite#do_action('yank').'<Plug>(unite_exit)'
    imap <buffer> <expr> <C-o>v unite#do_action('vsplit')
    imap <buffer> <expr> <C-o>s unite#do_action('split')
    imap <buffer> <expr> <C-o>t unite#do_action('tabopen')
    imap <buffer> <expr> <C-o>d unite#do_action('tabdrop')
    imap <buffer> <expr> <C-o>o unite#do_action('view')
    imap <buffer> <expr> <C-o>r unite#do_action('open')
    imap <buffer> <C-o> <Plug>(unite_choose_action)
    nmap <buffer> <C-o> <Plug>(unite_choose_action)
    inor <buffer> <C-f> <C-o><C-d>
    inor <buffer> <C-b> <C-o><C-u>
    nmap <buffer> <C-p> <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-p> <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-j> <Plug>(unite_select_next_line)
    imap <buffer> <C-k> <Plug>(unite_select_previous_line)
    nmap <buffer> ` <Plug>(unite_exit)
    imap <buffer> ` <Plug>(unite_exit)
    nmap <buffer> <C-c> <Plug>(unite_exit)
    imap <buffer> <C-c> <Plug>(unite_exit)
    nmap <buffer> m <Plug>(unite_toggle_mark_current_candidate)
    nmap <buffer> M <Plug>(unite_toggle_mark_current_candidate_up)
    nmap <buffer> <F1>  <Plug>(unite_quick_help)
    sil! nunmap <buffer> ?
endfunc
nnoremap <silent> "" :<C-u>Unite -no-start-insert history/yank<CR>
nnoremap <silent> "' :<C-u>Unite -no-start-insert register<CR>
nnoremap <silent> <expr> ,a ":\<C-u>Unite -no-start-insert -no-quit grep:".getcwd()."\<CR>"
com! -nargs=? -complete=file BookmarkAdd call unite#sources#bookmark#_append(<q-args>)
nnoremap <silent> ,b :<C-u>Unite bookmark<CR>
nnoremap <silent> ,vr :Unite -no-start-insert -no-quit vimgrep:**/*<CR>
nnoremap <silent> ,vn :Unite -no-start-insert -no-quit vimgrep:**<CR>
nnoremap <silent> <C-n> :<C-u>Unite -buffer-name=files file_rec/async<CR>
nnoremap <silent> <expr> <C-p> ":\<C-u>Unite -buffer-name="
    \ .(len(filter(range(1,bufnr('$')),'buflisted(v:val)')) > 1
    \ ? "Buffers/" : "")."NeoMRU ".(len(filter(range(1,bufnr('$')),
    \ 'buflisted(v:val)')) > 1 ? "buffer" : "")." -unique neomru/file\<CR>"
if !exists('s:UnitePathSearchMode') | let s:UnitePathSearchMode=0 | endif
func! s:UniteTogglePathSearch()
    if s:UnitePathSearchMode
        call unite#custom#source('buffer,neomru/file','matchers',
            \ ['matcher_regexp'])
        call unite#custom#source('buffer,neomru/file','converters',
            \ ['converter_default'])
        let s:UnitePathSearchMode=0
    else
        call unite#custom#source('buffer,neomru/file','matchers',
            \ ['converter_tail','matcher_regexp'])
        call unite#custom#source('buffer,neomru/file','converters',
            \ ['converter_file_directory'])
        let s:UnitePathSearchMode=1
    endif
    return ''
endfunc

" }}}2

" Undotree/Gundo settings
if has('python')
    call add(g:pathogen_disabled, 'undotree')
    nnoremap <silent> <Leader>u :GundoToggle<CR>
    let g:gundo_help=0
    let g:gundo_preview_bottom=1
else
    call add(g:pathogen_disabled, 'Gundo')
    nnoremap <silent> <Leader>u :UndotreeToggle<CR>
    let g:undotree_SplitWidth=40
    let g:undotree_SetFocusWhenToggle=1
endif

" Surround settings
xmap S <Plug>VSurround

" Syntastic settings
let g:syntastic_filetype_map={'arduino': 'cpp'}
let g:syntastic_mode_map={'mode': 'passive', 'active_filetypes': [], 'passive_filetypes': []}
let g:airline#extensions#syntastic#enabled=0

" Tabular settings
let g:no_default_tabular_maps=1

" Indent Guides settings
let g:indent_guides_auto_colors=0
nmap <silent> <Leader>i <Plug>IndentGuidesToggle

" Ack settings
if executable('ag') | let g:ackprg='ag --nogroup --nocolor --column' | endif
let g:ack_autofold_results=0
com! -nargs=* -bang A Ack<bang> <args>

" tmux navigator settings
let g:tmux_navigator_no_mappings=1
nnoremap <silent> <M-Left>  :TmuxNavigateLeft<CR>
nnoremap <silent> <M-Down>  :TmuxNavigateDown<CR>
nnoremap <silent> <M-Up>    :TmuxNavigateUp<CR>
nnoremap <silent> <M-Right> :TmuxNavigateRight<CR>

" Import scripts
execute pathogen#infect()

" Add current directory and red arrow if ignorecase is not set to status line
sil! call airline#parts#define('ic',{'condition': '!\&ic',
    \'text': nr2char(8593),'accent': 'red'})
sil! let g:airline_section_b = airline#section#create(['%{ShortCWD()}'])
sil! let g:airline_section_c = airline#section#create(['ic', '%<', 'file',
    \g:airline_symbols.space, 'readonly'])

" Solarized settings
set background=dark
if iPadSSH || $SOLARIZED != 1 | let g:solarized_termcolors=256 | endif
if !exists('colors_name') || colors_name != 'solarized'
    sil! colorscheme solarized
endif

" vim: fdm=marker fdl=1:
