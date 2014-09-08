" {{{1 Vim built-in configuration

" Allow settings that are not vi-compatible
if &compatible | set nocompatible | endif

" Reset autocommands when vimrc is re-sourced
augroup VimrcAutocmds
    autocmd!
augroup END

" Check if in read-only mode to disable unnecessary plugins
if !exists('s:readonly') | let s:readonly = &readonly || exists('vimpager') | endif

set shiftwidth=4                " Number of spaces to indent
set expandtab                   " Use spaces instead of tabs
set softtabstop=4
set autoindent                  " Automatic indentation
set cinoptions+=N-s             " Don't indent namespaces in C++
set cinoptions+=(0              " Line up function arguments
set nowrap                      " Don't wrap lines
set lazyredraw                  " Don't update display during macro execution
set encoding=utf-8              " Set default file encoding
set backspace=indent,eol,start  " Backspace through everything in insert mode
set whichwrap+=<,>,[,]          " Cursor keys wrap to previous/next line
set hlsearch                    " Highlight search terms
set incsearch                   " Incremental searching
set ignorecase                  " Make search case-insensitive and smart
set smartcase
set showmode                    " Show current mode
set nrformats-=octal            " Don't treat numbers as octal when incrementing/decrementing
set shortmess+=t                " Truncate filenames in messages when necessary
set showmatch                   " Show matching brace after inserting
set shiftround                  " Round indent to multiple of shiftwidth
set scrolloff=2                 " Pad lines/columns with context around cursor
set sidescrolloff=5
set display+=lastline           " Show as much as possible of the last line in a window
set autoread                    " Automatically load file if changed outside of vim
set number                      " Turn on hybrid line numbers
sil! set relativenumber
set history=5000                " Remember more command history
set tabpagemax=20               " Allow more tabs
set hidden                      " Allow switching buffer without saving changes first
set wildmenu                    " Turn on autocompletion
set wildmode=longest:full,full
set visualbell                  " Use visual bell instead of sound
sil! set undofile               " Enable persistent undo
set undolevels=1000
sil! set undoreload=10000
set ttimeout                    " Make keycodes time out after a short delay
set ttimeoutlen=50
set laststatus=2                " Always show statusline
set keywordprg=:help            " Use Vim help instead of man to look up keywords
set splitright                  " Vertical splits open on the right
set fileformats=unix,dos        " Always prefer unix format
sil! set fileformat=unix
set csqf=s-,c-,d-,i-,t-,e-      " Use quickfix list for cscope results
set foldopen+=jump              " Jumps open folds
set clipboard=unnamed           " Yank to system clipboard
sil! set clipboard+=unnamedplus
set mouse=                      " Disable mouse integration
set cmdwinheight=15             " Increase command window height
sil! set showbreak=↪            " Show character at start of wrapped lines
set makeprg=make\ -j            " Use multiple jobs in make by default
set nojoinspaces                " Don't add two spaces after punctuation
set gdefault                    " Substitute all occurrences by default
set nostartofline               " Don't jump to start of line for various motions

" Ignore system files
set wildignore=*.a,*.lib,*.spi,*.sys,*.dll,*.so,*.o,.DS_Store

" Configure display of whitespace
sil! set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:×,eol:¬

" Get return code from make command in v:shell_error
let &shellpipe='2>&1 | tee %s;echo ${pipestatus[1]} > $HOME/.exit;exit ${pipestatus[1]}'

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
        au VimEnter * exe "au BufWinEnter * silent! mks! ~/periodic_session.vis"
    augroup END
endif

" Enable matchit plugin
runtime! macros/matchit.vim

" {{{2 Switch to last active tab/window
let g:lastTab=1
func! s:LastActiveWindow()
    if winnr('#') > 0 && winnr('#') != winnr()
        wincmd p
    elseif winnr('$') > 1
        wincmd w
    elseif tabpagenr() != g:lastTab && g:lastTab <= tabpagenr('$')
        execute "tabnext ".g:lastTab
    else
        tabnext
    endif
endfunc
autocmd VimrcAutocmds TabLeave * let g:lastTab=tabpagenr()
nnoremap <silent> <expr> ` g:inCmdwin? ':q<CR>' : ':call <SID>LastActiveWindow()<CR>'
nnoremap <silent> <Leader>l :exe "tabn ".g:lastTab<CR>
nnoremap <silent> <Leader>; :exe "tabn ".g:lastTab<CR>
nnoremap <silent> ' `
nnoremap <silent> <M-'> '

" {{{2 Platform-specific configuration
let hasMac=has("mac")
let hasWin=has("win16") || has("win32") || has("win64")
let hasSSH=!empty($SSH_CLIENT)
let mobileSSH=hasMac && $MOBILE == 1

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

        " Use cygstart to open links
        let g:netrw_browsex_viewer = "cygstart"
    endif

    let s:hasvimtools=filereadable(expand("$HOME/.vim/autoload/vimtools.vim"))
endif

" {{{2 Mappings
" Save current file if modified or execute command if in command window
nn <silent> <expr> <C-s> g:inCmdwin? '<CR>' : ':update<CR>'
ino <silent> <expr> <C-s> g:inCmdwin? '<CR>' : '<Esc>:update<CR>'
vn <silent> <C-s> <C-c>:update<CR>gv

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
    command! -nargs=1 SwitchToOrOpen call vimtools#SwitchToOrOpen(<f-args>)
else
    command! -nargs=1 SwitchToOrOpen tab drop <args>
endif
nn <silent> ,ea :<C-u>edit ~/.vim/after/plugin/after.vim<CR>:norm! zv<CR>
nn <silent> ,eb :<C-u>edit ~/.bashrc<CR>:norm! zv<CR>
nn <silent> ,ec :<C-u>edit ~/.cshrc<CR>:norm! zv<CR>
nn <silent> ,eh :<C-u>edit ~/.histfile<CR>:norm! zv<CR>
nn <silent> ,ei :<C-u>edit ~/.inputrc<CR>:norm! zv<CR>
nn <silent> ,el :<C-u>edit ~/.zshrclocal<CR>:norm! zv<CR>
nn <silent> ,em :<C-u>edit ~/.minttyrc<CR>:norm! zv<CR>
nn <silent> ,es :<C-u>edit ~/.screenrc<CR>:norm! zv<CR>
nn <silent> ,et :<C-u>if expand('%') =~ "\.tmux\.conf$" \| edit
    \ ~/.tmux-local.conf \| else \| edit ~/.tmux.conf \| endif<CR>:norm! zv<CR>
nn <silent> ,ev :<C-u>edit $MYVIMRC<CR>:norm! zv<CR>
nn <silent> ,ex :<C-u>edit ~/.Xdefaults<CR>:norm! zv<CR>
nn <silent> ,ez :<C-u>edit ~/.zshrc<CR>:norm! zv<CR>

" Source vimrc
nn <silent> ,sv :so $MYVIMRC<CR>:runtime after/plugin/after.vim<CR>

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
nn <silent> <expr> ,ws ":keepj keepp sil! %s/\\s\\+$//".(&gdefault ? "" : "g")."\<CR>"

" Open tag in vertical split with Alt-]
nn <M-]> <C-w><C-]><C-w>L

" Open tag vertically or below
nn <silent> <C-w><C-]> :<C-u>execute "normal! :belowright vertical
    \ split<C-v><CR><C-v><C-]>".(v:count ? v:count."<C-v><C-w>_" : "")<CR>
nn <silent> <C-w>] :<C-u>execute "normal! :belowright
    \ split<C-v><CR><C-v><C-]>".(v:count ? v:count."<C-v><C-w>_" : "")<CR>

" Shortcuts for switching tab, including closing command window if it's open
nn <silent> <expr> <C-Tab>   tabpagenr('$')==1 ?
    \":sil! call system('tmux next')\<CR>" : (g:inCmdwin? ':q<CR>gt' : 'gt')
nn <silent> <expr> <C-S-Tab> tabpagenr('$')==1 ?
    \":sil! call system('tmux prev')\<CR>" : (g:inCmdwin? ':q<CR>gT' : 'gT')
ino <silent> <expr> <C-Tab> system('tmux next')
ino <silent> <expr> <C-S-Tab> system('tmux prev')
cno <silent> <expr> <C-Tab> system('tmux next')
cno <silent> <expr> <C-S-Tab> system('tmux prev')
vno <silent> <expr> <C-Tab> system('tmux next')
vno <silent> <expr> <C-S-Tab> system('tmux prev')
nm <M-l> <C-Tab>
nm <M-h> <C-S-Tab>
map <F15> <C-Tab>
map <F16> <C-S-Tab>
map! <F15> <C-Tab>
map! <F16> <C-S-Tab>

" Open new tab
nn <silent> <M-t> :tabnew<CR>
nn <silent> <M-T> :tab split<CR>

" Delete without yank by default, and <M-d> for delete with yank
nn c "_c|nn <M-c> c|nn \\c c|xn c "_c|xn <M-c> c|xn \\c c
nn C "_C|nn <M-C> C|nn \\C C|xn C "_C|xn <M-C> C|xn \\C C
nn d "_d|nn <M-d> d|nn \\d d|xn d "_d|xn <M-d> d|xn \\d d
nn D "_D|nn <M-D> D|nn \\D D|xn D "_D|xn <M-D> D|xn \\D D
nn s "_s|nn <M-s> s|nn \\s s|xn s "_s|xn <M-s> s|xn \\s s
nn S "_S|nn <M-S> S|nn \\S S|xn S "_S|xn <M-S> S|xn \\S S
nn x "_x|nn <M-x> x|nn \\x x|xn x "_x|xn <M-x> x|xn \\x x
nn X "_X|nn <M-X> X|nn \\X X|xn X "_X|xn <M-X> X|xn \\X X

" Copy file/path with/without line number
nn <silent> <C-g> <C-g>:let @+=expand('%:p')<CR>:let @*=@+<CR>:let @"=@+<CR>
nn <silent> g<C-g> g<C-g>:let @+=expand('%:p:h')<CR>:let @*=@+<CR>:let @"=@+<CR>
nn <silent> 1<C-g> 1<C-g>:let @+=expand('%:p:t')<CR>:let @*=@+<CR>:let @"=@+<CR>
nn <silent> <M-g> <C-g>:let @+=expand('%:p').':'.line('.')<CR>:let @*=@+<CR>:let @"=@+<CR>
nn <silent> <M-G> <C-g>:let @+=expand('%:p:t').':'.line('.')<CR>:let @*=@+<CR>:let @"=@+<CR>

" Change tab position
nn <silent> <C-w><C-e>     :tabm<CR>
nn <silent> <C-w>e         :tabm<CR>
nn <silent> <C-w><C-a>     :tabm0<CR>
nn <silent> <C-w>a         :tabm0<CR>
nn <silent> <C-w><C-Left>  :<C-u>exe 'tabm-'.v:count1<CR>
nn <silent> <C-w><Left>    :<C-u>exe 'tabm-'.v:count1<CR>
nn <silent> <C-w><C-Right> :<C-u>exe 'tabm+'.v:count1<CR>
nn <silent> <C-w><Right>   :<C-u>exe 'tabm+'.v:count1<CR>

" Make <C-c> cancel <C-w> instead of closing window
no <C-w><C-c> <NOP>

" Make <C-w><C-q>/<C-w>q close window except the last window
nn <silent> <expr> <C-w><C-q> g:inCmdwin? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w>q     g:inCmdwin? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w><C-w> g:inCmdwin? ':q<CR>' : '<C-w><C-w>'

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

" Repeat last command with 'verbose' prepended
nn @& :<C-u><C-r>:<Home>verbose <CR>

" Use <C-q> to do what <C-v> used to do
no <C-q> <C-v>

" Show current line of diff at bottom of tab
nn <Leader>dl <C-w>t<C-w>s<C-w>J<C-w>t<C-w>l<C-w>s<C-w>J<C-w>t:res<CR><C-w>b

" Make Y behave like other capital letters
map Y y$

" Navigate windows/tabs with arrow keys
no <Down>  <C-w>j
no <Up>    <C-w>k
no <silent> <Left>  :<C-u>let w=winnr()<CR><C-w>h:if w==winnr()\|exe "norm! gT"\|en<CR>
no <silent> <Right> :<C-u>let w=winnr()<CR><C-w>l:if w==winnr()\|exe "norm! gt"\|en<CR>

" Change window size with control + arrow keys
no <silent> <C-Down>  :<C-u>call vimtools#ResizeWindow('down')<CR>
no <silent> <C-Up>    :<C-u>call vimtools#ResizeWindow('up')<CR>
no <silent> <C-Left>  :<C-u>call vimtools#ResizeWindow('left')<CR>
no <silent> <C-Right> :<C-u>call vimtools#ResizeWindow('right')<CR>

" Stay in visual mode after indent change
vn < <gv
vn > >gv

" Copy WORD above/below cursor with <C-y>/<C-e>
ino <expr> <C-e> matchstr(getline(line('.')+1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')
ino <expr> <C-y> matchstr(getline(line('.')-1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')
ino <M-e> <C-e>
ino <M-y> <C-y>

" Make j/k work as expected on wrapped lines
no <expr> j &wrap && strdisplaywidth(getline('.')) > (winwidth(0) -
    \ (&number ? &numberwidth : 0)) ? 'gj' : 'j'
no <expr> k &wrap && max([strdisplaywidth(getline('.')),
    \ strdisplaywidth(getline(line('.')-1))]) >
    \ (winwidth(0) - (&number ? &numberwidth : 0)) ? 'gk' : 'k'

" ZZ and ZQ close buffer if it's not open in another window
nn <silent> ZQ :let b=bufnr('%')<CR>:call setbufvar(b,'&bh','delete')<CR>
    \:norm! ZQ<CR>:sil! call setbufvar(b,'&bh','')<CR>
nn <silent> ZZ :let b=bufnr('%')<CR>:call setbufvar(b,'&bh','delete')<CR>
    \:norm! ZZ<CR>:sil! call setbufvar(b,'&bh','')<CR>

" Save and quit all
nn <silent> ZA :wqall<CR>

" Go up directory tree easily
cno <expr> . (getcmdtype()==':'&&getcmdline()=~'[/ ]\.\.$')?'/..':'.'

" Execute line under cursor
nn <silent> <Leader>x :exec getline('.')<CR>

" Close quickfix window/location list
nn <silent> <Leader>w :ccl\|lcl\|winc z<CR>

" Switch to quickfix or location list window
nn <silent> <C-w><Space> :copen<CR>
nn <silent> <C-w><C-Space> :copen<CR>
nn <silent> <C-w><C-@> :copen<CR>
nn <silent> <C-w><C-g><Space> :lopen<CR>
nn <silent> <C-w><C-g><C-Space> :lopen<CR>
nn <silent> <C-w><C-g><C-@> :lopen<CR>
nn <silent> <C-w>g<Space> :lopen<CR>
nn <silent> <C-w>g<C-Space> :lopen<CR>
nn <silent> <C-w>g<C-@> :lopen<CR>

" Make current buffer a scratch buffer
nn <silent> <Leader>s :set bt=nofile<CR>

" Echo syntax name under cursor
nn <silent> <Leader>y :<C-U>exe vimtools#EchoSyntax(v:count)<CR>

" Change directory
nn <silent> <Leader>cd :cd! %:p:h<CR>:pwd<CR>
nn <silent> ,cd :lcd %:p:h<CR>:pwd<CR>
nn <silent> <Leader>.. :cd ..<CR>:pwd<CR>:sil! call repeat#set("\<Leader>..")<CR>
nn <silent> ,.. :lcd ..<CR>:pwd<CR>:sil! call repeat#set(",..")<CR>

" Put from " register in insert mode
ino <M-p> <C-r>"

" Go to older position in jump list
nn <S-Tab> <C-o>

" Make <C-d>/<C-u> scroll 1/3 page
no <expr> <C-d> (v:count ? "" : (winheight('.')) / 3 + 1)."\<C-d>"
no <expr> <C-u> (v:count ? "" : (winheight('.')) / 3 + 1)."\<C-u>"

" Highlight word without moving cursor
nn <silent> <Leader>* :let @/='\<'.expand('<cword>').'\>'<CR>
    \:call histadd('/', @/)<CR>:set hls<CR>
nn <silent> <Leader>8 :let @/='\<'.expand('<cword>').'\>'<CR>
    \:call histadd('/', @/)<CR>:set hls<CR>
nn <silent> <Leader>g* :let @/=expand('<cword>')<CR>
    \:call histadd('/', @/)<CR>:set hls<CR>
nn <silent> <Leader>g8 :let @/=expand('<cword>')<CR>
    \:call histadd('/', @/)<CR>:set hls<CR>

" Move current line to 1/5 down from top or up from bottom
nn <expr> zh "zt".(winheight('.')/5)."\<C-y>"
nn <expr> zl "zb".(winheight('.')/5)."\<C-e>"

" Open cursor file in vertical or horizontal split
nn <silent> <C-w><C-f> :belowright vertical wincmd f<CR>
nn <silent> <C-w>f :belowright wincmd f<CR>

" Default make key
nn <silent> <F5> :update<CR>:make<CR><CR>
im <F5> <Esc><F5>

" Cycle through previous searches
nn <silent> <expr> <C-k> (g:inCmdwin? '' : "/\<C-f>".v:count1)."k:let @/=getline('.')<CR>"
nn <silent> <expr> <C-j> (g:inCmdwin? '' : "/\<C-f>".v:count1)."j:let @/=getline('.')<CR>"

" Don't open fold when jumping to first or last line in diff mode
nn <silent> <expr> gg "gg".(&diff ? "" : "zv")
nn <silent> <expr> G "G".(&diff ? "" : "zv")

" [count]V always selects [count] lines
nn <expr> V v:count ? "\<Esc>V".(v:count > 1 ? (v:count - 1).'j' : '') : 'V'

" <Home> moves cursor after \v
cno <expr> <Home> "\<Home>".(getcmdtype() =~ '[/?]' &&
    \ getcmdline() =~? '^\\v' ? "\<Right>\<Right>" : "")
cmap <C-b> <Home>

" Fix @: in visual mode when there is a modifier before the range
vnoremap <expr> @ @: =~ "\\V'<,'>" ? "\<Esc>@" : "@"

" Synonyms for q: and q/
nn g: q:
nn g/ q/

" Use <C-n>/<C-p> instead of arrows for command line history
cm <C-p> <Up>
cm <C-n> <Down>

" - is used for file browser
nn _ -

" Go to most recent text change
nn <silent> g. m':execute "buffer".g:last_change_buf<CR>:keepjumps normal! `.<CR>

" Delete swap file and reload file
nn <silent> <Leader>ds :<C-u>Redir swap<CR>:call system("rm <C-r>"<BS>p")<CR>:e<CR>

" {{{2 Abbreviations to open help
if s:hasvimtools
    command! -nargs=? -complete=help Help call vimtools#OpenHelp(<q-args>)
    cnorea <expr> ht getcmdtype()==':'&&getcmdpos()<=3 ? 'tab help':'ht'
    cnorea <expr> h getcmdtype()==':'&&getcmdpos()<=2 ? 'Help':'h'
    cnorea <expr> H getcmdtype()==':'&&getcmdpos()<=2 ? 'Help':'H'
    cnoremap <expr> <Up> getcmdtype()==':'&&getcmdline()=='h' ? '<BS>H<Up>':'<Up>'
    nmap <silent> <expr> K g:inCmdwin? 'viwK' : ":exec
        \ 'Help '.vimtools#HelpTopic()<CR>"
    vnoremap <silent> <expr> K vimtools#OpenHelpVisual()
endif

" {{{2 Cscope configuration
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
" Save/restore unnamed/clipboard registers
func! SaveRegs()
    let s:quotereg = @" | let s:starreg = @* | let s:plusreg = @+
endfunc
func! RestoreRegs()
    let @" = s:quotereg | let @* = s:starreg | let @+ = s:plusreg
endfunc

" Like bufdo but return to starting buffer
func! Bufdo(command, bang)
    let currBuff=bufnr("%")
    if a:bang
        execute 'bufdo set eventignore-=Syntax | ' . a:command
    else
        execute 'bufdo ' . a:command
    endif
    execute 'buffer ' . currBuff
endfunc
command! -nargs=+ -bang -complete=command Bufdo call Bufdo(<q-args>, <bang>0)

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

    " Resize window
    nnoremap <buffer> <C-Up>   <C-w>+
    nnoremap <buffer> <C-Down> <C-w>-

    " Close window
    nnoremap <silent> <buffer> <Leader>w :q<CR>
    nnoremap <silent> <buffer> ZZ :q<CR>
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
command! -nargs=+ -complete=command Redir call Redir(<q-args>)
nnoremap <Leader>r :<C-r>:<Home>Redir <CR>

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

" Cycle search mode between regular, very magic, and very nomagic
func! s:CycleSearchMode()
    let l:cmd = getcmdline()
    let l:pos = getcmdpos()
    if l:cmd =~# '\v^(KeepPatterns [^/]*[sgv]\/)?\\v'
        let l:cmd = substitute(l:cmd,'\v^(KeepPatterns [^/]*[sgv]\/)?\\v','\1\\V','')
    elseif l:cmd =~# '\v^(KeepPatterns [^/]*[sgv]\/)?\\V'
        let l:cmd = substitute(l:cmd,'\v^(KeepPatterns [^/]*[sgv]\/)?\\V','\1','')
        call setcmdpos(l:pos - 2)
    else
        let l:cmd = substitute(l:cmd,'\v^(KeepPatterns [^/]*[sgv]\/)?','\1\\v','')
        call setcmdpos(l:pos + 2)
    endif
    return l:cmd
endfunc
cnoremap <expr> <C-x> getcmdtype() =~ '[/?:]' ?
    \ "\<C-\>e\<SID>CycleSearchMode()\<CR>" : ""

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
        return "\<C-r>+\<F10>".(@+=~"\<NL>$"?"\<BS>":"")
    endif
    return "\<C-r>+"
endfunc
noremap <C-v> "+gP
cnoremap <expr> <C-v> getcmdtype() == '=' ?
    \ "\<C-r>+" : "\<C-r>=substitute(@+, '\\n', '', 'g')\<CR>"
imap <expr> <C-v> <SID>Paste()
exe 'vnoremap <script> <C-v> '.paste#paste_cmd['v']

" Make last search a whole word
func! s:SearchWholeWord(dir)
    let sf = v:searchforward
    if @/[0:1] ==# '\v'
        let @/ = '\v<('.@/[2:].')>'
    elseif @/[0:1] ==# '\V'
        let @/ = '\V\<\('.@/[2:].'\)\>'
    else
        let @/='\<\('.@/.'\)\>'
    endif
    call histadd('/', @/)
    if (a:dir && sf) || (!a:dir && !sf)
        echo '/'.@/ | return '/'."\<CR>"
    else
        echo '?'.@/ | return "?\<CR>"
    endif
endfunc
nn <silent> <expr> <Leader>n <SID>SearchWholeWord(1)
nn <silent> <expr> <Leader>N <SID>SearchWholeWord(0)

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
            return "\<C-u>\\v"
        else
            return "\<C-u>\\V"
        endif
    endif
    return "\<C-w>"
endfunc
cnoremap <expr> <C-w> <SID>SearchCmdDelWord()

" <C-Left> moves cursor after \v
func! s:SearchCtrlLeft()
    if getcmdtype() =~ '[/?]' && getcmdline() =~? '^\\v'
        if strpart(getcmdline(), 0, getcmdpos() - 1) =~ '\v^\S+\s?$'
            return "\<C-Left>\<Right>\<Right>"
        endif
    endif
    return "\<C-Left>"
endfunc
cnoremap <expr> <C-Left> <SID>SearchCtrlLeft()

" Fix up arrow in search history when search starts with \v
func! s:OlderHistory()
    if getcmdtype() =~ '[/?]' && getcmdline() ==? '\v'
        return "\<C-u>\<Up>"
    elseif getcmdtype() == ':' && getcmdline() =~# '\v^.*[sgv]/\\[vV]$'
        return "\<BS>\<BS>\<Up>"
    elseif s:hasvimtools
        return getcmdtype() == ':' && getcmdline() == 'h' ? "\<BS>H\<Up>" : "\<Up>"
    endif
    return "\<Up>"
endfunc
cnoremap <expr> <Up> <SID>OlderHistory()

" Add wildcards to path in command line for zsh-like expansion
func! s:StarifyPath()
    set wildcharm=<C-t>
    let cmdline = getcmdline()
    let space = match(cmdline, '\m^.*\zs\s\ze\S\+$')
    let start = cmdline[0:space]
    let finish = substitute(cmdline[space+1:-1],'[^[:space:]~]\zs/','*/','g')
    return start.finish
endfunc
cnoremap <C-s> <C-\>e<SID>StarifyPath()<CR><C-t><C-d>

" Ring system bell
func! s:Bell()
    let visualbell_save = &visualbell
    set novisualbell
    execute "normal! \<Esc>"
    let &visualbell = visualbell_save
endfunc
autocmd VimrcAutocmds QuickFixCmdPost * call <SID>Bell()

" Setup for single-file C/C++ projects
func! s:SingleFile()
    execute 'setlocal makeprg=make\ -j8\ '.expand('%:r')
    nnoremap <buffer> <S-F5> :execute '!./'.expand('%:r')<CR>
    lcd! %:p:h
endfunc
command! -nargs=0 SingleFile call <SID>SingleFile()

" Use 'very magic' regex by default
func! s:SearchHandleKey(dir)
    echo a:dir.'\v'
    let char = getchar()
    if     char =~ '`$' | let char = '' | endif
    if     char == char2nr("\<CR>")             | return a:dir."\<CR>"
    elseif char == char2nr("\<Esc>")            | return "\<C-l>"
    elseif char == char2nr("\<C-c>")            | return "\<C-l>"
    elseif char == char2nr("\<C-v>")            | return a:dir."\\v\<C-r>+"
    elseif char == char2nr("\<C-x>")            | return a:dir.'\V'
    elseif char == "\<Up>"                      | return a:dir."\<Up>"
    elseif char == char2nr("/") && a:dir == '/' | return '//'
    else
        return a:dir.'\v'.(type(char) == type("") ? char : nr2char(char))
    endif
endfunc
noremap <expr> / <SID>SearchHandleKey('/')
noremap <expr> ? <SID>SearchHandleKey('?')

" Paste in visual mode without overwriting clipboard
func! s:VisualPaste()
    call SaveRegs()
    normal! gvp
    call RestoreRegs()
endfunc
vnoremap <silent> p :<C-u>call <SID>VisualPaste()<CR>
vnoremap <silent> <C-p> :<C-u>call <SID>VisualPaste()<CR>=']
vnoremap <M-p> p
vnoremap <M-P> p=']

" Insert result of visually selected expression
func! s:EvalExpr()
    call SaveRegs()
    return "c\<C-o>:let @\"=substitute(@\",'\\n','','g')\<CR>".
        \ "\<C-r>=\<C-r>\"\<CR>\<Esc>:call RestoreRegs()\<CR>"
endfunc
vnoremap <expr> <silent> <C-e> <SID>EvalExpr()

" Don't overwrite pattern with substitute command
if s:hasvimtools
    command! -nargs=* KeepPatterns call vimtools#KeepPatterns(<q-args>)
    " Complete wildmode with <C-e> if in wildmenu with a trailing slash
    cnoremap <expr> / wildmenumode() && (strridx(getcmdline(),'/')==len(getcmdline())-1) ?
        \ "\<C-e>" : "\<C-\>evimtools#KeepPatternsSubstitute()\<CR>\<Left>\<C-]>\<Right>"
    nnoremap <expr> & ":keeppatterns s/".g:lsub_pat."/".g:lsub_rep
        \ ."\<CR>:silent! call repeat#set('&')\<CR>"
    nnoremap <expr> g& ":keeppatterns s/".g:lsub_pat."/".g:lsub_rep."/"
        \ .g:lsub_flags."\<CR>:silent! call repeat#set('g&')\<CR>"
else
    cnoremap <expr> / wildmenumode() && (strridx(getcmdline(),'/')==len(getcmdline())-1) ?
        \ "\<C-e>" : '/'
endif

" Function abbreviations
if s:hasvimtools
    cnoremap ( <C-\>evimtools#FuncAbbrevs()<CR><Left><C-]><Right>
endif

" Delete until character on command line
func! s:DeleteUntilChar(char)
    let cmdstart = strpart(getcmdline(), 0, getcmdpos() - 1)
    let cmdstart = substitute(cmdstart, '\V'.escape(a:char, '\').'\*\$', '', '')
    let newcmdstart = strpart(cmdstart, 0, strridx(cmdstart, a:char) + 1)
    let end = strpart(getcmdline(), getcmdpos() - 1)
    call setcmdpos(getcmdpos() + len(newcmdstart) - len(cmdstart))
    return newcmdstart.end
endfunc
cnoremap <C-@> <C-\>e<SID>DeleteUntilChar('/')<CR>
inoremap <C-@> <Esc>vT/"_c
cnoremap <M-w> <C-\>e<SID>DeleteUntilChar(' ')<CR>
inoremap <M-w> <Esc>vT<Space>"_c

" Stay at search result without completing search
func! s:QuitSearch()
    if getcmdtype() !~ '[/?]' | return '' | endif
    let visual = mode() =~? "[v\<C-v>]"
    return "\<C-e>\<C-u>\<C-c>:\<C-u>call search('".getcmdline()."', '".
        \ (getcmdtype() == '/' ? '' : 'b')."')\<CR>zv".
        \ (visual ? 'm>gv' : "")
endfunc
cnoremap <silent> <expr> <C-^> <SID>QuitSearch()
cnoremap <silent> <expr> <C-CR> <SID>QuitSearch()

" Unfold at incremental search match
func! s:UnfoldSearch()
    let type = getcmdtype()
    if type !~ '[/?]' | return '' | endif
    let visual = mode() =~? "[v\<C-v>]"
    let cmd = getcmdline()
    return "\<C-c>:\<C-u>let unfoldview = winsaveview()\<CR>"
        \ .":call search('".cmd."', '".(type == '/' ? '' : 'b')."')\<CR>zv"
        \ .":call winrestview(unfoldview)\<CR>:unlet unfoldview\<CR>zv"
        \ .":call feedkeys('".(visual ? 'gv' : '')
        \ .type."\<C-v>\<C-u>".cmd."', 't')\<CR>"
endfunc
cnoremap <silent> <expr> <C-o> <SID>UnfoldSearch()

" Search without saving when in command line window
func! s:SearchWithoutSave()
    let @/ = getcmdline()
    return ''
endfunc
augroup VimrcAutocmds
    autocmd CmdwinEnter * if expand('<afile>') =~ '[/?]' |
        \     execute 'cnoremap <expr> <CR> getcmdtype() =~ "[/?]" ?
        \         "\<C-\>e<SID>SearchWithoutSave()\<CR>\<CR>" : "\<C-]>\<CR>"' |
        \ endif
    autocmd CmdwinLeave * silent! cunmap <CR>
augroup END

" Print number of occurrences of last search without moving cursor
func! s:PrintCount()
    let l:view = winsaveview() | let l:gd = &gdefault | set nogdefault
    redir => l:cnt | keepjumps silent %s///gne | redir END
    keepjumps call winrestview(l:view)
    echo l:cnt =~ 'match' ? substitute(l:cnt,'\n','','') : 'No matches'
    let &gdefault = l:gd
endfunc
nn <silent> <M-n> :call <SID>PrintCount()<CR>
vn <silent> <M-n> :<C-u>call <SID>PrintCount()<CR>

" Put spaces around a character/visual selection
func! s:SpacesAround(visual)
    call SaveRegs()
    execute "normal! ".(a:visual ? "gv" : "")."s \<C-r>\" \<Esc>h"
    call RestoreRegs()
    silent! call repeat#set("g\<Space>")
endfunc
nn <silent> g<Space> :<C-u>call <SID>SpacesAround(0)<CR>
vn <silent> g<Space> :<C-u>call <SID>SpacesAround(1)<CR>

" Show human-readable timestamp in zsh history file
func! s:EchoHistTime()
    let line = getline(search('^:\s*\d*:', 'bcnW')) | if !len(line) | return | endif
    redraw | let fmt = len($DATEFMT) ? $DATEFMT : '%a %d%b%y %T'
    echo strftime(fmt, line[2:11])
endfunc
autocmd VimrcAutocmds CursorMoved $HOME/.histfile call <SID>EchoHistTime()

" {{{2 GUI configuration
if has('gui_running')
    " Disable most visible GUI features
    set guioptions=eAc

    if hasWin
        " Set font for gVim
        if hostname() ==? 'Jake-Desktop'
            " Big font for big TV
            set guifont=DejaVu_Sans_Mono_for_Powerline:h11:cANSI
        else
            set guifont=DejaVu_Sans_Mono_for_Powerline:h9:cANSI
        endif
    elseif hasMac
        " Set font for MacVim
        set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h12

        " Start in fullscreen mode
        autocmd VimrcAutocmds VimEnter * sil! set fullscreen
    else
        " Use text-only tabline (prevent resizing issues)
        set guioptions-=e

        " Set font for gVim
        set guifont=Source\ Code\ Pro\ for\ Powerline\ Medium\ 9
    endif
else
    " Make control + arrow keys work in terminal
    exec "set <F13>=\<Esc>[1;5A <F14>=\<Esc>[1;5B"
    exec "set <C-Right>=\<Esc>[1;5C <C-Left>=\<Esc>[1;5D"
    map <F13> <C-Up>
    map <F14> <C-Down>
    map! <F13> <C-Up>
    map! <F14> <C-Down>

    " Make alt + arrow keys work in terminal
    exec "set <F17>=\<Esc>[1;3A <F18>=\<Esc>[1;3B"
    exec "set <F19>=\<Esc>[1;3C <F20>=\<Esc>[1;3D"
    map <F17> <M-Up>
    map <F18> <M-Down>
    map <F19> <M-Right>
    map <F20> <M-Left>
    map! <F17> <M-Up>
    map! <F18> <M-Down>
    map! <F19> <M-Right>
    map! <F20> <M-Left>

    " Shifted function key codes
    exe "set <S-F1>=\e[25~"    | exe "set <S-F2>=\e[26~"
    exe "set <S-F3>=\e[28~"    | exe "set <S-F4>=\e[29~"
    exe "set <S-F5>=\e[31~"    | exe "set <S-F6>=\e[32~"
    exe "set <S-F7>=\e[33~"    | exe "set <S-F8>=\e[34~"
    exe "set <S-F9>=\e[20;2~"  | exe "set <S-F10>=\e[21;2~"
    exe "set <S-F11>=\e[23;2~" | exe "set <S-F12>=\e[24;2~"

    " Change tab in XTerm
    "         <C-Tab>              <C-S-Tab>
    exec "set <F15>=\<Esc>[27;5;9~ <F16>=\<Esc>[27;6;9~"

    " Use correct background color
    autocmd VimrcAutocmds VimEnter * set t_ut=

    " Use block cursor in normal mode and bar cursor in insert mode
    let &t_SI = "\<Esc>[5 q"
    let &t_EI = "\<Esc>[1 q"

    " Enable mouse for scrolling and window selection
    set mouse=nir
    noremap <F22> <NOP>
    noremap <F21> <LeftMouse>
    for b in ["Left","Middle","Right"] | for m in ["","2","3","4","C","S","A"]
        execute 'map <'.m.(strlen(m)?'-':'').b.'Mouse> <NOP>'
    endfor | endfor | map <expr> <LeftMouse> winnr('$')>1?"\<F21>":"\<F22>"
endif

" }}}2

" Create new buffer with filetype as (optional) argument
command! -nargs=? New     new     | set filetype=<args>
command! -nargs=? Enew    enew    | set filetype=<args>
command! -nargs=? Vnew    vnew    | set filetype=<args>
command! -nargs=? Tabedit tabedit | set filetype=<args>

" Increase time allowed for keycode mappings over SSH
if mobileSSH
    set ttimeoutlen=250
elseif hasSSH
    set ttimeoutlen=100
endif

augroup VimrcAutocmds
    " Don't auto comment new line made with 'o', 'O', or <CR>
    autocmd FileType * exe "set fo-=o" | exe "set fo-=r"

    " Use line wrapping for plain text files (but not help files)
    autocmd FileType text setl wrap linebreak
    autocmd FileType help setl nowrap nolinebreak concealcursor=

    " Indent line continuation for conf files
    autocmd FileType conf setl indentexpr=getline(v:lnum-1)=~'\\\\$'?&sw:0

    " Prefer single-line style comments and fix shell script comments
    autocmd FileType cpp,arduino setl commentstring=//%s
    autocmd FileType python,crontab setl commentstring=#%s
    autocmd FileType * if &cms=='# %s' | setl cms=#%s | endif
    autocmd FileType dosbatch setl commentstring=REM%s
    autocmd FileType autohotkey setl commentstring=;%s

    " Highlight current line in active window but not in insert mode
    autocmd BufRead,BufNewFile,VimEnter * set cul
    autocmd InsertLeave,WinEnter,FocusGained * set cul
    autocmd InsertEnter,WinLeave,FocusLost * set nocul

    " Disable paste mode after leaving insert mode
    autocmd InsertLeave * set nopaste

    " Open quickfix window automatically if not empty
    autocmd QuickFixCmdPost * cwindow |
        \ if substitute(system('< $HOME/.exit'), '\d\+', '&', '') != 0 |
        \     redraw! | echohl ErrorMsg | echomsg "Shell command failed" | echohl None |
        \ endif | call system('[[ -f $HOME/.exit ]] && command rm $HOME/.exit')

    " Always make quickfix full-width on the bottom
    autocmd FileType qf wincmd J

    " Use to check if inside command window
    au VimEnter,CmdwinLeave * let g:inCmdwin=0
    au CmdwinEnter * let g:inCmdwin=1 | let g:cmdwinType = expand('<afile>')
    au CmdwinEnter * call <SID>CmdwinMappings()

    " Enforce cmdwinheight when quickfix window is open
    au CmdwinEnter * if winheight(0) > &cmdwinheight | exe "norm! "
        \ .&cmdwinheight."\<C-w>_" | endif

    " Restore cursor position and open fold after loading a file
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \     exe "normal! g`\"" | let b:do_unfold = 1 |
        \ endif
    autocmd BufWinEnter * if exists('b:do_unfold') |
        \ exe "normal! zv" | unlet b:do_unfold | endif
    autocmd VimEnter * silent! normal! zv

    " Load files with mixed line endings as DOS format
    autocmd BufReadPost * nested
        \ if !exists('b:reload_dos') && !&binary && &ff == 'unix'
        \       && (0 < search('\r$', 'nc')) && &buftype == ''
        \       && expand('<afile>') !~? '\v\.(diff|rej|patch)$' |
        \     let b:reload_dos = 1 |
        \     e ++ff=dos |
        \ endif

    " Fix help buftype after loading session
    autocmd SessionLoadPost *.txt if &filetype == 'help' | set buftype=help | endif

    " showcmd causes Vim to start in replace mode sometimes
    autocmd VimEnter * set showcmd

    " Set global variable on FocusLost
    autocmd FocusLost * let g:focuslost = 1 | silent! AirlineRefresh
    autocmd FocusGained,CursorMoved,CursorMovedI *
        \ if exists('g:focuslost') |
        \     unlet g:focuslost | silent! execute "AirlineRefresh" |
        \ endif

    " Save position of last text change
    autocmd TextChanged,TextChangedI *
        \ if &buflisted && &buftype == '' |
        \     let g:last_change_buf = bufnr('%') |
        \ endif

    " Jump to quickfix result in previous window
    autocmd FileType qf nn <silent> <buffer> <CR> :execute "wincmd p \| "
        \ .line('.').(w:quickfix_title =~ "loc.*list" ? "ll" : "cc")<CR>zv

    " Open files as read-only automatically
    autocmd SwapExists * let v:swapchoice = 'o'
augroup END

" Define some useful constants
let pi = acos(-1.0)
let d2r = pi / 180.0
let r2d = 180.0 / pi
let ft2m = 0.3048
let m2ft = 1.0 / ft2m
let ft2km = ft2m / 1000.0
let km2ft = 1.0 / ft2km
let grav = 9.80665
let kg2lb = 2.20462
let lb2kg = 0.453592
let mi2km = ft2m * 5280.0 / 1000.0
let km2mi = 1.0 / mi2km
let nmi2km = 1.852
let km2nmi = 1.0 / nmi2km
let slug2kg = 14.5939029
let kg2slug = 1.0 / slug2kg
let amps = 340.29
let afps = amps * m2ft
let assignments_pattern = '\v[=!]@<![+|&^]?\=[=~]@!'

" Abbreviation template
func! s:CreateAbbrev(lhs, rhs, cmdtype, ...)
    if a:0
        execute 'cnoreabbrev <expr> '.a:lhs.' getcmdtype() =~ "['.a:cmdtype
            \ .']" && getcmdline() == '''.a:1.a:lhs.''' ? "'.a:rhs.'" : "'.a:lhs.'"'
    else
        execute 'cnoreabbrev <expr> '.a:lhs.' getcmdtype() =~ "['.a:cmdtype
            \ .']" && getcmdpos() <= '.(len(a:lhs) + 1).' ? "'.a:rhs.'" : "'.a:lhs.'"'
    endif
endfunc
let ls_sort = has('mac') ? ' --sort=none' : ''
call <SID>CreateAbbrev('ve',   'verbose',                         ':'   )
call <SID>CreateAbbrev('so',   'source',                          ':'   )
call <SID>CreateAbbrev('ec',   'echo',                            ':@>' )
call <SID>CreateAbbrev('dt',   'diffthis',                        ':'   )
call <SID>CreateAbbrev('do',   'diffoff \| set nowrap',           ':'   )
call <SID>CreateAbbrev('du',   'diffupdate',                      ':'   )
call <SID>CreateAbbrev('vd',   'vertical diffsplit',              ':'   )
call <SID>CreateAbbrev('wi',   'windo',                           ':'   )
call <SID>CreateAbbrev('ca',   'call',                            ':'   )
call <SID>CreateAbbrev('pp',   'PP',                              '>'   )
call <SID>CreateAbbrev('csa',  'cscope add',                      ':'   )
call <SID>CreateAbbrev('csf',  'cscope find',                     ':'   )
call <SID>CreateAbbrev('csk',  'cscope kill -1',                  ':'   )
call <SID>CreateAbbrev('csr',  'cscope reset',                    ':'   )
call <SID>CreateAbbrev('css',  'cscope show',                     ':'   )
call <SID>CreateAbbrev('csh',  'cscope help',                     ':'   )
call <SID>CreateAbbrev('l',    'ls -h --color=auto'.ls_sort,      ':',  '!')
call <SID>CreateAbbrev('ls',   'ls -h --color=auto'.ls_sort,      ':',  '!')
call <SID>CreateAbbrev('ll',   'ls -lsh --color=auto'.ls_sort,    ':',  '!')
call <SID>CreateAbbrev('lls',  'ls -lshrt --color=auto'.ls_sort,  ':',  '!')
call <SID>CreateAbbrev('lla',  'ls -lshA --color=auto'.ls_sort,   ':',  '!')
call <SID>CreateAbbrev('llas', 'ls -lshrtA --color=auto'.ls_sort, ':',  '!')

" Other abbreviations
let g:global_command_pattern = '\v\C^[^/]*v?g%[lobal]!?/([^/]|\\@<=/)*\\@<!/'
cnoreabbrev <expr> ex (getcmdtype()==':'&&getcmdpos()<=3)
    \ \|\| (getcmdline() =~ g:global_command_pattern.'ex$') ? 'execute':'ex'
cnoreabbrev <expr> no (getcmdtype()==':'&&getcmdpos()<=3)
    \ \|\| (getcmdline() =~ g:global_command_pattern.'no$') ? 'normal':'no'

" Don't clobber registers from select mode
snoremap <Space> <C-g>"_c<Space>
snoremap \| <C-g>"_c\|
for c in range(33, 124) + [126]
    execute "snoremap ".escape(nr2char(c), '|')." <C-g>\"_c".escape(nr2char(c), '|')
endfor

" {{{1 Plugin configuration

" Make empty list of disabled plugins
if !exists('g:pathogen_disabled')
    let g:pathogen_disabled=[]
endif

" Only enable misc/shell in Windows
if !hasWin | call extend(g:pathogen_disabled, ['misc','shell']) | endif

" Disable some plugins if in read-only mode
if s:readonly
    call add(g:pathogen_disabled, 'neocomplete')
    call add(g:pathogen_disabled, 'neosnippet-snippets')
    call add(g:pathogen_disabled, 'syntastic')
    call add(g:pathogen_disabled, 'tabular')
    call add(g:pathogen_disabled, 'targets')
    call add(g:pathogen_disabled, 'unite')
    call add(g:pathogen_disabled, 'vimfiler')
endif

" Airline configuration
let g:airline_theme='solarized'
au VimrcAutocmds TabEnter,FocusGained *
    \ silent! call airline#highlighter#highlight(['normal',&mod?'modified':''])
nnoremap <silent> <M-w> :AirlineToggleWhitespace<CR>:AirlineRefresh<CR>
let g:airline#extensions#whitespace#show_message=0
let g:airline_section_y='%{&fileformat}'

" Use powerline font unless in Mac SSH session or in old Vim
if mobileSSH || v:version < 703
    let g:airline_powerline_fonts=0
    let g:airline_left_sep=''
    let g:airline_right_sep=''
else
    let g:airline_powerline_fonts=1
endif

" Shortcut to force close buffer without closing window
nnoremap <silent> <Leader><Leader>bd :Bclose!<CR>

" Tagbar configuration
nnoremap <silent> <Leader>t :TagbarToggle<CR>
let g:tagbar_iconchars=['▶','▼']
let g:tagbar_sort=0
let g:tagbar_autofocus=1
let g:tagbar_map_showproto='r'

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr=1
let OmniCpp_MayCompleteScope=1
autocmd VimrcAutocmds CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif

" Commentary configuration
let g:commentary_map_backslash=0

" {{{2 Completion settings
if has('lua') && $VIMBLACKLIST !~? 'neocomplete'
    call add(g:pathogen_disabled, 'supertab')

    if !s:readonly
        " NeoComplete settings
        let g:neocomplete#enable_at_startup=1
        let g:neocomplete#enable_smart_case=1
        let g:neocomplete#max_list=200
        let g:neocomplete#min_keyword_length=4
        let g:neocomplete#enable_refresh_always=1
        let g:neocomplete#sources#buffer#cache_limit_size=3000000
        let g:tmuxcomplete#trigger=''
        if !exists('g:neocomplete#keyword_patterns')
            let g:neocomplete#keyword_patterns = {}
        endif
        let g:neocomplete#keyword_patterns.matlab =
            \ '\h\w*\(\(\.\((''\?\)\?\w*\('')\?\)\?\)\+'
            \ .'\|{\d\+}\(\.\((''\?\)\?\w*\('')\?\)\?\)\+'
            \ .'\|{\d*\}\?\)\?'
        if !exists('g:neocomplete#sources')
            let g:neocomplete#sources = {}
        endif
        let g:neocomplete#sources._ = ['file/include', 'member', 'buffer',
            \ 'syntax', 'include', 'neosnippet', 'omni']
        let g:neocomplete#sources.matlab = ['file/include', 'member', 'buffer',
            \ 'syntax', 'include', 'neosnippet', 'omni', 'matlab-complete']
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
        inoremap <expr> <C-e>   pumvisible() ? neocomplete#close_popup()
            \ : matchstr(getline(line('.')+1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')
        imap     <expr> <C-d>   neosnippet#expandable_or_jumpable()?
            \ "\<Plug>(neosnippet_expand_or_jump)":
            \ (pumvisible() ? neocomplete#close_popup() : "\<C-d>")
        smap <C-d> <Plug>(neosnippet_expand_or_jump)
        inoremap <expr> <C-f>   neocomplete#cancel_popup()
        inoremap <expr> <C-l>   neocomplete#complete_common_string()
        augroup VimrcAutocmds
            autocmd CmdwinEnter * inoremap <buffer> <expr> <Tab>
                \ pumvisible() ? "\<C-n>" : neocomplete#start_manual_complete()
            autocmd CmdwinEnter * inoremap <buffer> <expr> <S-Tab>
                \ pumvisible() ? "\<C-p>" : neocomplete#start_manual_complete()
            autocmd VimrcAutocmds CmdwinEnter : let b:neocomplete_sources=['vim', 'file']
            autocmd InsertLeave * if &ft=='vim' | sil! exe 'NeoCompleteVimMakeCache' | en
        augroup END
    endif
else
    call add(g:pathogen_disabled, 'neocomplete')
    let g:SuperTabDefaultCompletionType="context"
    imap <C-d> <Plug>(neosnippet_expand_or_jump)
    smap <C-d> <Plug>(neosnippet_expand_or_jump)
    silent! set shortmess+=c
endif

" {{{2 Sneak settings
let g:sneak#streak=1
let g:sneak#use_ic_scs=1
autocmd VimrcAutocmds ColorScheme * call <SID>SneakHighlights()
func! s:SneakHighlights()
    let fg = &background == 'dark' ? 8 : 15 | let gui = 'gui=reverse guifg=#'
    execute "highlight! SneakPluginTarget ctermfg=".fg." ctermbg=4 ".gui."268bd2"
    execute "highlight! SneakStreakTarget ctermfg=".fg." ctermbg=2 ".gui."859900"
    execute "highlight! SneakStreakCursor ctermfg=".fg." ctermbg=1 ".gui."dc322f"
    highlight! link SneakStreakMask Normal
    highlight! link SneakStreakStatusLine StatusLine
endfunc
func! s:SneakMaps()
    if exists('g:loaded_sneak_plugin')
        for mode in ['n', 'x', 'o']
            for l in ['f', 't']
                execute mode.'map '.l.' <Plug>Sneak_'.l
                execute mode.'map '.toupper(l).' <Plug>Sneak_'.toupper(l)
            endfor
            execute mode.'map <Space>   <Plug>Sneak_s'
            execute mode.'map <C-Space> <Plug>Sneak_S'
            execute mode.'map <C-@>     <Plug>Sneak_S'
            execute mode.'map ,, <Plug>SneakPrevious'
        endfor
        nnoremap <silent> <C-l> :sil! call sneak#cancel()<CR>:nohl<CR><C-l>
    endif
endfunc
autocmd VimrcAutocmds VimEnter * call <SID>SneakMaps()
call <SID>SneakMaps()

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
let g:vimfiler_ignore_pattern='^\.\|\.[do]$'
autocmd VimrcAutocmds FileType vimfiler call s:VimfilerSettings()
func! s:VimfilerSettings()
    nmap <buffer> m     <Plug>(vimfiler_toggle_mark_current_line)
    nmap <buffer> <M-m> <Plug>(vimfiler_move_file)
    nmap <buffer> e     <Plug>(vimfiler_execute)
    nmap <buffer> <BS>  <Plug>(vimfiler_close)
    nmap <buffer> -     <Plug>(vimfiler_switch_to_parent_directory)
    nmap <buffer> <F1>  <Plug>(vimfiler_help)
    nmap <buffer> <expr> <CR> vimfiler#smart_cursor_map(
        \"\<Plug>(vimfiler_expand_tree)","\<Plug>(vimfiler_edit_file)")
    nmap <buffer> D     <Plug>(vimfiler_delete_file)
    nmap <buffer> <C-s> <Plug>(vimfiler_select_sort_type)
    nmap <buffer> S     <Plug>(vimfiler_select_sort_type)
    nmap <buffer> <Tab> <Plug>(vimfiler_choose_action)
    nmap <buffer> gN    <Plug>(vimfiler_new_file)
    exe "nunmap <buffer> <Space>" | exe "nunmap <buffer> L" | exe "nunmap <buffer> M"
    exe "nunmap <buffer> H" | exe "nunmap <buffer> <S-Space>" | exe "nunmap <buffer> ?"
    exe "nunmap <buffer> N"
endfunc

" {{{2 Unite settings
let g:unite_source_history_yank_enable=1
let g:unite_source_history_yank_limit=500
let g:unite_split_rule='botright'
let g:unite_marked_icon='✓'
let g:unite_cursor_line_highlight='CursorLine'
if executable('ag')
    let g:unite_source_grep_command='ag'
    let g:unite_source_grep_default_opts='--nogroup --nocolor --column -S'
    let g:unite_source_grep_recursive_opt=''
endif
let g:unite_source_grep_search_word_highlight='WarningMsg'
let g:unite_source_history_yank_save_clipboard=1
augroup VimrcAutocmds
    autocmd VimEnter * if exists(':Unite') | call <SID>UniteSetup() | endif
    autocmd FileType unite call <SID>UniteSettings()
    autocmd CursorHold * silent! call unite#sources#history_yank#_append()
augroup END
func! s:UniteSettings()
    setlocal conceallevel=0
    autocmd CursorMoved,CursorMovedI,BufEnter <buffer>
        \ if exists('b:match') |
        \     silent! call matchdelete(b:match) |
        \ endif |
        \ let b:match = matchadd('Search', (@/=~#'\\\@<!\u'?"":'\c').@/, 9999)
    imap <silent> <buffer> <expr> <C-q> unite#do_action('delete')
        \."\<Plug>(unite_append_enter)"
    nnor <silent> <buffer> <expr> <C-q> unite#do_action('delete')
    inor <silent> <buffer> <expr> <C-s>= unite#do_action('split')
    nnor <silent> <buffer> <expr> <C-s>= unite#do_action('split')
    inor <silent> <buffer> <expr> <C-s>" unite#do_action('vsplit')
    nnor <silent> <buffer> <expr> <C-s>" unite#do_action('vsplit')
    imap <silent> <buffer> <expr> <C-d> <SID>UniteTogglePathSearch()."\<Esc>"
        \.'gg3\|"+YQ'.":\<C-u>Unite -buffer-name=buffers/neomru "
        \."-prompt-direction=top -unique buffer neomru/file\<CR>"."\<C-r>+"
    nmap <buffer> <expr> yy unite#do_action('yank').'<Plug>(unite_exit)'
    imap <buffer> <expr> <C-o>v     unite#do_action('vsplit')
    imap <buffer> <expr> <C-o><C-v> unite#do_action('vsplit')
    imap <buffer> <expr> <C-o>s     unite#do_action('split')
    imap <buffer> <expr> <C-o><C-s> unite#do_action('split')
    imap <buffer> <expr> <C-o>t     unite#do_action('tabopen')
    imap <buffer> <expr> <C-o><C-t> unite#do_action('tabopen')
    imap <buffer> <expr> <C-o>d     unite#do_action('tabdrop')
    imap <buffer> <expr> <C-o><C-d> unite#do_action('tabdrop')
    imap <buffer> <expr> <C-o>o     unite#do_action('view')
    imap <buffer> <expr> <C-o><C-o> unite#do_action('view')
    imap <buffer> <expr> <C-o>r     unite#do_action('open')
    imap <buffer> <expr> <C-o><C-r> unite#do_action('open')
    nmap <buffer> <expr> ` b:unite['profile_name'] == 'source/grep'
        \ ? ':call <SID>LastActiveWindow()<CR>'
        \ : '<Plug>(unite_exit)'
    imap <buffer> <expr> ` '<Plug>(unite_exit)'
    imap <buffer> <C-o> <Plug>(unite_choose_action)
    nmap <buffer> <C-o> <Plug>(unite_choose_action)
    inor <buffer> <C-f> <Esc><C-d>
    inor <buffer> <C-b> <Esc><C-u>
    nmap <buffer> <C-f> <C-d>
    nmap <buffer> <C-b> <C-u>
    nmap <buffer> <C-p> <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-j> <Plug>(unite_select_next_line)
    imap <buffer> <C-k> <Plug>(unite_select_previous_line)
    nmap <buffer> <C-c> <Plug>(unite_exit)
    imap <buffer> <C-c> <Plug>(unite_exit)
    nmap <buffer> m <Plug>(unite_toggle_mark_current_candidate)
    nmap <buffer> M <Plug>(unite_toggle_mark_current_candidate_up)
    nmap <buffer> <F1>  <Plug>(unite_quick_help)
    imap <buffer> <F1>  <Esc><Plug>(unite_quick_help)
    nmap <buffer>  S A<C-u>
    imap <buffer> <C-Space> <Plug>(unite_toggle_mark_current_candidate)
    imap <buffer> <C-@> <Plug>(unite_toggle_mark_current_candidate)
    imap <buffer> <C-n> <Esc><Plug>(unite_rotate_next_source)<Plug>(unite_insert_enter)
    inor <buffer> . \.
    inor <buffer> \. .
    sil! nunmap <buffer> ?
endfunc
nn <silent> "" :<C-u>Unite -prompt-direction=top history/yank<CR>
nn <silent> "' :<C-u>Unite -prompt-direction=top register<CR>
nn <silent> <expr> ,a ":\<C-u>Unite -prompt-direction=top "
    \."-no-quit -auto-resize grep:".getcwd()."\<CR>"
nn ,<C-a> :<C-u>Unite -prompt-direction=top -no-quit -auto-resize grep:
com! -nargs=? -complete=file BookmarkAdd call unite#sources#bookmark#_append(<q-args>)
nn <silent> ,b :<C-u>Unite -prompt-direction=top bookmark<CR>
nn <silent> ,vr :Unite -prompt-direction=top -no-quit vimgrep:**/*<CR>
nn <silent> ,vn :Unite -prompt-direction=top -no-quit vimgrep:**<CR>
nn <silent> <C-n> :<C-u>Unite -prompt-direction=top -buffer-name=files file_rec/async<CR>
nn <silent> <C-h> :<C-u>Unite -prompt-direction=top -buffer-name=buffers buffer<CR>
nn <silent> g<C-h> :<C-u>Unite -prompt-direction=top -buffer-name=buffers buffer:+<CR>
nn <silent> <expr> <C-p> ":\<C-u>Unite -prompt-direction=top -buffer-name="
    \ .(len(filter(range(1,bufnr('$')),'buflisted(v:val)')) > 1
    \ ? "buffers/" : "")."neomru ".(len(filter(range(1,bufnr('$')),
    \ 'buflisted(v:val)')) > 1 ? "buffer" : "")." -unique neomru/file\<CR>"
nn <silent> <M-p> :<C-u>Unite -prompt-direction=top neomru/directory<CR>
nn <silent> g<C-p> :<C-u>Unite -prompt-direction=top -buffer-name=neomru neomru/file<CR>
nn <silent> <F1> :<C-u>Unite -prompt-direction=top mapping<CR>
nnoremap <silent> <Leader>w :ccl\|lcl\|winc z\|sil! UniteClose<CR>
nnoremap <silent> ,u :UniteResume<CR>
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
func! s:UniteSetup()
    call unite#filters#matcher_default#use(['matcher_regexp'])
    call unite#custom#default_action('directory', 'cd')
    call unite#custom#profile('default', 'context', {'start_insert': 1})
    for source in ['history/yank', 'register', 'grep', 'vimgrep']
        call unite#custom#profile('source/'.source, 'context', {'start_insert': 0})
    endfor
endfunc

" Use Unite's MRU list for alternate buffer key
func! UniteAlternateBuffer(count)
    let buf = bufnr('%')
    if !exists(':Unite') || (a:count == 1 && buflisted(bufnr('#')))
        try | execute "normal! \<C-^>" | catch | endtry
    else
        let buflist = unite#sources#buffer#get_unite_buffer_list()
        if exists('buflist['.(a:count-1).']')
            execute "buffer ".buflist[(a:count-1)]['action__buffer_nr']
        elseif exists("buflist[-2]")
            execute "buffer ".buflist[-2]['action__buffer_nr']
        else
            execute "normal! \<C-^>"
        endif
    endif
    execute "normal! zv"
    if bufnr('%') == buf | echo "No alternate buffer" | endif
endfunc
nnoremap <silent> <C-^> :<C-u>call UniteAlternateBuffer(v:count1)<CR>

" Cycle through Unite's MRU list
func! UniteBufferCycle(resume)
    if a:resume && !exists('s:buflist')
        call feedkeys("\<C-^>") | return
    endif
    let s:UBCActive = 1
    if !a:resume
        let s:buflist = unite#sources#buffer#get_unite_buffer_list()
        let s:bufnr = -2
        let s:startbuf = bufnr('%')
        let s:startaltbuf = bufnr('#')
    endif
    let s:key = '['
    while s:key == '[' || s:key == ']'
        if s:bufnr == -2
            let s:key = ']'
            let s:bufnr = -1
        endif
        let s:bufnr = s:bufnr + (s:key == ']' ? 1 : -1)
        if s:bufnr >= -1 && s:bufnr < len(s:buflist) - 1
            execute "buffer ".s:buflist[s:bufnr]['action__buffer_nr']
            redraw
            let s = ''
            if s:bufnr >= 0
                let s .= 'Previous: "'.fnamemodify(bufname(
                    \ s:buflist[s:bufnr-1]['action__buffer_nr']), ':t').'" '
            endif
            if s:bufnr < len(s:buflist) - 2
                let s .= 'Next: "'.fnamemodify(bufname(
                    \ s:buflist[s:bufnr+1]['action__buffer_nr']), ':t').'"'
            endif
            echo s
        else
            let s:bufnr = s:bufnr - (s:key == ']' ? 1 : -1)
        endif
        let s:key = nr2char(getchar())
    endwhile
    let s:UBCActive = 0
    if index(['q', 'Q', "\<C-c>", "\<CR>", "\<Esc>"], s:key) < 0
        call feedkeys(s:key)
    endif
    if bufnr('%') != s:startbuf
        execute "buffer ".s:startbuf
    else
        execute "buffer ".s:startaltbuf
    endif
    buffer #
endfunc
nnoremap <silent> ]r :<C-u>call UniteBufferCycle(0)<CR>
nnoremap <silent> [r :<C-u>call UniteBufferCycle(1)<CR>
let s:UBCActive = 0
autocmd VimrcAutocmds BufEnter * if !s:UBCActive | sil! unlet s:buflist | endif

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
nnoremap <silent> ds<Space> F<Space>"_x,"_x:silent! call repeat#set('ds ')<CR>

" Syntastic settings
let g:syntastic_filetype_map={'arduino': 'cpp'}
let g:syntastic_mode_map={'mode': 'passive', 'active_filetypes': [], 'passive_filetypes': []}
let g:airline#extensions#syntastic#enabled=0
nnoremap ,sc :<C-u>execute "SyntasticCheck" \| execute "Errors" \| lfirst<CR>

" Tabular settings
let g:no_default_tabular_maps=1

" Indent Guides settings
let g:indent_guides_auto_colors=0
nmap <silent> <Leader>i <Plug>IndentGuidesToggle

" Ack settings
if executable('ag') | let g:ackprg='ag --nogroup --nocolor --column -S' | endif
let g:ack_autofold_results=0
let g:ack_apply_lmappings=0
let g:ack_apply_qmappings=0
cnoreabbrev <expr> A getcmdtype() == ':' && getcmdpos() <= 2 ? 'Ack!' : 'A'
cnoreabbrev <expr> a getcmdtype() == ':' && getcmdpos() <= 2 ? 'Ack!' : 'a'
func! s:AckCurrentSearch(ic)
    let view = winsaveview() | call SaveRegs()
    keepjumps normal gny
    call winrestview(view)
    if a:ic == 0 | let cmd = "Ack! -s ".g:ag_flags." -- '".@"."'" | else
        if @/ =~ '\u'
            let cmd = "Ack! ".g:ag_flags." -- '".@"."'"
        else
            let cmd = "Ack! ".g:ag_flags." -- '".tolower(@")."'"
        endif
    endif
    let cmd = escape(cmd, '%#')
    execute cmd | call histadd(':', cmd) | cwindow
    if &buftype == 'quickfix' | execute "normal! gg" | endif
    call RestoreRegs()
endfunc
nnoremap <silent> ga :<C-u>call <SID>AckCurrentSearch(1)<CR>
nnoremap <silent> gA :<C-u>call <SID>AckCurrentSearch(0)<CR>
if !exists('g:ag_flags') | let g:ag_flags = '' | endif

" tmux navigator settings
let g:tmux_navigator_no_mappings=1
nnoremap <silent> <M-Left>  :TmuxNavigateLeft<CR>
nnoremap <silent> <M-Down>  :TmuxNavigateDown<CR>
nnoremap <silent> <M-Up>    :TmuxNavigateUp<CR>
nnoremap <silent> <M-Right> :TmuxNavigateRight<CR>

" Vimux settings
nnoremap <Leader>vo :call VimuxOpenRunner()<CR>
nnoremap <silent> <Leader>: :VimuxPromptCommand<CR>
nnoremap <silent> @\ :<C-u>VimuxRunLastCommand<CR>
nnoremap <silent> @\| :<C-u>VimuxRunLastCommand<CR>
nnoremap <silent> g\| :VimuxPromptCommand<CR><C-f>
nnoremap <silent> g\ :VimuxPromptCommand<CR><C-f>
nnoremap <silent> <Leader>bb :call
    \ VimuxRunCommand('break '.expand('%:t').':'.line('.'))<CR>
nnoremap <silent> <Leader>bc :call
    \ VimuxRunCommand('clear '.expand('%:t').':'.line('.'))<CR>
let g:VimuxRunnerType = 'pane'
command! -nargs=0 VimuxToggleRunnerType let g:VimuxRunnerType =
    \ g:VimuxRunnerType == 'pane' ? 'window' : 'pane' | echo g:VimuxRunnerType

" Targets settings
let g:targets_aiAI = 'ai  '
let g:targets_nlNL = '    '
let g:targets_pairs = ''
let g:targets_quotes = ''

" fuzzyfinder settings
set runtimepath+=~/.fzf
nnoremap <silent> <M-f> :FZF<CR>

" eunuch settings
cnoreabbrev <expr> loc getcmdtype() == ':' && getcmdpos() <= 4 ?
    \ 'Locate! --regex' : 'loc'

" vimtools functions
command! -nargs=? -complete=dir Tree call vimtools#Tree(<f-args>)
command! -nargs=0 FollowedBy call vimtools#FollowedBy(0)
command! -nargs=0 NotFollowedBy call vimtools#FollowedBy(1)
command! -nargs=0 PrecededBy call vimtools#PrecededBy(0)
command! -nargs=0 NotPrecededBy call vimtools#PrecededBy(1)
autocmd VimrcAutocmds FileType c,cpp,*sh call vimtools#SectionJumpMaps()
nnoremap <silent> g= :call vimtools#MakeParagraph()<CR>

" python-mode settings
let g:pymode_options = 0
let g:pymode_lint_on_write = 0
let g:pymode_breakpoint_cmd = "import clewn.vim as vim\rvim.pdb()"
let g:pymode_trim_whitespaces = 0
let g:pymode_run_bind = ',r'
let g:pymode_breakpoint_bind = '<Leader>bb'
let g:pymode_doc = 0
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_lint_ignore = "E501,E302"

" VCSCommand settings
let VCSCommandCVSExec = ''
let VCSCommandBZRExec = ''
let VCSCommandSVKExec = ''

" jedi settings
autocmd VimrcAutocmds FileType python setlocal omnifunc=jedi#completions
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_select_first = 0
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#goto_definitions_command = '<Leader>jd'
if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.python =
    \ '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'

" DirDiff settings
let g:DirDiffExcludes = '.*.un~,.svn,.git,.hg,'.&wildignore

" Import scripts
execute pathogen#infect()

" Add current directory and red arrow if ignorecase is not set to status line
sil! call airline#parts#define('ic',{'condition': '!\&ic',
    \'text': nr2char(8593),'accent': 'red'})
sil! let g:airline_section_b = airline#section#create(['%{ShortCWD()}'])
sil! let g:airline_section_c = airline#section#create(['ic', '%<', 'file',
    \g:airline_symbols.space, 'readonly'])

" Solarized settings
if mobileSSH || $SOLARIZED != 1 | let g:solarized_termcolors=256 | endif
if !exists('colors_name') || colors_name != 'solarized'
    set background=dark
    sil! colorscheme solarized
endif

" vim: fdm=marker fdl=1:
