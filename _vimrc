" {{{ Vim built-in configuration

" Allow settings that are not vi-compatible
if &compatible | set nocompatible | endif

" Reset autocommands when vimrc is re-sourced
augroup VimrcAutocmds
    autocmd!
augroup END

" Check if in read-only mode to disable unnecessary plugins
if !exists('s:readonly') | let s:readonly = &readonly || exists('vimpager') | endif

" Make sure $MYVIMRC gets set
if empty($MYVIMRC) | let $MYVIMRC = expand('<sfile>') | endif

set shiftwidth=4                " Number of spaces to indent
set expandtab                   " Use spaces instead of tabs
set softtabstop=4
set autoindent                  " Automatic indentation
set cinoptions+=N-s             " Don't indent namespaces in C++
set cinoptions+=(0              " Line up function arguments
set cinoptions+=:0              " Don't indent inside switch statement
set nowrap                      " Don't wrap lines
set lazyredraw                  " Don't update display during macro execution
set encoding=utf-8              " Set default file encoding
set backspace=indent,eol,start  " Backspace through everything in insert mode
set whichwrap+=<,>,[,]          " Cursor keys wrap to previous/next line
set hlsearch                    " Highlight search terms
set incsearch                   " Incremental searching
set ignorecase                  " Make search case-insensitive and smart
set smartcase
set noshowmode                  " Don't show current mode
set nrformats-=octal            " Don't treat numbers as octal when incrementing/decrementing
set shortmess+=t                " Truncate filenames in messages when necessary
sil! set shortmess+=c           " Don't display insert completion messages
set showmatch                   " Show matching brace after inserting
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
sil! set showbreak=↪\           " Show character at start of wrapped lines
set nojoinspaces                " Don't add two spaces after punctuation
set gdefault                    " Substitute all occurrences by default
set nostartofline               " Don't jump to start of line for various motions
set isfname+={,}                " Interpret {} as part of a filename
set isfname-==                  " but not =
sil! set breakindent            " Indent wrapped lines
set tags-=./tags tags^=./tags;  " Search upwards for tags
set complete=.,w,t              " Don't complete from non-visible buffers

" Ignore system files
set wildignore=*.a,*.lib,*.spi,*.sys,*.dll,*.so,*.o,.DS_Store,*.pyc,*.d,*.exe,*.hi,*.pkl
set suffixes&vim
let &suffixes .= ','.substitute(&wildignore, '*', '', 'g')

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
set sessionoptions=buffers,curdir,help,tabpages,winsize
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
execute 'onoremap <silent> V%'  substitute(maparg('%',  'o'), '^v', 'V', '')
execute 'onoremap <silent> Vg%' substitute(maparg('g%', 'o'), '^v', 'V', '')

" {{{ Switch to last active tab/window
let g:lastTab=1
func! s:LastActiveWindow() " {{{
    if winnr('#') > 0 && winnr('#') != winnr()
        wincmd p
    elseif winnr('$') > 1
        wincmd w
    elseif tabpagenr() != g:lastTab && g:lastTab <= tabpagenr('$')
        execute "tabnext ".g:lastTab
    else
        tabnext
    endif
endfunc " }}}
autocmd VimrcAutocmds TabLeave * let g:lastTab=tabpagenr()
nnoremap <silent> <expr> ` <SID>inCmdWin()? ':q<CR>' : ':call <SID>LastActiveWindow()<CR>'
xnoremap <silent> ` :<C-u>call <SID>LastActiveWindow()<CR>
nnoremap <silent> <Leader>l :exe "tabn ".g:lastTab<CR>
nnoremap <silent> <Leader>; :exe "tabn ".g:lastTab<CR>
nnoremap <silent> ' `
xnoremap <silent> ' `
nnoremap <silent> <M-'> '
xnoremap <silent> <M-'> '
" }}}

" {{{ Platform-specific configuration
let hasMac=has("mac")
let hasWin=has("win16") || has("win32") || has("win64")
let hasSSH=!empty($SSH_CLIENT)
let mobileSSH=hasSSH && $MOBILE == 1

if hasWin
    " Change where backups are saved
    if !isdirectory("C:\\temp\\vimtmp")
        call mkdir("C:\\temp\\vimtmp", "p")
    endif
    set backupdir=C:\temp\vimtmp,.
    set directory=C:\temp\vimtmp//,.

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
    set backupdir=~/.tmp,.
    set directory=~/.tmp//,.
    sil! set undodir=.,~/.tmp

    if hasMac
        " Reveal current file in Finder
        nnoremap <silent> <F4> :<C-u>call system('reveal '.fnameescape(expand('%:p')))<CR>

        " Enable use of option key as meta key
        sil! set macmeta
    else
        " Explore to current file from Cygwin vim
        nnoremap <silent> <F4> :call
            \ system('cygstart explorer /select,`cygpath -w "'.expand('%:p').'"`')<CR>

        " Use cygstart to open links
        let g:netrw_browsex_viewer = "cygstart"
    endif

    let s:hasvimtools=filereadable(expand("$HOME/.vim/autoload/vimtools.vim"))
endif
" }}}

" {{{ Mappings
" Save current file if modified or execute command if in command window
nn <silent> <expr> <C-s> <SID>inCmdWin()? '<CR>' : ':<C-u>update<CR>'
ino <silent> <expr> <C-s> <SID>inCmdWin()? '<CR>' : '<Esc>:<C-u>update<CR>'
vn <silent> <C-s> <C-c>:<C-u>update<CR>
snor <silent> <C-s> <C-c>:<C-u>update<CR>

" Redraw the screen, remove search highlighting, and synchronize syntax
if v:version > 704 || (v:version == 704 && has('patch79'))
    nn <silent> <expr> <C-l> v:hlsearch ? ':<C-u>nohlsearch<CR>' : '<C-l>'
endif
nm <silent> g<C-l> :<C-u>syntax sync fromstart<CR><C-l>

" Execute q macro
nm Q @q

" Toggle paste mode
nn <silent> <Leader>pp :set paste!<CR>

" Select all
nn <Leader>a ggVG
vn <Leader>a <Esc>ggVG

" Toggle line numbers
nn <silent> <F2> :set number!<Bar>silent! let &relativenumber=&number<CR>
vm <silent> <F2> <Esc><F2>gv
im <F2> <C-o><F2>

" Edit configuration files
if s:hasvimtools
    command! -nargs=1 SwitchToOrOpen call vimtools#SwitchToOrOpen(<f-args>)
else
    command! -nargs=1 SwitchToOrOpen tab drop <args>
endif
let g:file_dict = {
    \ 'a': '$HOME/.vim/after/plugin/after.vim',
    \ 'b': ['$HOME/.bashrc', '$HOME/.bash_history'],
    \ 'c': '$HOME/.cshrc',
    \ 'd': '$HOME/.dircolors',
    \ 'f': '$HOME/.fzf.zsh',
    \ 'G': '$HOME/.ghci',
    \ 'g': ['$HOME/.gitconfig', '$HOME/.gitconfig_local'],
    \ 'H': '$HOME/.haskeline',
    \ 'h': ['$HOME/.histfile', '$HOME/.directory_history'],
    \ 'i': '$HOME/.inputrc',
    \ 'l': '$HOME/.zshrclocal',
    \ 'M': '$HOME/.minttyrc',
    \ 'm': '$HOME/.matplotlib/matplotlibrc',
    \ 'P': '$HOME/.plugged',
    \ 'p': ['$HOME/.ipython/profile_default/ipython_config.py',
    \       '$VIMCONFIG/misc/python/ipython_config.py'],
    \ 's': '$HOME/.screenrc',
    \ 't': ['$HOME/.tmux.conf', '$HOME/.tmux-local.conf'],
    \ 'u': '$HOME/.muttrc',
    \ 'v': ['$MYVIMRC', '$HOME/.vim/after/plugin/after.vim'],
    \ 'x': '$HOME/.Xdefaults',
    \ 'z': ['$HOME/.zshrc', '$HOME/.zshrclocal'],
    \ }
for key in keys(g:file_dict)
    execute 'nnoremap <silent> ,e'.key.' :<C-u>call <SID>edit_dotfile("'.key.'")<CR>'
endfor
func! s:simplify(file) abort " {{{
    return resolve(expand(a:file))
endfunc " }}}
func! s:escape(file) abort " {{{
    return fnameescape(s:simplify(a:file))
endfunc " }}}
func! s:edit_dotfile(key) abort " {{{
    if type(g:file_dict[a:key]) == type([])
        if v:count == 2 || s:simplify(expand('%:p')) == s:simplify(g:file_dict[a:key][0])
            execute 'edit '.s:escape(g:file_dict[a:key][1]).'|normal! zv'
        else
            execute 'edit '.s:escape(g:file_dict[a:key][0]).'|normal! zv'
        endif
    else
        execute 'edit '.s:escape(g:file_dict[a:key]).'|normal! zv'
    endif
endfunc " }}}

" Source vimrc
nn <silent> ,sv :so $MYVIMRC<CR>:runtime after/plugin/after.vim<CR>

" Shortcuts for switching buffer
nn <silent> <C-p> :bp<CR>
nn <silent> <C-n> :bn<CR>

" Search recursively or non-recursively
nn ,gr :vim // **/*<C-Left><C-Left><Right>
nn ,gn :vim // *<C-Left><C-Left><Right>
nn ,go :call setqflist([])<CR>:silent! Bufdo! vimgrepa // %<C-Left><C-Left><Right>
nn <Leader>gr :grep **/*(D.) -e ''<Left>
nn <Leader>gn :grep *(D.) -e ''<Left>
nn <Leader>go :call setqflist([])<CR>:silent! Bufdo! grepa '' %<C-Left><C-Left><Right>

" Delete trailing whitespace
nn <silent> <expr> ,ws ':keepj keepp sil! %s/\s\+$//'.(&gdefault ? '' : 'g').'<CR>'

" Open tag vertically or below
nn <silent> <C-w><C-]> :<C-u>belowright vertical split<CR><C-]>zv
nn <silent> <C-w>] :<C-u>belowright split<CR><C-]>zv
nn <silent> <C-w>g<C-]> :<C-u>tab split<CR><C-]>zv
xn <silent> <C-w><C-]> :<C-u>belowright vertical split<CR>gv<C-]>zv
xn <silent> <C-w>] :<C-u>belowright split<CR>gv<C-]>zv

" Shortcuts for switching tab, including closing command window if it's open
nn <silent> <expr> <C-Tab>   tabpagenr('$')==1 ?
    \":sil! call system('tmux next')\<CR>" : (<SID>inCmdWin()? ':q<CR>gt' : 'gt')
nn <silent> <expr> <C-S-Tab> tabpagenr('$')==1 ?
    \":sil! call system('tmux prev')\<CR>" : (<SID>inCmdWin()? ':q<CR>gT' : 'gT')
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

" Delete without yank by default, and <M-d> or \\d for delete with yank
if maparg('c', 'n') == ''
    for k in ['c', 'd', 's', 'x', 'C', 'D', 'S', 'X']
        for m in ['nnoremap', 'xnoremap']
            exe m.' '.k.' "_'.k.'|'.m.' <M-'.k.'> '.k.'|'.m.' \\'.k.' '.k.'|ono <M-'.k.'> '.k
        endfor
    endfor
endif

" Copy file/path with/without line number
function! s:copy(arg) abort " {{{
    let @+ = a:arg | let @* = @+ | let @" = @+
    echo 'copied: ' . @"
endfunction " }}}
nn <silent> <C-g> <C-g>:let @+ = expand('%:p')<CR>:let @* = @+<CR>:let @" = @+<CR>
nn <silent> g<C-g> g<C-g>:let @+ = expand('%:p:h')<CR>:let @* = @+<CR>:let @" = @+<CR>
nn <silent> 1<C-g> 1<C-g>:call <SID>copy(expand('%:p:t'))<CR>
nn <silent> <M-g> <C-g>:call <SID>copy(expand('%:p').':'.line('.'))<CR>
nn <silent> <M-G> <C-g>:call <SID>copy(expand('%:p:t').':'.line('.'))<CR>

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
nn <silent> <expr> <C-w><C-q> <SID>inCmdWin()? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w>q     <SID>inCmdWin()? ':q<CR>' : '<C-w>c'
nn <silent> <expr> <C-w><C-w> <SID>inCmdWin()? ':q<CR>' : '<C-w><C-w>'

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
nn @! :<C-u><C-r><C-r>:<Home><C-Right>!<CR>

" Repeat last command with case of first character switched
nn @~ :<C-u><C-r><C-r>:<C-f>^~<CR>

" Repeat last command with 'verbose' prepended
nn @& :<C-u><C-r><C-r>:<Home>verbose <CR>
nn @? :<C-u><C-r><C-r>:<Home>verbose <CR>

" Use <C-q> to do what <C-v> used to do
no <C-q> <C-v>

" Show current line of diff at bottom of tab
nn <Leader>dl <C-w>t<C-w>s<C-w>J<C-w>t<C-w>l<C-w>s<C-w>J<C-w>t:res<CR><C-w>b

" Make Y behave like other capital letters
nn Y y$

" Navigate windows with arrow keys
no <Down>  <C-w>j
no <Up>    <C-w>k
no <Left>  <C-w>h
no <Right> <C-w>l

" Change window size with control + arrow keys
no <silent> <C-Down>  :<C-u>call vimtools#ResizeWindow('down')<CR>
no <silent> <C-Up>    :<C-u>call vimtools#ResizeWindow('up')<CR>
no <silent> <C-Left>  :<C-u>call vimtools#ResizeWindow('left')<CR>
no <silent> <C-Right> :<C-u>call vimtools#ResizeWindow('right')<CR>

" Stay in visual mode after indent change
vn < <gv
vn > >gv

" Copy WORD/word above/below cursor with (<C-y>/<C-f>)/(<M-y>/<M-f>)
ino <silent> <C-f> <C-r>=matchstr(getline(line('.') + 1), '\v%'.virtcol('.').'v%(\S+\|\s*)')<CR>
ino <silent> <C-y> <C-r>=matchstr(getline(line('.') - 1), '\v%'.virtcol('.').'v%(\S+\|\s*)')<CR>
ino <silent> <M-f> <C-r>=matchstr(getline(line('.') + 1), '\v%'.virtcol('.').'v%(\k+\|\W)')<CR>
ino <silent> <M-y> <C-r>=matchstr(getline(line('.') - 1), '\v%'.virtcol('.').'v%(\k+\|\W)')<CR>
ino <M-F> <C-e>
ino <M-Y> <C-y>

" Make j/k work as expected on wrapped lines
no <expr> j &wrap && strdisplaywidth(getline('.')) > (winwidth(0) -
    \ (&number ? &numberwidth : 0)) ? 'gj' : 'j'
no <expr> k &wrap && max([strdisplaywidth(getline('.')),
    \ strdisplaywidth(getline(line('.')-1))]) >
    \ (winwidth(0) - (&number ? &numberwidth : 0)) ? 'gk' : 'k'

" ZZ and ZQ close buffer if it's not open in another window
nn <silent> <expr> ZQ substitute('%sdelete")<CR>:normal! ZQ<CR>%s'.&bufhidden.
    \ '")<CR>','%s',':<C-u>call setbufvar('.bufnr('%').',"\&bufhidden","','g')
nn <silent> <expr> ZZ substitute('%sdelete")<CR>:normal! ZZ<CR>%s'.&bufhidden.
    \ '")<CR>','%s',':<C-u>call setbufvar('.bufnr('%').',"\&bufhidden","','g')

" Save and quit all
nn <silent> ZA :wqall<CR>

" Go up directory tree easily
cno <expr> . (getcmdtype()==':'&&getcmdline()=~'[/ ]\.\.$')?'/..':'.'

" Execute line under cursor
if s:hasvimtools
    nno <silent> <Leader>x  :<C-u>let g:first_op=1<bar>set opfunc=vimtools#SourceMotion<CR>g@
    nno <silent> <Leader>xx :<C-u>set opfunc=vimtools#SourceMotion<Bar>exe
        \ 'norm! 'v:count1.'g@_'<CR>
    autocmd VimrcAutocmds FileType vim ino <silent> <buffer> <Leader>x <Esc>:<C-u>let g:first_op=1
        \ <bar>set opfunc=vimtools#SourceMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    autocmd VimrcAutocmds FileType help,vim xno <silent> <buffer> <C-p> :<C-u>
        \ call SaveRegs()<CR>gvy:execute 'PP <C-r>=substitute(@@, "'", '&&', 'g')<CR>'
        \ <bar>call RestoreRegs()<CR>
    xno <silent> <Leader>x  :<C-u>call vimtools#SourceMotion('visual')<CR>
else
    nn <silent> <Leader>xx :exec getline('.')<CR>
endif

" Close quickfix window/location list
nn <silent> <Leader>w :cclose<bar>Windo lclose<bar>pclose<CR>

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
nn <silent> <Leader>ss :<C-u>set buftype=<C-r>=&buftype ==# 'nofile' ? '' : 'nofile'<CR><CR>

" Echo syntax name under cursor
nn <silent> <Leader>y :<C-U>exe vimtools#EchoSyntax(v:count)<CR>

" Change directory
nn <silent> <Leader>cd :execute "Windo cd ".fnameescape(
    \ &filetype ==# 'vimfiler' ? b:vimfiler.current_dir : expand('%:p:h'))<CR>:echo getcwd()<CR>
nn <silent> ,cd :lcd %:p:h<CR>:pwd<CR>
nn <silent> <Leader>.. :execute "Windo cd ".fnameescape(fnamemodify(getcwd(),':h'))<bar>pwd
    \ <bar>silent! call repeat#set("\<Leader>..")<CR>
nn <silent> ,.. :lcd ..<CR>:pwd<CR>:sil! call repeat#set(",..")<CR>

" Put from " register in insert mode
ino <M-p> <C-r>"

" Go to older position in jump list
nn <S-Tab> <C-o>zv

" Make <C-d>/<C-u> scroll 1/3 page
no <expr> <C-d> (v:count ? "" : (winheight('.')) / 3 + 1)."\<C-d>"
no <expr> <C-u> (v:count ? "" : (winheight('.')) / 3 + 1)."\<C-u>"

" Highlight word without moving cursor
nn <Leader>* :<C-u>let @/ = '\<' . expand('<cword>') . '\>'<bar>
    \ call histadd('/', @/)<bar>set hlsearch<bar>echo '/' . @/<CR>zv
nmap <Leader>8 <Leader>*
nn <Leader>g* :<C-u>let @/ = expand('<cword>')<bar>
    \ call histadd('/', @/)<bar>set hlsearch<bar>echo '/' . @/<cr>zv
nmap <Leader>g8 <Leader>g*

" Move current line to 1/5 down from top or up from bottom
nn <expr> zh "zt".(winheight('.')/5)."\<C-y>"
nn <expr> zl "zb".(winheight('.')/5)."\<C-e>"
xn <expr> zh "zt".(winheight('.')/5)."\<C-y>"
xn <expr> zl "zb".(winheight('.')/5)."\<C-e>"

" Open cursor file in vertical or horizontal split
nn <silent> <C-w><C-f> :belowright vertical wincmd f<CR>
nn <silent> <C-w>f :belowright wincmd f<CR>
xn <silent> <C-w><C-f> :<C-u>belowright vertical split<CR>gvgf
xn <silent> <C-w>f :<C-u>belowright vertical split<CR>gvgf

" Default make key
nn <silent> <F5> :update<CR>:make<CR><CR>
nn <silent> g<F5> :update<CR>:make clean<CR><CR>
im <F5> <Esc><F5>

" Cycle through previous searches
nn <silent> <expr> <C-k> (<SID>inCmdWin()? '' : "/\<C-f>".(v:count1 + 1))."k:let @/=getline('.')<CR>"
nn <silent> <expr> <C-j>  <SID>inCmdWin()? "j:let @/=getline('.')<CR>" : '<C-j>'

" Don't open fold when jumping to first or last line in diff mode and remember G jumps
nn <silent> <expr> gg "gg".(&diff ? "" : "zv")
nn <silent> <expr> G "G".(&diff ? "" : "zv") . (v:count ? 'mGmg' : '')

" [count]V/v always selects [count] lines/characters
nn <expr> V v:count ? "\<Esc>V".(v:count > 1 ? (v:count - 1).'j' : '') : 'V'
nn <expr> v v:count ? "\<Esc>v".(v:count > 1 ? (v:count - 1).'l' : '') : 'v'

" <Home> moves cursor after \v
cno <expr> <Home> "\<Home>".(getcmdtype() =~ '[/?]' &&
    \ getcmdline() =~? '^\\v' ? "\<Right>\<Right>" : "")
cmap <C-b> <Home>

" Fix @: in visual mode when there is a modifier before the range
vnoremap <expr> @ @: =~ "\\V'<,'>" ? "\<Esc>@" : "@"

" Synonym for q:
nn g: q:

" Use <C-n>/<C-p> instead of arrows for command line history
cm <C-p> <Up>
cm <C-n> <Down>

" - is used for file browser
nn _ -
xn _ -

" Go to most recent text change
nn <silent> g. m':silent! execute "buffer".g:last_change_buf<CR>:keepjumps normal! `.<CR>

" Delete swap file and reload file
nn <silent> <Leader>ds :<C-u>if delete(b:swapname) == 0<bar>set noreadonly<bar>else<bar>
    \ echoerr 'failed to delete swapfile'<bar>endif<CR>

" Until opening pair, comma, or semicolon
ono . :<C-u>call    search('[[({<,;]')\|echo<CR>
xno . <Esc>`>l:call search('[[({<,;]')\|echo<CR>v`<oh
ono g] vg_
xno g] g_h

" Update diff
nn <silent> du :<C-u>diffupdate<CR>

" Insert home directory after typing $~
ino <expr> ~ getline('.')[virtcol('.')-2] == '$' ? "\<BS>".$HOME : '~'
cno <expr> ~ getcmdline()[getcmdpos()-2] == '$' ? "\<BS>".$HOME : '~'

" Discard changes and reload undofile for current file
nn <silent> <Leader><Leader>r :<C-u>execute "silent later ".&undolevels
    \<bar>while &modified<bar>silent earlier<bar>endwhile
    \<bar>execute 'rundo '.fnameescape(undofile(expand('%:p')))<CR>

" Don't save omaps to command history
silent! nn <unique> . .

" New line when cursor is not at the end of the current line
ino <silent> <C-j> <Space><BS><C-r>="\<lt>C-o>o"<CR>
vno <C-j> <Esc>o
ino <silent> <C-k> <Space><BS><C-r>="\<lt>C-o>O"<CR>
vno <C-k> <Esc>O

" Insert filename tail with <C-r>$ and escape special characters with <C-r>%/#
cno <expr> <C-r>% fnameescape(expand('%'))
cno <expr> <C-r># fnameescape(expand('#'))
cno <expr> <C-r>$ fnameescape(expand('%:t'))
ino <expr> <C-r>$ expand('%:t')

" Equivalent of 'dgn' for all matches in buffer/visual selection
nn <silent> <Leader>dgn :<C-u>%s///<CR>
xn <silent> gd :s///<CR>

" Faster repeat of previous shell command
cno <expr> ! getcmdtype() == ':' && getcmdline() == '!' ? '!<CR>' : '!'

" Move cursor in insert mode without splitting undo
ino <Left>  <C-g>U<Left>
ino <Right> <C-g>U<Right>
function! s:home() abort " {{{
    let line = getline('.')
    let before = strchars(line[:col('.')-1]) - 1
    let after = strchars(line[col('.')-1:])
    let blanks = strchars(matchstr(line, '^\s*'))
    if before < blanks
        return repeat("\<C-g>U\<Right>", blanks - before)
    elseif before == blanks
        return repeat("\<C-g>U\<Left>", blanks)
    else
        return repeat("\<C-g>U\<Left>", before - blanks + (after ? 0 : 1))
    endif
endfunction " }}}
inoremap <expr> <Home> <SID>home()
inoremap <expr> <End> repeat("<C-g>U<Right>", strchars(getline('.')[col('.')-1:]))
im <C-b> <Home>
im <C-e> <End>

" Remove trailing whitespace with <CR> (<BS> can delete multiple characters so use <Del>)
ino <expr> <CR> (getline('.')[:virtcol('.')-2] =~ '\(\S\\|^\)\s\+$' ?
    \ repeat('<Left><Del>', len(matchstr(getline('.')[:virtcol('.')-2], '\s\+$'))) : '').
    \ (pumvisible() ? '<C-y>' : '') . '<CR>'
ino \<CR> \<CR>

" Make * and # use 'smartcase'
nn * /\<<C-r>=expand('<cword>')<CR>\><CR>zv
nn # ?\<<C-r>=expand('<cword>')<CR>\><CR>zv
nn g* /<C-r>=expand('<cword>')<CR><CR>zv
nn g# ?<C-r>=expand('<cword>')<CR><CR>zv

" Toggle IPython history storage
nn <silent> ,ih :<C-u>let g:ipython_store_history = !get(g:, 'ipython_store_history', 1)<CR>
    \:<C-u>echo 'IPython history ' . (g:ipython_store_history ? 'enabled' : 'disabled')<CR>

" Insert date
ino <silent> <expr> <C-x><C-d> substitute(strftime('%d%b%Y'), '^0*', '', '')
cno          <expr> <C-x><C-d> substitute(strftime('%d%b%Y'), '^0*', '', '')
ino <silent> <expr> <C-x>d strftime('%Y_%m_%d_%H%M%Z')
cno          <expr> <C-x>d strftime('%Y_%m_%d_%H%M%Z')

" Copy all differences from other buffer
nn <Leader>do <C-\><C-n>gg:diffget<bar>1,$+diffget<CR>

" Shortcuts for t_ and T_
omap _ t_
omap - T_
" }}}

" {{{ Abbreviations to open help
if s:hasvimtools
    command! -nargs=? -complete=help Help call vimtools#OpenHelp(<q-args>)
    cnorea <expr> ht getcmdtype()==':'&&getcmdpos()<=3 ? 'tab help':'ht'
    cnorea <expr> h getcmdtype()==':'&&getcmdpos()<=2 ? 'Help':'h'
    cnorea <expr> H getcmdtype()==':'&&getcmdpos()<=2 ? 'Help':'H'
    cnoremap <expr> <Up> getcmdtype()==':'&&getcmdline()=='h' ? '<BS>H<Up>':'<Up>'
    nmap <silent> <expr> K <SID>inCmdWin()? 'viwK' : ":exec
        \ 'Help '.vimtools#HelpTopic()<CR>"
    vnoremap <silent> <expr> K vimtools#OpenHelpVisual()
endif
" }}}

" {{{ Cscope configuration
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
" }}}

" {{{ Functions
" Save/restore unnamed/clipboard registers
func! SaveRegs() " {{{
    let s:quotereg = @" | let s:starreg = @* | let s:plusreg = @+
endfunc " }}}
func! RestoreRegs() " {{{
    let @" = s:quotereg | let @* = s:starreg | let @+ = s:plusreg
endfunc " }}}

" Like bufdo but return to starting buffer
func! Bufdo(command, bang) " {{{
    let currBuff=bufnr("%")
    if a:bang
        execute 'bufdo set eventignore-=Syntax | ' . a:command
    else
        execute 'bufdo ' . a:command
    endif
    execute 'buffer ' . currBuff
endfunc " }}}
command! -nargs=+ -bang -complete=command Bufdo call Bufdo(<q-args>, <bang>0)

" Like windo but restore current and previous window
func! Windo(command) " {{{
    let cwin = winnr()
    let cwinbuf = winbufnr(cwin)
    let pwin = winnr('#')
    let pwinbuf = winbufnr(pwin)
    execute 'windo '.a:command
    silent! execute pwin.'wincmd w'
    if winbufnr(winnr()) != pwinbuf | silent! execute bufwinnr(pwinbuf).'wincmd w' | endif
    silent! execute cwin.'wincmd w'
    if winbufnr(winnr()) != cwinbuf | silent! execute bufwinnr(cwinbuf).'wincmd w' | endif
endfunc " }}}
command! -nargs=+ -complete=command Windo call Windo(<q-args>)

" Function to set key codes for terminals
func! s:KeyCodes() " {{{
    " Set key codes to work as meta key combinations
    for n in range(33, 47) + range(58, 61) + range(63, 90) + range(92, 126)
        execute "set <M-" . escape(nr2char(n), '"|') . ">=\<Esc>" . escape(nr2char(n), '"|')
    endfor
endfunc " }}}
nnoremap <silent> <Leader>k :call <SID>KeyCodes()<CR>
if mobileSSH | call s:KeyCodes() | endif

func! s:CmdwinMappings() " {{{
    " Make gf/<C-]> work in command window
    function! s:cmdwinmap(map, exp, cmd) abort " {{{
        return printf('nnoremap <silent> <buffer> %s :let cword = ' .
            \ 'expand("<' . a:exp . '>")<CR>:quit<CR>:execute "%s " . cword<CR>zv', a:map, a:cmd)
    endfunction " }}}
    execute s:cmdwinmap('gf',           'cfile', 'edit')
    execute s:cmdwinmap('<C-w><C-f>',   'cfile', 'belowright vsplit')
    execute s:cmdwinmap('<C-w>f',       'cfile', 'belowright split')
    execute s:cmdwinmap('<C-w>gf',      'cfile', 'tabedit')
    execute s:cmdwinmap('<C-]>',        'cword', 'tag')
    execute s:cmdwinmap('<C-w><C-]>',   'cword', 'belowright vertical stag')
    execute s:cmdwinmap('<C-w>]',       'cword', 'belowright stag')
    execute s:cmdwinmap('<C-w>g<C-]>',  'cword', 'tab stag')
    execute s:cmdwinmap('g<C-]>',       'cword', 'tjump')
    execute s:cmdwinmap('g<C-w><C-]>',  'cword', 'belowright vertical stjump')
    execute s:cmdwinmap('g<C-w>]',      'cword', 'belowright stjump')
    execute s:cmdwinmap('g<C-w>g<C-]>', 'cword', 'tab stjump')

    " Delete item under cursor from history
    nnoremap <silent> <buffer> dD :call histdel(g:cmdwinType,'\V\^'.
        \escape(getline('.'),'\').'\$')<CR>:norm! "_dd<CR>

    " Resize window
    nnoremap <buffer> <C-Up>   <C-w>+
    nnoremap <buffer> <C-Down> <C-w>-

    " Close window
    nnoremap <silent> <buffer> <Leader>w :q<CR>
    nnoremap <silent> <buffer> ZZ :q<CR>

    " Don't delete trailing trailing with <CR> in command window
    inoremap <buffer> <expr> <CR> (pumvisible() ? '<C-y>' : '') . '<CR>'
endfunc " }}}

" Delete hidden buffers
func! s:DeleteHiddenBuffers() " {{{
    let tpbl=[]
    call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
    for l:buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
        silent! execute 'bd' l:buf
    endfor
endfunc " }}}
nnoremap <silent> <Leader>dh :call <SID>DeleteHiddenBuffers()<CR>

func! s:CleanEmptyBuffers() " {{{
    let buffers = filter(range(0, bufnr('$')), 'buflisted(v:val) && '
        \.'empty(bufname(v:val)) && bufwinnr(v:val)<0 && getbufvar(v:val,"&buftype")==""')
    if !empty(buffers)
        exe 'bw '.join(buffers, ' ')
    endif
endfunc " }}}
nnoremap <silent> <Leader>de :call <SID>CleanEmptyBuffers()<CR>

" Kludge to make first quickfix result unfold
func! s:ToggleFoldOpen() " {{{
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
endfunc " }}}
autocmd VimrcAutocmds QuickFixCmdPost * call s:ToggleFoldOpen()

" Function to redirect output of ex command to clipboard
func! Redir(cmd) " {{{
    redir @" | execute a:cmd | redir END
    let @"=substitute(@","^\<NL>*",'','g')
    let @*=@"
    let @+=@"
endfunc " }}}
command! -nargs=+ -complete=command Redir call Redir(<q-args>)
nnoremap <Leader>R :<C-r><C-r>:<Home>Redir <CR>

" Function to removing trailing carriage return from register
func! s:FixReg() " {{{
    let l:reg=nr2char(getchar())
    let l:str=getreg(l:reg)
    while l:str =~ "\<CR>\<NL>"
        let l:str=substitute(l:str,"\<CR>\<NL>","\<NL>",'')
    endwhile
    call setreg(l:reg, l:str)
endfunc " }}}
nnoremap <silent> <Leader>f :call <SID>FixReg()<CR>

" Cycle search mode between regular, very magic, and very nomagic
func! s:CycleSearchMode() " {{{
    let l:cmd = getcmdline()
    let l:pos = getcmdpos()
    if l:cmd =~# '\v(KeepPatterns [sgv]\/)?(\\\%V)?\\v'
        let l:cmd = substitute(l:cmd,'\v(KeepPatterns [sgv]\/)?(\\\%V)?\\v','\1\2\\V','')
    elseif l:cmd =~# '\v(KeepPatterns [sgv]\/)?(\\\%V)?\\V'
        let l:cmd = substitute(l:cmd,'\v(KeepPatterns [sgv]\/)?(\\\%V)?\\V','\1\2','')
        call setcmdpos(l:pos - 2)
    else
        let l:cmd = substitute(l:cmd,'\v(^.*KeepPatterns [sgv]\/)?(\\\%V)?','\1\2\\v','')
        call setcmdpos(l:pos + 2)
    endif
    return l:cmd
endfunc " }}}
cnoremap <expr> <C-x><C-x> getcmdtype() =~ '[/?:]' ?
    \ "\<C-\>e\<SID>CycleSearchMode()\<CR>" : ""

" Close other windows or close other tabs
func! s:CloseWinsOrTabs() " {{{
    let startwin = winnr()
    wincmd t
    if winnr() == winnr('$')
        tabonly
    else
        if winnr() != startwin | wincmd p | endif
        wincmd o
    endif
endfunc " }}}
nnoremap <silent> <C-w>o :call <SID>CloseWinsOrTabs()<CR>
nnoremap <silent> <C-w><C-o> :call <SID>CloseWinsOrTabs()<CR>

" <C-v> pastes from system clipboard
func! s:Paste() " {{{
    if @+ =~ "\<NL>"
        set paste
        set pastetoggle=<F10>
        return "\<C-r>+\<F10>".(@+=~"\<NL>$"?"\<BS>":"")
    endif
    return "\<C-r>+"
endfunc " }}}
nnoremap <C-v> "+gP
cnoremap <expr> <C-v> getcmdtype() == '=' ?
    \ "\<C-r>+" : "\<C-r>=substitute(@+, '\\n', '', 'g')\<CR>"
imap <expr> <C-v> <SID>Paste()
exe 'vnoremap <silent> <script> <C-v> '.paste#paste_cmd['v']

" Make last search a whole word
func! s:SearchWholeWord(dir) " {{{
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
endfunc " }}}
nn <silent> <expr> <Leader>n <SID>SearchWholeWord(1).'zv'
nn <silent> <expr> <Leader>N <SID>SearchWholeWord(0).'zv'

" Search for first non-blank
func! s:FirstNonBlank() " {{{
    if getcmdline() == '^'
        return "\<BS>".'\(^\s*\)\@<='
    elseif getcmdline() ==# '\v^'
        return "\<BS>".'(^\s*)@<='
    elseif getcmdline() ==# '\V^'
        return "\<BS>".'\(\^\s\*\)\@\<\='
    else
        return '^'
    endif
endfunc " }}}
cnoremap <expr> ^ getcmdtype()=~'[/?]' ? <SID>FirstNonBlank() : '^'

" Don't delete the v/V at the start of a search
func! s:SearchCmdDelWord() " {{{
    let s:iskeyword = &l:iskeyword | setlocal iskeyword&
    let cmd = (getcmdtype() =~ '[/?]' ? '/' : '').
        \ strpart(getcmdline(), 0, getcmdpos() - 1)
    if cmd =~# '\v/%(\\\%V)?\\[vV]\k+\s*$'
        return "\<C-w>".matchstr(cmd, '\v/%(\\\%V)?\\\zsv\ze\k*\s*$')
    elseif cmd =~# '\v/\\\%V\k+\s*$'
        return "\<C-w>V"
    endif
    return "\<C-w>"
endfunc
func! s:ResetIskeyword()
    let &l:iskeyword = s:iskeyword
    return ''
endfunc " }}}
cnoremap <expr> <C-w> <SID>SearchCmdDelWord() . '<C-r>=<SID>ResetIskeyword()<CR>'
cnoremap <expr> <C-u> "\<C-u>".
    \ ((getcmdtype() =~ '[/?]' && len(getcmdline()) > 2 &&
    \  (getcmdline()[:1] == '\v' \|\| getcmdline()[:1] == '\V')) ? getcmdline()[:1] : '')

" <C-Left> moves cursor after \v
func! s:SearchCtrlLeft() " {{{
    if getcmdtype() =~ '[/?]' && getcmdline() =~? '^\\v'
        if strpart(getcmdline(), 0, getcmdpos() - 1) =~ '\v^\S+\s?$'
            return "\<C-Left>\<Right>\<Right>"
        endif
    endif
    return "\<C-Left>"
endfunc " }}}
cnoremap <expr> <C-Left> <SID>SearchCtrlLeft()

" Fix up arrow in search history when search starts with \v
func! s:OlderHistory() " {{{
    augroup omap_slash
        autocmd!
    augroup END
    if getcmdtype() =~ '[/?]' && getcmdline() ==? '\v'
        return "\<C-u>\<Up>"
    elseif getcmdtype() == ':' && getcmdline() =~# '\v^.*[Ssgv]/\\[vV]$'
        return "\<BS>\<BS>\<Up>"
    elseif getcmdtype() == ':' && getcmdline() =~# '\v^.*[Ssgv]/\\\%V\\[vV]$'
        return repeat("\<BS>", 5)."\<Up>"
    elseif s:hasvimtools && getcmdtype() == ':' && getcmdline() == 'h'
        return "\<BS>H\<Up>"
    elseif getcmdline() == ''
        return "\<S-Up>"
    endif
    return "\<Up>"
endfunc " }}}
cnoremap <expr> <Up> <SID>OlderHistory()

" Add wildcards to path in command line for zsh-like expansion
func! s:StarifyPath() " {{{
    set wildcharm=<C-t>
    let cmdline = getcmdline()
    let space = match(cmdline, '\m^.*\zs\s\ze\S\+$')
    let start = cmdline[0:space]
    let finish = substitute(cmdline[space+1:-1],'[^[:space:]~]\zs/','*/','g')
    return start.finish
endfunc " }}}
cnoremap <C-s> <C-\>e<SID>StarifyPath()<CR><C-t><C-d>

" Ring system bell
func! s:Bell() " {{{
    let visualbell_save = &visualbell
    set novisualbell
    execute "normal! \<Esc>"
    let &visualbell = visualbell_save
endfunc " }}}
autocmd VimrcAutocmds QuickFixCmdPost * call s:Bell()

" Setup for single-file C/C++ projects
func! s:SingleFile() " {{{
    execute 'setlocal makeprg=make\ '.expand('%:r')
    nnoremap <buffer> <S-F5> :execute '!./'.expand('%:r')<CR>
    if $CXX ==# '' && $CPPFLAGS ==# ''
        if executable('clang++')
            let $CXX = 'clang++'
        endif
        let $CXXFLAGS = '-Wall -Wextra --std=c++11'
    endif
    lcd! %:p:h
endfunc " }}}
command! -nargs=0 SingleFile call s:SingleFile()

" Use 'very magic' regex by default
func! s:SearchHandleKey(dir) " {{{
    echo a:dir.'\v'
    let c = getchar()
    if c != char2nr("\<C-c>") && c != char2nr("\<Esc>")
        set wildcharm=<C-t>
        augroup search_tab_map
            autocmd!
            autocmd CursorMoved * execute 'silent! cunmap <Tab>' | autocmd! search_tab_map
        augroup END
        cnoremap <expr> <Tab> getcmdtype() =~ '[/?]' ?
            \ '<C-\>e<SID>SearchComplete()<CR><C-t>' : '<Tab>'
    endif
    " CursorHold, FocusLost, FocusGained
    if c =~ "\200\375[`_]" || c == "\<F24>" || c == "\<F25>" | let c = '' | endif
    if     c == char2nr("\<CR>")             | return a:dir."\<CR>"
    elseif c == char2nr("\<Esc>")            | return "\<C-l>"
    elseif c == char2nr("\<C-c>")            | return "\<C-l>"
    elseif c == char2nr("\<C-^>")            | return "\<C-l>"
    elseif c == char2nr("\<C-x>")            | return a:dir.'\V'
    elseif c == "\<Up>"                      | return a:dir."\<Up>"
    elseif c == char2nr("/") && a:dir == '/' | return '//'
    elseif c == char2nr("\<C-v>")
        return a:dir."\\v\<C-r>=substitute(@+, '\\n', '', 'g')\<CR>"
    elseif c == char2nr("\<Tab>")
        return a:dir."\\v\<C-\>e" . maparg('<SID>', 'n') .
            \ "SearchComplete('\\v', '" . a:dir . "')\<CR>\<C-t>"
    else
        return a:dir.'\v'.(type(c) == type("") ? c : nr2char(c))
    endif
endfunc " }}}
nnoremap <SID> <SID>
noremap <expr> / <SID>SearchHandleKey('/')
noremap <expr> ? <SID>SearchHandleKey('?')

" Tab completion for search prompt
function! s:SearchComplete(...) abort " {{{
    silent! cunmap <Tab>
    let magic = matchstr(getcmdline(), '\v^(\\v|\\V\\|\\)\<?')
    let begin = substitute(getcmdline(), '\v^(\\v|\\V\\|\\)\<?', '', '')
    let cmdtype = getcmdtype()
    let input = input('='.cmdtype.magic, begin, 'customlist,vimtools#CmdlineComplete')
    return magic.input
endfunction " }}}

" Paste in visual mode without overwriting clipboard
func! s:VisualPaste() " {{{
    call SaveRegs()
    normal! gvp
    call RestoreRegs()
endfunc " }}}
vnoremap <silent> p :<C-u>call <SID>VisualPaste()<CR>
vnoremap <silent> <C-p> :<C-u>call <SID>VisualPaste()<CR>=']
vnoremap <M-p> p
vnoremap <M-P> p=']

" Insert result of visually selected expression
func! s:EvalExpr() " {{{
    call SaveRegs()
    return "c\<C-o>:let @\"=substitute(@\",'\\n','','g')\<CR>".
        \ "\<C-r>=\<C-r>\"\<CR>\<Esc>:call RestoreRegs()\<CR>"
endfunc " }}}
vnoremap <expr> <silent> <C-e> <SID>EvalExpr()

" Don't overwrite pattern with substitute command
if s:hasvimtools
    command! -range -nargs=* KeepPatterns
        \ call vimtools#KeepPatterns(<line1>, <line2>, <q-args>)
    " Complete wildmode with <C-e> if in wildmenu with a trailing slash
    if exists('*wildmenumode')
        cnoremap <expr> / wildmenumode() && (strridx(getcmdline(),'/')==len(getcmdline())-1) ?
            \ "\<C-e>" : "\<C-\>evimtools#KeepPatternsSubstitute()\<CR>\<Left>\<C-]>\<Right>"
    endif
    nnoremap <silent> & :<C-u>call vimtools#RepeatSubs(0)<CR>:silent! call repeat#set('&')<CR>
    nnoremap <silent> g& :<C-u>call vimtools#RepeatSubs(1)<CR>:silent! call repeat#set('g&')<CR>
else
    if exists('*wildmenumode')
        cnoremap <expr> / wildmenumode() && (strridx(getcmdline(),'/')==len(getcmdline())-1) ?
            \ "\<C-e>" : '/'
    endif
endif

" Function abbreviations
if s:hasvimtools && v:version >= 704
    cnoremap ( <C-\>evimtools#FuncAbbrevs()<CR><Left><C-]><Right>
endif

" Delete until character on command line
func! s:DeleteUntilChar(char) " {{{
    let cmdstart = strpart(getcmdline(), 0, getcmdpos() - 1)
    let start = substitute(cmdstart, '\V'.escape(a:char, '\').'\*\$', '', '')
    let newcmdstart = strpart(start, 0, strridx(start, a:char) + 1)
    let end = strpart(getcmdline(), getcmdpos() - 1)
    call setcmdpos(getcmdpos() + len(newcmdstart) - len(cmdstart))
    return newcmdstart.end
endfunc " }}}
cnoremap <C-@> <C-\>e<SID>DeleteUntilChar('/')<CR>
inoremap <C-@> <Esc>"_dT/"_s
cnoremap – <C-\>e<SID>DeleteUntilChar('_')<CR>
inoremap – <Esc>"_dT_"_s
cnoremap <M-w> <C-\>e<SID>DeleteUntilChar(' ')<CR>
inoremap <expr> <M-w> getline('.')[:virtcol('.')-1] =~ '^\S*\s*$' ? '<C-u>' :
    \ (virtcol('.') == 0 ? '<BS>' : (getline('.')[virtcol('.')-2] =~ '\s' ?
    \ repeat('<Left><Del>', len(matchstr(getline('.')[:virtcol('.')-2], '\s\+$'))) :
    \ '<Esc>"_dT<Space>"_s'))

" !$ inserts last WORD of previous command
func! s:LastWord() " {{{
    let cmdstart = strpart(getcmdline(), 0, getcmdpos() - 1)
    let cmdstart = cmdstart[0:-2].matchstr(@:, '\v\S+$')
    let end = strpart(getcmdline(), getcmdpos() - 1)
    return cmdstart.end
endfunc " }}}
cnoremap <expr> $ getcmdline()[getcmdpos()-2] == '!' ?
    \ "\<C-\>e\<SID>LastWord()\<CR>" : '$'

" Stay at search result without completing search
func! QuitSearch() " {{{
    if getcmdtype() !~ '[/?]' | return '' | endif
    let visual = mode() =~? "[v\<C-v>]"
    return "\<C-e>\<C-u>\<C-c>m`:\<C-u>call search('".
        \ substitute(getcmdline(), "'", "''", 'g')."', '".
        \ (getcmdtype() == '/' ? '' : 'b')."')\<CR>zv".(visual ? 'm>gv' : "")
endfunc " }}}
cnoremap <silent> <expr> <C-^> QuitSearch()
cnoremap <silent> <expr> <C-CR> QuitSearch()

" Unfold at incremental search match
func! s:UnfoldSearch() " {{{
    let type = getcmdtype()
    if type !~ '[/?]' | return '' | endif
    let visual = mode() =~? "[v\<C-v>]"
    let cmd = substitute(getcmdline(), "'", "''", 'g')
    return "\<C-c>:\<C-u>let unfoldview = winsaveview()\<CR>"
        \ .":call search('".cmd."', '".(type == '/' ? '' : 'b')."')\<CR>zv"
        \ .":call winrestview(unfoldview)\<CR>:unlet unfoldview\<CR>zv"
        \ .":call feedkeys('".(visual ? 'gv' : '')
        \ .type."\<C-v>\<C-u>".cmd."', 't')\<CR>"
endfunc " }}}
cnoremap <silent> <expr> <C-o> <SID>UnfoldSearch()

" Go to next/previous match without exiting search command line
func! s:IncSearchNext(dir) " {{{
    let type = getcmdtype()
    if type !~ '[/?]' | return '' | endif
    let visual = mode() =~? "[v\<C-v>]"
    let cmd = substitute(getcmdline(), "'", "''", 'g')
    return "\<C-c>:\<C-u>call search('".cmd."', '".(a:dir ? '' : 'b')."')\<CR>zv".s:UnfoldSearch()
endfunc " }}}
cnoremap <silent> <expr> <C-j> <SID>IncSearchNext(1)
cnoremap <silent> <expr> <C-k> <SID>IncSearchNext(0)

" Search without saving when in command line window
func! s:SearchWithoutSave() " {{{
    let @/ = getcmdline()
    return ''
endfunc " }}}
augroup VimrcAutocmds
    autocmd CmdwinEnter * if expand('<afile>') =~ '[/?]' |
        \     execute 'cnoremap <expr> <CR> getcmdtype() =~ "[/?]" ?
        \         "\<C-\>e<SID>SearchWithoutSave()\<CR>\<CR>" : "\<C-]>\<CR>"' |
        \ endif
    autocmd CmdwinLeave * silent! cunmap <CR>
augroup END

" Print number of occurrences of last search without moving cursor
func! s:PrintCount(visual) " {{{
    let l:view = winsaveview() | let l:gd = &gdefault | set nogdefault
    redir => l:cnt
    execute 'keepjumps silent '.(a:visual ? "'<,'>" : '%').'s///gne'
    redir END
    keepjumps call winrestview(l:view)
    echo l:cnt =~ 'match' ? substitute(l:cnt,'\n','','') : 'No matches'
    let &gdefault = l:gd
endfunc " }}}
nn <silent> <M-n> :call <SID>PrintCount(0)<CR>
vn <silent> <M-n> :<C-u>call <SID>PrintCount(1)<CR>

" Put spaces around a character/visual selection
func! s:SpacesAround() " {{{
    call SaveRegs()
    if mode() == 'n'
        let ret = "s \<C-r>\" \<Esc>h`["
    elseif mode() =~# 'V'
        let ret = "\<C-v>$A \<Esc>gv0I \<Esc>`<"
    elseif mode() =~# 'v'
        let ret = "s \<C-r>\" \<Esc>h`<"
    elseif mode() == "\<C-v>"
        let ret = "A \<Esc>gvI \<Esc>`<"
    endif
    call RestoreRegs()
    silent! call repeat#set("g\<Space>")
    return ret
endfunc " }}}
nn <silent> <expr> g<Space> <SID>SpacesAround()
vn <silent> <expr> g<Space> <SID>SpacesAround()

" Show human-readable timestamp in zsh history file
func! s:EchoHistTime() " {{{
    let line = getline(search('^:\s*\d*:', 'bcnW')) | if !len(line) | return | endif
    redraw | let fmt = len($DATEFMT) ? $DATEFMT : '%a %d%b%y %T'
    echo strftime(fmt, line[2:11])
endfunc " }}}
autocmd VimrcAutocmds CursorMoved $HOME/.histfile call s:EchoHistTime()

" Insert search match (as opposed to <C-r>/)
function! s:InsertSearchResult() " {{{
    let view = winsaveview() | call SaveRegs()
    try
        silent normal! ggn
        call winrestview(view)
        keepjumps normal! gny
        return @@
    catch
        return ''
    finally
        call winrestview(view) | call RestoreRegs()
    endtry
endfunction " }}}
inoremap <silent> <C-]> <C-r><C-r>=<SID>InsertSearchResult()<CR>

" Check if location list (rather than quickfix)
func! s:IsLocationList() " {{{
    redir => l:filename | file | redir END
    return match(l:filename, 'Location List') > -1
endfunc " }}}

" Operator map to move to opening pair if outside pair else closing pair
func! s:ToPair(visual) " {{{
    let l:matchpairs = &matchpairs
    let &matchpairs = '(:),{:},[:],<:>'
    try
        if a:visual
            call setpos('.', getpos("'>"))
        endif
        let pos = getpos('.')
        let lpos = getpos("'<")
        normal! %
        if getpos('.') != pos
            normal! %
        else
            let quote = searchpos('[''"]', 'n', line('.'))
            if quote[0] == line('.')
                execute "normal! ".quote[1]."|"
            endif
        endif
        if a:visual && getpos('.') != pos
            execute "normal! ".getpos("'<")[2]."|v".getpos(".")[2]."|h"
        endif
    finally
        let &matchpairs = l:matchpairs
        echo
    endtry
endfunc " }}}
onoremap <silent> g[ :<C-u>call <SID>ToPair(0)<CR>
xnoremap <silent> g[ :<C-u>call <SID>ToPair(1)<CR>

" Execute q macro recursively
func! s:RecursiveQ() " {{{
    let l:q = getreg('q')
    set nowrapscan
    let @q = @q.'@q'
    normal! @q
    call setreg('q', l:q)
    set wrapscan eventignore=
endfunc " }}}
nnoremap <silent> <Leader>q :<C-u>call <SID>RecursiveQ()<CR>

" Replace : with newlines and do the opposite before exiting
func! s:Vared() " {{{
    execute 'keeppatterns s/:/\r/e'.(&gdefault ? '' : 'g')
    execute 'autocmd VimLeavePre * execute "silent! keeppatterns 1,$-1s'.
        \ '/\\n\\ze\\s*\\S/:/'.(&gdefault ? '' : 'g').'e" | wq'
endfunc " }}}
command! -nargs=0 Vared call s:Vared()

" Restore `[ and `] marks after saving a file
func! s:SaveMarks()
    let s:left_mark = getpos("'[")
    let s:right_mark = getpos("']")
endfunc
func! s:RestoreMarks()
    if exists('s:left_mark') && exists('s:right_mark')
        call setpos("'[", s:left_mark)
        call setpos("']", s:right_mark)
    endif
endfunc
if v:version >= 704 || (v:version == 703 && has('patch867'))
    autocmd VimrcAutocmds CursorMoved,TextChanged,InsertLeave * call s:SaveMarks()
else
    autocmd VimrcAutocmds CursorMoved,InsertLeave * call s:SaveMarks()
endif
autocmd VimrcAutocmds BufWritePost * call s:RestoreMarks()

" Turn off diffs automatically
if s:hasvimtools
    nnoremap <silent> [od :<C-u>call vimtools#DiffThis()<bar>echo 'DiffThis'<CR>
    nnoremap <silent> ]od :<C-u>call vimtools#DiffOff()<bar>echo 'DiffOff'<CR>
    nnoremap <silent> cod :<C-u>call vimtools#ToggleDiff()<CR>
endif

" Don't save search when using / or ? as an operator
func! s:OmapSlash(char) " {{{
    augroup omap_slash
        autocmd!
        if v:version >= 704 || (v:version == 703 && has('patch867'))
            autocmd CursorMoved,TextChanged * call s:CheckSearch() | autocmd! omap_slash
        else
            autocmd CursorMoved * call s:CheckSearch() | autocmd! omap_slash
        endif
    augroup END
    let s:saved_search = getreg('/')
    return a:char
endfunc " }}}
func! s:CheckSearch() " {{{
    if getreg('/') != s:saved_search
        call histdel('/', -1)
        call setreg('/', s:saved_search)
        set nohlsearch | set hlsearch | redraw!
    endif
endfunc " }}}
onoremap <expr> / <SID>OmapSlash('/\v')
onoremap <expr> ? <SID>OmapSlash('?\v')

" Check if in command line window
if exists('*getcmdwintype')
    func! s:inCmdWin() abort " {{{
        return getcmdwintype() !=# ''
    endfunc
else
    func! s:inCmdWin() abort
        return g:inCmdwin
    endfunc " }}}
endif

" Make @: work immediately after restarting vim
function! s:ex_repeat() " {{{
    if len(getreg(':')) && @: !~# '^Rem\%[ove]$' | return "@:" | endif
    let num = -1
    while histget(':', num) =~# '^Rem\%[ove]$' | let num -= 1 | endwhile
    echo ':' . histget(':', num)
    return ":\<C-u>execute histget(':', " . num . ")\<CR>"
endfunction " }}}
nnoremap <silent> <expr> @: <SID>ex_repeat()
" }}}

" {{{ GUI configuration
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
        let &guifont = 'DejaVu Sans Mono for Powerline:h12'

        " Start in fullscreen mode
        autocmd VimrcAutocmds VimEnter * sil! set fullscreen
    else
        " Use text-only tabline (prevent resizing issues)
        set guioptions-=e

        " Set font for gVim
        let &guifont = 'DejaVu Sans Mono for Powerline 9'
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
    execute "set <S-F1>=\e[1;2P"   | execute "set <S-F2>=\e[1;2Q"
    execute "set <S-F3>=\e[1;2R"   | execute "set <S-F4>=\e[1;2S"
    execute "set <S-F5>=\e[15;2~"  | execute "set <S-F6>=\e[17;2~"
    execute "set <S-F7>=\e[18;2~"  | execute "set <S-F8>=\e[19;2~"
    execute "set <S-F9>=\e[20;2~"  | execute "set <S-F10>=\e[21;2~"
    execute "set <S-F11>=\e[23;2~" | execute "set <S-F12>=\e[24;2~"

    " Shift + arrow keys
    exe "set <S-Left>=\<Esc>[1;2D <S-Right>=\<Esc>[1;2C <S-Down>=\<Esc>[1;2B <S-Up>=\<Esc>[1;2A"
    for d in ['Up', 'Down', 'Right', 'Left'] | execute "inoremap \<S-".d."> \<nop>" | endfor

    " Change tab in XTerm
    "         <C-Tab>              <C-S-Tab>
    exec "set <F15>=\<Esc>[27;5;9~ <F16>=\<Esc>[27;6;9~"

    " Use correct background color
    autocmd VimrcAutocmds VimEnter * set t_ut=

    " Use block cursor in normal mode, bar in insert mode, and underline in replace mode
    if !mobileSSH
        let &t_SI = "\<Esc>[5 q"
        let &t_EI = "\<Esc>[1 q"
        if v:version > 704 || (v:version == 704 && has('patch687'))
            let &t_SR = "\<Esc>[3 q"
        endif
    endif

    " Disable italics (set italics mode = italics end)
    let &t_ZH = &t_ZR

    " Enable mouse for scrolling and window selection
    set mouse=nir
    noremap <F22> <NOP>
    noremap <F21> <LeftMouse>
    for b in ["Left","Middle","Right"] | for m in ["","2","3","4","C","S","A"]
        execute 'map <'.m.(strlen(m)?'-':'').b.'Mouse> <NOP>'
    endfor | endfor | map <expr> <LeftMouse> winnr('$')>1?"\<F21>":"\<F22>"
endif

" }}}

" Create new buffer with filetype as (optional) argument
for cmd in ['new', 'enew', 'vnew', 'tabedit']
    execute "command! -nargs=? -complete=filetype ".toupper(cmd[0]).cmd[1:]." ".cmd." | ".
        \ "if !empty('<args>') | set filetype=<args> | "
        \ "else | let &filetype= getbufvar('#', '&filetype') | endif"
endfor

" Increase time allowed for keycode mappings over SSH
if mobileSSH
    set ttimeoutlen=250
elseif hasSSH
    set ttimeoutlen=100
endif

augroup VimrcAutocmds " {{{
    " Don't auto comment new line made with 'o', 'O', or <CR>
    autocmd FileType * exe "set fo-=o" | exe "set fo-=r"

    " Use line wrapping for plain text files (but not help files)
    autocmd FileType text setl wrap linebreak
    autocmd FileType help setl nowrap nolinebreak concealcursor=

    " Indent line continuation for conf files
    autocmd FileType conf setl indentexpr=getline(v:lnum-1)=~'\\\\$'?&sw:0

    " Prefer single-line style comments and fix shell script comments
    autocmd FileType cpp,arduino setl commentstring=//%s
    autocmd FileType python,crontab,txt,applescript setl commentstring=#%s
    autocmd FileType * if &cms=='# %s' | setl cms=#%s | endif
    autocmd FileType dosbatch setl commentstring=REM%s
    autocmd FileType autohotkey setl commentstring=;%s

    " Settings for git commit messages
    autocmd FileType gitcommit setlocal spell colorcolumn=50

    " Highlight current line in active window but not in insert mode
    autocmd BufRead,BufNewFile,VimEnter * set cursorline
    autocmd InsertLeave,WinEnter,FocusGained * set cursorline
    autocmd InsertEnter,WinLeave,FocusLost * set nocursorline

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
    au CmdwinEnter * call s:CmdwinMappings()

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
        \ if get(g:, 'reload_dos', 1) && !exists('b:reload_dos') && !&binary && &ff == 'unix'
        \       && (0 < search('\r$', 'nc')) && &buftype == ''
        \       && expand('<afile>') !~? '\v(^fugitive)|(\.(diff|rej|patch)$)' |
        \     let b:reload_dos = 1 |
        \     e ++ff=dos |
        \ endif

    " Fix help buftype after loading session
    autocmd SessionLoadPost *.txt if &filetype == 'help' | set buftype=help | endif

    " showcmd causes Vim to start in replace mode sometimes
    autocmd VimEnter * set showcmd

    " Set global variable on FocusLost
    autocmd FocusLost * let g:focuslost = 1 | silent! call lightline#update()
    autocmd FocusGained,CursorMoved,CursorMovedI *
        \ if exists('g:focuslost') |
        \     unlet g:focuslost | silent! call lightline#update() |
        \ endif

    " Save position of last text change
    if v:version >= 704 || (v:version == 703 && has('patch867'))
        autocmd TextChanged,TextChangedI *
            \ if &buflisted && &buftype == '' |
            \     let g:last_change_buf = bufnr('%') |
            \ endif
    endif

    " Jump to quickfix result in previous window
    autocmd FileType qf nn <silent> <buffer> <CR> :execute "wincmd p \| "
        \ .line('.').(<SID>IsLocationList() ? "ll" : "cc")<CR>zv

    " Open files as read-only automatically
    autocmd SwapExists * let v:swapchoice = 'o' | let b:swapname = v:swapname

    " Remove quit command from history
    autocmd VimEnter * call histdel(':', '^w\?q\%[all]!\?$')

    " Preserve previous window when preview window opens during completion
    autocmd InsertEnter * let s:pwinid += 1 | call setwinvar(winnr('#'), 'pwin', s:pwinid)
    autocmd InsertLeave * if winnr('$') > 2 && getwinvar(winnr('#'), 'pwin') != s:pwinid |
        \ silent! call s:RestorePrevWin() | endif
augroup END " }}}

" Restore previous windo after leaving insert mode
if !exists('s:pwinid') | let s:pwinid = 0 | endif
func! s:RestorePrevWin() abort " {{{
    let winnr = winnr()
    wincmd P
    if winnr != winnr() && line('$') < &previewheight
        execute "resize ".line('$')
    endif
    for w in range(1, winnr('$'))
        if getwinvar(w, 'pwin') == s:pwinid
            let pwin = w
            break
        endif
    endfor
    if exists('l:pwin')
        execute l:pwin.'wincmd w'
        execute winnr.'wincmd w'
    endif
endfunc " }}}

" Strip ANSI color codes in vimpager for diffs
let g:ansi_pattern = "\\v\e\\[([0-9]{1,2}(;[0-9]{1,2})*)?[mK]"
if exists('vimpager')
    augroup diff_syntax
        autocmd!
        autocmd CursorMoved *
            \ if search("\\v^(\e".'\[(\d+;)*\d+m)*\@+\s*([+-]\d+,\d+\s+)+\@+', 'n', 50) > 0 |
            \     execute 'silent keeppatterns %s#'.g:ansi_pattern.'##e'.(&gdefault ? '' : 'g') |
            \     set filetype=diff | execute "normal! gg0" |
            \ endif | execute 'autocmd! diff_syntax'
    augroup END
endif

" Try to detect git repository for git log
autocmd VimrcAutocmds VimEnter * if exists('vimpager')|silent! call fugitive#detect(getcwd())|endif

" Match highlighting
func! s:MatchHighlights() " {{{
    for n in range(1, 5)
        execute "highlight Match".n." ctermbg=".(&bg=='dark'?0:7)." ctermfg=".(7 - n).""
    endfor
endfunc " }}}
func! s:MatchAdd(n) " {{{
    call s:MatchHighlights()
    autocmd VimrcAutocmds ColorScheme * call s:MatchHighlights()
    execute "call matchadd('Match".a:n."',  '".(substitute(@/,
        \ '^\\[vV]', '', '')=~'\u'?'':'\c').@/."', 0)"
endfunc " }}}
for n in range(1, 5)
    execute 'nnoremap <silent> <Leader>h'.n.' :<C-u>call <SID>MatchAdd('.n.')<CR>'
endfor
nnoremap <Leader>hc :<C-u>call clearmatches()<CR>

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
let vsound = 340.29
let vsoundfps = vsound * m2ft
let assignments_pattern = '\v[=!<>]@<![+|&^.]?\=[=~]@!'
let maps_pattern = '\v<([lnvx]n%[oremap]|([cilovx]u)%[nmap]|'.
    \'(no|[cio]no)%[remap]|([cilnosvx]?mapc)%[lear]|'.
    \'([cilnosvx]|un|sun)m%[ap]|map|nun%[map]|smap|snor%[emap])>'

" Abbreviation template {{{
func! s:CreateAbbrev(lhs, rhs, cmdtype, ...) " {{{
    if a:0
        execute 'cnoreabbrev <expr> '.a:lhs.' getcmdtype() =~ "['.a:cmdtype
            \ .']" && getcmdline() == '''.a:1.a:lhs.''' ? "'.a:rhs.'" : "'.a:lhs.'"'
    else
        execute 'cnoreabbrev <expr> '.a:lhs.' getcmdtype() =~ "['.a:cmdtype
            \ .']" && getcmdpos() <= '.(len(a:lhs) + 1).' ? "'.a:rhs.'" : "'.a:lhs.'"'
    endif
endfunc " }}}
let ls_sort = has('mac') ? ' --sort=none' : ''
call s:CreateAbbrev('ve',   'verbose',                         ':>'  )
call s:CreateAbbrev('so',   'source',                          ':'   )
call s:CreateAbbrev('ec',   'echo',                            ':@>' )
call s:CreateAbbrev('es',   'echo string',                     ':@>' )
call s:CreateAbbrev('dt',   'diffthis',                        ':'   )
call s:CreateAbbrev('do',   'diffoff \| set nowrap',           ':'   )
call s:CreateAbbrev('du',   'diffupdate',                      ':'   )
call s:CreateAbbrev('vd',   'vertical diffsplit',              ':'   )
call s:CreateAbbrev('wi',   'Windo',                           ':'   )
call s:CreateAbbrev('ca',   'call',                            ':>'  )
call s:CreateAbbrev('m',    'make',                            ':'   )
call s:CreateAbbrev('mcl',  'make clean',                      ':'   )
call s:CreateAbbrev('min',  'make install',                    ':'   )
call s:CreateAbbrev('mup',  'make upload',                     ':'   )
call s:CreateAbbrev('pp',   'PP',                              ':>'  )
call s:CreateAbbrev('bd',   'breakdel',                        '>'   )
call s:CreateAbbrev('bc',   'breakdel *',                      '>'   )
call s:CreateAbbrev('Qa',    'qa',                             ':'   )
call s:CreateAbbrev('Qa!',   'qa!',                            ':'   )
call s:CreateAbbrev('qa1',   'qa!',                            ':'   )
call s:CreateAbbrev('E',     'e',                              ':'   )
call s:CreateAbbrev('csa',  'cscope add',                      ':'   )
call s:CreateAbbrev('csf',  'cscope find',                     ':'   )
call s:CreateAbbrev('csk',  'cscope kill -1',                  ':'   )
call s:CreateAbbrev('csr',  'cscope reset',                    ':'   )
call s:CreateAbbrev('css',  'cscope show',                     ':'   )
call s:CreateAbbrev('csh',  'cscope help',                     ':'   )
call s:CreateAbbrev('vc',   'cd $VIMCONFIG',                   ':'   )
call s:CreateAbbrev('vcb',  'cd $VIMCONFIG/vimfiles/bundle',   ':'   )
call s:CreateAbbrev('l',    'ls -h --color=auto'.ls_sort,      ':',  '!')
call s:CreateAbbrev('ls',   'ls -h --color=auto'.ls_sort,      ':',  '!')
call s:CreateAbbrev('la',   'ls -hA --color=auto'.ls_sort,     ':',  '!')
call s:CreateAbbrev('ll',   'ls -lsh --color=auto'.ls_sort,    ':',  '!')
call s:CreateAbbrev('lls',  'ls -lshrt --color=auto',          ':',  '!')
call s:CreateAbbrev('lla',  'ls -lshA --color=auto'.ls_sort,   ':',  '!')
call s:CreateAbbrev('llas', 'ls -lshrtA --color=auto',         ':',  '!')
call s:CreateAbbrev('py',   'python %',                        ':',  '!')
if has('win32unix') || has('win64unix')
    call s:CreateAbbrev('open', 'cygstart', ':', '!')
endif " }}}

" Other abbreviations
let b = '((\\)@<!\\)' " Unescaped backslash
let g:global_command_pattern = '\v\C^[^/]*(v?g%[lobal]|v)!?/([^/]|'.b.'@<=/)*'.b.'@<!/'
cnoreabbrev <expr> ex (getcmdtype()==':'&&getcmdpos()<=3)
    \ \|\| (getcmdline() =~ g:global_command_pattern.'ex$') ? 'execute':'ex'
cnoreabbrev <expr> no (getcmdtype()==':'&&getcmdpos()<=3)
    \ \|\| (getcmdline() =~ g:global_command_pattern.'no$') ? 'normal':'no'
cnoreabbrev <expr> VC getcmdline() =~ '\v<VC' ? expand('$VIMCONFIG') : 'VC'
cnoreabbrev <expr> VCB getcmdline() =~ '\v<VCB' ?
    \ expand('$VIMCONFIG').'/vimfiles/bundle' : 'VCB'
cnoreabbrev <expr> dg getcmdline() =~ '^\(%\<bar>''<,''>\)dg$' ? 'diffget' : 'dg'
cnoreabbrev <expr> do getcmdline() =~ '^\(%\<bar>''<,''>\)do$' ? 'diffget' : 'do'
cnoreabbrev <expr> dp getcmdline() =~ '^\(%\<bar>''<,''>\)dp$' ? 'diffput' : 'dp'

" Don't clobber registers from select mode
snoremap <Space> <C-g>"_c<Space>
snoremap \| <C-g>"_c\|
for c in range(33, 124) + [126]
    execute "snoremap ".escape(nr2char(c), '|')." <C-g>\"_c".escape(nr2char(c), '|')
endfor
" }}}

" {{{ Plugin configuration

" Make empty list of disabled plugins
if !exists('g:pathogen_disabled')
    let g:pathogen_disabled=[]
endif

" Only enable misc/shell in Windows
if !hasWin | call extend(g:pathogen_disabled, ['misc','shell']) | endif

" Disable some plugins if in read-only mode
if s:readonly
    call add(g:pathogen_disabled, 'neocomplete')
    call add(g:pathogen_disabled, 'neosnippet')
    call add(g:pathogen_disabled, 'neosnippet-snippets')
    call add(g:pathogen_disabled, 'pymode')
    call add(g:pathogen_disabled, 'scriptease')
    call add(g:pathogen_disabled, 'tabular')
    call add(g:pathogen_disabled, 'targets')
    call add(g:pathogen_disabled, 'vcscommand')
    call add(g:pathogen_disabled, 'vimfiler')
endif

" lightline configuration
let g:lightline_powerline_fonts = !mobileSSH && v:version >= 703
runtime! plugin/lightline_config.vim
nnoremap <silent> <M-w> :<C-u>call whitespace#toggle()<CR>

" Shortcut to force close buffer without closing window
nnoremap <silent> <Leader><Leader>bd :Bclose!<CR>

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr=1
let OmniCpp_MayCompleteScope=1
autocmd VimrcAutocmds CursorMovedI,InsertLeave c,cpp
    \ if pumvisible() == 0 | silent! pclose | endif

" Commentary configuration
let g:commentary_map_backslash=0

" {{{ Completion settings
if has('lua') && $VIMBLACKLIST !~? 'neocomplete'
    call add(g:pathogen_disabled, 'supertab')

    if !s:readonly
        " NeoComplete settings
        let g:neocomplete#enable_at_startup=1
        let g:neocomplete#enable_smart_case=1
        let g:neocomplete#max_list=200
        let g:neocomplete#min_keyword_length=4
        let g:tmuxcomplete#trigger=''
        if !exists('g:neocomplete#keyword_patterns')
            let g:neocomplete#keyword_patterns = {}
        endif
        let g:neocomplete#keyword_patterns._ = '\h\w*'
        let g:neocomplete#keyword_patterns['default'] = '\h\w*'
        let g:neocomplete#keyword_patterns.matlab =
            \ '\h\w*\(\(\.\((''\?\)\?\w*\('')\?\)\?\)\+'
            \ .'\|{\d\+}\(\.\((''\?\)\?\w*\('')\?\)\?\)\+'
            \ .'\|{\d*\}\?\)\?'
        func! s:StartManualComplete(dir)
            " Indent if only whitespace behind cursor
            if pumvisible() || getline('.')[virtcol('.')-2] =~ '\S'
                return pumvisible() ? (a:dir ? "\<C-n>" : "\<C-p>")
                    \: (neocomplete#helper#get_force_omni_complete_pos(
                    \   neocomplete#get_cur_text(1)) >= 0 ?
                    \      "\<C-x>\<C-o>\<C-r>=neocomplete#mappings#popup_post()\<CR>" :
                    \      neocomplete#start_manual_complete())
            else
                return a:dir ? "\<Tab>" : "\<BS>"
            endif
        endfunc
        inoremap <silent> <expr> <Tab>   <SID>StartManualComplete(1)
        inoremap <silent> <expr> <S-Tab> <SID>StartManualComplete(0)
        inoremap <silent> <expr> <C-f>   pumvisible() ? neocomplete#close_popup()
            \ : matchstr(getline(line('.')+1),'\%'.virtcol('.').'v\%(\S\+\\|\s*\)')
        imap     <expr> <C-d>   neosnippet#expandable_or_jumpable()?
            \ "\<Plug>(neosnippet_expand_or_jump)":
            \ (pumvisible() ? neocomplete#close_popup() : "\<C-d>")
        smap <C-d> <Plug>(neosnippet_expand_or_jump)
        imap <C-x><C-h> <Plug>(complete_ipython_history)
        imap <C-h> <Plug>(insert_ipython_history)
        inoremap <silent> <expr> <C-l>
            \ pumvisible() && &completefunc ==# 'neocomplete#sources#lines#complete' ?
            \ "\<C-p>" : neocomplete#complete_common_string()
        inoremap <silent> <expr> <C-x><C-w> neocomplete#sources#words#start()
        inoremap <silent> <expr> <C-x><C-l> neocomplete#sources#lines#start()
        nnoremap <silent> ,n :<C-u>NeoCompleteToggle<CR>
        " Make <BS> delete letter instead of clearing completion
        inoremap <BS> <BS>
        execute 'inoremap <C-Tab> '.repeat('<C-n>', 10)
        execute 'inoremap <C-S-Tab> '.repeat('<C-p>', 10)
        augroup VimrcAutocmds
            autocmd CmdwinEnter * inoremap <silent> <buffer> <expr> <Tab>
                \ pumvisible() ? "\<C-n>" : neocomplete#start_manual_complete()
            autocmd CmdwinEnter * inoremap <silent> <buffer> <expr> <S-Tab>
                \ pumvisible() ? "\<C-p>" : neocomplete#start_manual_complete()
            autocmd VimrcAutocmds CmdwinEnter : let b:neocomplete_sources =
                \ ['vim', 'file', 'words', 'syntax', 'buffer']
            autocmd InsertLeave * if &ft=='vim' | sil! exe 'NeoCompleteVimMakeCache' | en
            autocmd TextChangedI * let s:omni = 0
        augroup END

        function! s:ResetCompletion() abort " {{{
            let neocomplete = neocomplete#get_current_neocomplete()
            for source in values(neocomplete.sources)
                let context = source.neocomplete__context
                let context.prev_candidates = []
                let context.prev_complete_pos = -1
                let context.prev_line = ''
            endfor
            return neocomplete#start_manual_complete()
        endfunction " }}}
        inoremap <silent> <expr> <C-x><C-x> <SID>ResetCompletion()
        inoremap <silent> <expr> _ '_' .
            \ (&filetype ==# 'python' && &l:omnifunc ==# 'CompleteIPython' &&
            \  neocomplete#get_cur_text()[-1:] == '.' ? <SID>ResetCompletion() : '')
    endif
else
    call add(g:pathogen_disabled, 'neocomplete')
    let g:SuperTabDefaultCompletionType="context"
    imap <C-d> <Plug>(neosnippet_expand_or_jump)
    smap <C-d> <Plug>(neosnippet_expand_or_jump)
    silent! set shortmess+=c
endif
" }}}

" {{{ Sneak settings
let g:sneak#streak=1
let g:sneak#use_ic_scs=1
autocmd VimrcAutocmds ColorScheme * call s:SneakHighlights()
func! s:SneakHighlights() " {{{
    let fg = &background == 'dark' ? 8 : 15 | let gui = 'gui=reverse guifg=#'
    execute "highlight! SneakPluginTarget cterm=reverse ctermbg=".fg." ctermfg=4 ".gui."268bd2"
    execute "highlight! SneakStreakTarget cterm=bold,reverse ctermbg="fg." ctermfg=2 ".gui."859900"
    execute "highlight! SneakStreakMask cterm=reverse ctermbg=".(fg-8)." ctermfg=2 ".gui."859900"
    execute "highlight! SneakStreakCursor cterm=reverse ctermbg=".fg." ctermfg=1 ".gui."dc322f"
    highlight! link SneakStreakStatusLine StatusLine
endfunc " }}}
func! s:SneakMaps() " {{{
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
        if v:version > 704 || (v:version == 704 && has('patch79'))
            nnoremap <silent> <expr> <C-l> sneak#is_sneaking() ?
                \ sneak#cancel() : (v:hlsearch ? ':<C-u>nohlsearch<CR>' : '<C-l>')
        else
            nnoremap <silent> <expr> <C-l> sneak#is_sneaking() ? sneak#cancel() : '<C-l>'
        endif
    endif
endfunc " }}}
autocmd VimrcAutocmds VimEnter * call s:SneakMaps()
call s:SneakMaps()
" }}}

" {{{ VimFiler settings
nnoremap <silent> - :VimFilerBufferDir -find<CR>
nnoremap <silent> <Leader>- :VimFilerExplorer -find <C-r>=
    \ vimfiler#helper#_get_buffer_directory(bufnr('%'))<CR><CR>
nnoremap <silent> <C-_> :VimFilerCurrentDir -find<CR>
nnoremap <silent> <Leader><C-_> :VimFilerExplorer -find <C-r>=getcwd()<CR><CR>
let g:vimfiler_as_default_explorer=1
if stridx($VIMBLACKLIST, 'vimfiler') == -1
    let g:loaded_netrwPlugin=1
endif
nn <silent> gx :call netrw#BrowseX(expand("<cfile>"),0)<CR>
let g:vimfiler_tree_leaf_icon=' '
let g:vimfiler_file_icon='-'
if v:version > 704 || (v:version == 704 && has('patch651'))
    let g:vimfiler_tree_opened_icon='▼'
    let g:vimfiler_tree_closed_icon='▶'
endif
let g:vimfiler_marked_file_icon='✓'
let g:vimfiler_ignore_pattern = '^\.\|.*\.'.
    \ '\(DS_Store\|a\|bak\|d\|dll\|exe\|hi\|info\|lib\|o\|obj\|pyc\|so\|spi\|swp\)$'
let g:vimfiler_restore_alternate_file=0
let g:vimfiler_time_format='%a %d%b%Y %H:%M'
let g:vimfiler_force_overwrite_statusline=0
autocmd VimrcAutocmds FileType vimfiler call s:VimfilerSettings()
func! s:VimfilerSettings() " {{{
    nmap <buffer> m     <Plug>(vimfiler_toggle_mark_current_line)
    nmap <buffer> <M-m> <Plug>(vimfiler_move_file)
    nmap <buffer> <BS>  <Plug>(vimfiler_close)
    nmap <buffer> -     <Plug>(vimfiler_switch_to_parent_directory)
    nmap <buffer> <F1>  <Plug>(vimfiler_help)
    nmap <buffer> <CR>  <Plug>(vimfiler_expand_or_edit)
    nmap <buffer> e     <Plug>(vimfiler_cd_or_edit)
    nmap <buffer> D     <Plug>(vimfiler_delete_file)
    nmap <buffer> <C-s> <Plug>(vimfiler_select_sort_type)
    nmap <buffer> S     <Plug>(vimfiler_select_sort_type)
    nmap <buffer> <Tab> <Plug>(vimfiler_choose_action)
    nmap <buffer> gN    <Plug>(vimfiler_new_file)
    xmap <buffer> *     <Plug>(vimfiler_toggle_mark_selected_lines)
    nmap <buffer> g/    <Plug>(vimfiler_set_current_mask)
    xmap <expr> <buffer> q "\<Esc>\<Plug>(vimfiler_hide)"
    xmap <expr> <buffer> Q "\<Esc>\<Plug>(vimfiler_exit)"
    nnoremap <buffer> got :<C-U>call gtfo#open#term(b:vimfiler.current_dir, "")<CR>
    nnoremap <buffer> gOt :<C-U>call gtfo#open#term(b:vimfiler.current_dir, "win")<CR>
    for map in ['<Space>', 'L', 'M', 'H', '<S-Space>', 'N', 'go', '<Leader>', 'gS', 'gv']
        execute 'silent! nunmap <buffer>' map
    endfor
    silent! call fugitive#detect(expand('%:p'))
endfunc " }}}
" }}}

" {{{ Unite settings
let g:unite_source_history_yank_enable=1
let g:unite_source_history_yank_limit=500
let g:unite_marked_icon='✓'
let g:unite_cursor_line_highlight='CursorLine'
if executable('ag')
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts = "--vimgrep --hidden -S " .
        \ "--ignore '.hg' --ignore '.svn' --ignore '.git' --ignore '.bzr'"
    let g:unite_source_grep_recursive_opt = ''
    let g:unite_source_rec_async_command =
        \ ['ag', '--follow', '--nocolor', '--nogroup', '--hidden', '-g', '']
endif
let g:unite_source_grep_search_word_highlight='WarningMsg'
let g:unite_source_history_yank_save_registers=['"', '+', '*']
let g:unite_kind_cdable_cd_command='Windo silent! cd'
let g:unite_force_overwrite_statusline=0
let g:unite_source_output_shellcmd_colors = [
    \ '#073642', '#dc322f', '#859900', '#b58900', '#268bd2', '#d33682', '#2aa198', '#eee8d5',
    \ '#002b36', '#cb4b16', '#586e75', '#657b83', '#839496', '#6c71c4', '#93a1a1', '#fdf6e3']
call s:CreateAbbrev('U', 'Unite -start-insert', ':')
call s:CreateAbbrev('u', 'Unite -start-insert', ':')
augroup VimrcAutocmds
    autocmd VimEnter * if exists(':Unite') | call s:UniteSetup() | endif
    autocmd FileType unite call s:UniteSettings()
    autocmd CursorHold * silent! call neoyank#_append()
augroup END

function! s:prev_bufnr(bufnr) abort " {{{
    silent! let unite = getbufvar(a:bufnr, 'unite')
    if type(unite) != type({}) || bufwinnr(a:bufnr) < 1 | return | endif
    let bufnr = winbufnr(winnr('#'))
    if index(['help', 'quickfix'], getbufvar(bufnr, '&buftype')) == -1
        let unite.prev_bufnr = bufnr
    endif
endfunction " }}}
func! s:UniteSettings() " {{{
    imap <silent> <buffer> <expr> <C-q> unite#do_action('delete')
        \."\<Plug>(unite_append_enter)"
    nnor <silent> <buffer> <expr> <C-q> unite#do_action('delete')
    imap <silent> <buffer> <expr> <C-d> <SID>UniteTogglePathSearch()."\<Esc>"
        \.'1G0y$Q'.":\<C-u>Unite -buffer-name=buffers/neomru "
        \."-unique buffer neomru/file\<CR>"."\<C-r>\""
    nnor <buffer> <expr> yy unite#do_action('yank').'<Plug>(unite_exit)'

    function! s:ni_map(key1, key2, action, ...) abort
        for mode in ['n', 'i']
            for key in [a:key1, a:key2]
                execute printf("%snoremap <buffer> <expr> %s unite#do_action('%s')%s",
                    \ mode, key, a:action, a:0 ? ('.''' . a:1 . '''') : '')
            endfor
        endfor
    endfunction
    call s:ni_map('<C-o><C-d>', '<C-o>d', 'vsplit', ':<C-u>call vimtools#ToggleDiff()<CR>')
    call s:ni_map('<C-o><C-v>', '<C-o>v', 'vsplit')
    call s:ni_map('<C-o><C-s>', '<C-o>s', 'split')
    call s:ni_map('<C-o><C-t>', '<C-o>t', 'tabopen')
    call s:ni_map('<C-^>',      '<C-^>',  'persist_open')

    nmap <buffer> <expr> <silent> ` stridx(join(b:unite.source_names), 'grep') == -1
        \ ? '<Plug>(unite_exit)'
        \ : ':call <SID>LastActiveWindow()<CR>'
    nmap <buffer> <expr> <C-s> unite#mappings#set_current_sorters(
        \ unite#mappings#get_current_sorters() == [] ? ['sorter_ftime', 'sorter_reverse'] : [])
        \ . "\<Plug>(unite_redraw)"
    imap <buffer> <expr> <C-s> unite#mappings#set_current_sorters(
        \ unite#mappings#get_current_sorters() == [] ? ['sorter_ftime', 'sorter_reverse'] : [])
    imap <buffer> ` <Esc>`
    imap <buffer> <C-o> <Plug>(unite_choose_action)
    nmap <buffer> <C-o> <Plug>(unite_choose_action)
    inor <buffer> <C-b> <Home>
    inor <buffer> <C-e> <End>
    nmap <buffer> <C-f> <C-d>
    nmap <buffer> <C-b> <C-u>
    nmap <buffer> <C-p> <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-p> <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-j> <Plug>(unite_select_next_line)
    imap <buffer> <C-k> <Plug>(unite_select_previous_line)
    nmap <buffer> <C-c> <Plug>(unite_exit)
    imap <buffer> <C-c> <Plug>(unite_exit)
    nmap <buffer> m <Plug>(unite_toggle_mark_current_candidate)
    nmap <buffer> M <Plug>(unite_toggle_mark_current_candidate_up)
    nmap <buffer> <F1>  <Plug>(unite_quick_help)
    imap <buffer> <F1>  <Esc><Plug>(unite_quick_help)
    imap <buffer> <C-Space> <Plug>(unite_toggle_mark_current_candidate)
    imap <buffer> <C-@> <Plug>(unite_toggle_mark_current_candidate)
    imap <buffer> <C-n> <Esc><Plug>(unite_rotate_next_source)<Plug>(unite_insert_enter)
    inor <buffer> . \.
    inor <buffer> \. .
    inor <buffer> <expr> <BS>
        \ getline('.')[virtcol('.')-3:virtcol('.')-2] == '\.' ? '<BS><BS>' : '<BS>'
    inor <buffer> <C-r>% <C-r>#
    inor <buffer> <expr> <C-r>$ expand('#:t')
    nmap <buffer> a <Plug>(unite_append_enter)
    nmap <buffer> S <Plug>(unite_append_end)<Plug>(unite_delete_backward_line)
    nmap <buffer> s <Plug>(unite_append_enter)<BS>
    nmap <buffer> [u k<CR>
    nmap <buffer> ]u j<CR>
    nmap <buffer> [U gg<CR>
    nmap <buffer> ]U G<CR>
    nnor <buffer> <C-g> :<C-u>call <SID>modify_unite_options()<CR>
    xmap <buffer> * <Plug>(unite_toggle_mark_selected_candidates)
    nmap <buffer> ! <Plug>(unite_disable_max_candidates)
    for key in ['<Up>', '<Down>', '<Left>', '<Right>'] + split('?Nbet', '\zs')
        execute 'silent! nunmap <buffer> ' . key
    endfor
    silent! iunmap <buffer> <Space>
    autocmd WinEnter <buffer> call s:prev_bufnr(+expand('<abuf>'))
endfunc " }}}

function! s:grep(source, ...) abort " {{{
    let path = len(a:000) >= 1 ? a:1 :
        \ join(vimtools#flatten(map(split(input('Path: ', '.', 'file')),
        \                           'vimtools#glob(v:val)')), "\n")
    let opts = len(a:000) >= 2 ? a:2 : input(
        \ 'Options: ', a:source ==# 'grep' ? get(g:, 'ag_flags', '') : '')
    let inp = input('Pattern: ', '', 'customlist,vimtools#CmdlineComplete')
    if len(inp) | call histadd('/', inp) | call unite#start([[a:source, path, opts, inp]]) | endif
endfunction
function! s:modify_unite_options() abort
    let unite = unite#get_current_unite()

    if index(unite.source_names, 'buffer') != -1
        let context = unite#get_sources('buffer').unite__context
        let names = {'!': 'bang', '?': 'question', '+': 'plus', '-': 'minus', 't': 'terminal'}
        let flags = input('!: all, ?: non-listed, +: modified, -: files, t: terminal: ',
            \ join(filter(keys(names), 'get(context, "source__is_" . names[v:val], 0)'), ''))
        for [char, name] in items(names)
            let context['source__is_' . name] = stridx(flags, char) != -1
        endfor

    elseif stridx(join(unite.source_names), 'grep') != -1
        let context = map(filter(copy(unite#get_sources()), 'v:val.name =~ "grep"'),
            \             'v:val.unite__context')[0]
        let context.source__extra_opts = input('Options: ',
            \ join(split(g:ag_flags) + split(context.source__extra_opts)))

    elseif index(unite.source_names, 'history/ipython') != -1
        try
            let [ g:ipython_history_timeout,
                \ g:ipython_history_len,
                \ g:ipython_history_raw,
                \ g:ipython_history_unique] = map(split(input('timeout, length, raw, unique = ',
                \ printf('%s %s %s %s', get(g:, 'ipython_history_timeout', 2),
                \                       get(g:, 'ipython_history_len', 100),
                \                       get(g:, 'ipython_history_raw', 1),
                \                       get(g:, 'ipython_history_unique', 1))), '\s\+'), '+v:val')
        endtry

    else
        return
    endif
    call unite#force_redraw()
endfunction " }}}
nn <silent> ,a         :<C-u>call <SID>grep('grep', '.', get(g:, 'ag_flags', ''))<CR>
nn <silent> ,A         :<C-u>call <SID>grep('grep')<CR>
nn <silent> ,<Leader>a :<C-u>call <SID>grep('grep/git', '.', '')<CR>
nn <silent> ,<Leader>A :<C-u>call <SID>grep('grep/git')<CR>

nn <silent> "" :<C-u>Unite -start-insert history/yank<CR>
nn <silent> "' :<C-u>Unite -start-insert register<CR>
nn ,<C-a> :<C-u>Unite -no-quit -auto-resize grep:
com! -nargs=? -complete=file BookmarkAdd call unite#sources#bookmark#_append(<q-args>)
nn <silent> ,b :<C-u>Unite bookmark<CR>
nn <silent> ,vr :<C-u>Unite vimgrep:**/*<CR>
nn <silent> ,vn :<C-u>Unite vimgrep:**<CR>
nn <silent> <C-n> :<C-u>Unite -buffer-name=files file_rec/async<CR>
nn <silent> <C-h> :<C-u>Unite -buffer-name=buffers buffer<CR>
nn <silent> g<C-h> :<C-u>Unite -buffer-name=buffers buffer:+<CR>
nn <silent> <expr> <C-p> ":\<C-u>Unite -buffer-name="
    \ .(len(filter(range(1,bufnr('$')),'buflisted(v:val)')) > 1
    \ ? "buffers/" : "")."neomru ".(len(filter(range(1,bufnr('$')),
    \ 'buflisted(v:val)')) > 1 ? "buffer" : "")." -unique neomru/file\<CR>"
nn <silent> <M-p> :<C-u>Unite neomru/directory<CR>
nn <silent> <C-o> :<C-u>Unite file<CR>
nn <silent> <M-/> :<C-u>Unite line:all<CR>
nn <silent> <M-?> :<C-u>Unite line:all -input=`expand('<lt>cword>')`<CR>
nn <silent> g<C-p> :<C-u>Unite -buffer-name=neomru neomru/file<CR>
nn <silent> <F1> :<C-u>Unite mapping<CR>
nn <silent> <expr> <Leader>o ':<C-u>Unite -direction=' .
    \ (winnr() == 1 ? 'topleft' : 'botright') . ' -vertical -winwidth=60 outline<CR>'
nn <silent> ,h :<C-u>Unite history/ipython -max-multi-lines=100 -no-split -no-resize<CR>
xn <silent> ,h :<C-u>call SaveRegs()<CR>gvy:call unite#start([['history/ipython']], {
    \ 'input': @@, 'split': 0, 'auto_resize': 0, 'max_multi_lines': 100})<CR>
    \ <Esc>:call RestoreRegs()<CR>i
nn <silent> <M-h> :<C-u>Unite history/command<CR>
nn <silent> <Leader>vi :<C-u>Unite vimuxindex<CR>
nn <silent> g/ :<C-u>Unite line:buffers -input=\v<CR>
nn <silent> <Leader>w :cclose<bar>Windo lclose<bar>pclose<bar>silent! UniteClose<CR>
nn <silent> [u :<C-u><C-r>=v:count1<CR>UnitePrevious<CR>
nn <silent> ]u :<C-u><C-r>=v:count1<CR>UniteNext<CR>
nn <silent> [U :<C-u>UniteFirst<CR>
nn <silent> ]U :<C-u>UniteLast<CR>
nn <silent> ,u :<C-u>UniteResume -split<CR>
nn <silent> U :<C-u>Unite -direction=botright<CR>
nn <silent> <Leader>U :<C-u>call unite#mappings#_choose_action(
    \ unite#get_candidates([['file', expand('%')]], {'profile_name': 'all_files'}))<CR>
if !exists('s:UnitePathSearchMode') | let s:UnitePathSearchMode=0 | endif

func! s:UniteTogglePathSearch() " {{{
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
endfunc " }}}

func! s:UniteSetup() " {{{
    call unite#filters#matcher_default#use(['matcher_regexp'])
    call unite#custom#default_action('directory', 'cd')
    call unite#custom#profile('default', 'context',
        \ {'start_insert': 1, 'direction': 'botright', 'prompt_direction': 'top'})
    call unite#custom#profile('all_files', 'matchers', ['matcher_default'])
    call unite#custom#profile('script/vimfiler/mask', 'matchers', ['matcher_context'])
    call unite#custom#source('file', 'ignore_pattern', '.*\.\(un\~\|mat\|pdf\)$')
    call unite#custom#source('file,file_rec,file_rec/async', 'sorters', 'sorter_rank')
    for source in ['history/yank', 'register', 'grep', 'vimgrep']
        call unite#custom#profile('source/'.source, 'context', {'start_insert': 0})
    endfor
    function! s:action_replace(action, candidates) " {{{
        for index in range(len(a:candidates))
            if index == 1 | silent wincmd o | endif
            if index > 0 || len(a:candidates) == 1
                call unite#util#command_with_restore_cursor(
                    \ substitute(a:action, '^split$', 'belowright &', ''))
            endif
            call unite#take_action('open', a:candidates[index])
            if index == 0 | let win = winnr() | endif
        endfor
        silent! execute win . "wincmd w"
    endfunction " }}}
    for type in ['split', 'vsplit']
        let replace = {'is_selectable': 1, 'description': type . ' replacing current window'}
        function! replace.func(candidates)
            call s:action_replace(self.name, a:candidates)
        endfunction
        call unite#custom#action('openable', type, replace)
    endfor

    let s:backup = {
        \ 'description' : 'backup files',
        \ 'is_invalidate_cache' : 1,
        \ 'is_selectable' : 1,
        \ }
    function! s:backup.func(candidates) " {{{
        for candidate in a:candidates
            let time = strftime('%Y_%m_%d_%H%M%Z')
            let filename = candidate.action__path . '.' . time

            call unite#sources#file#copy_files(filename, [candidate])

            if filereadable(undofile(candidate.action__path))
                call unite#sources#file#copy_files(
                    \ undofile(candidate.action__path . '.' . time),
                    \ [{'action__path': undofile(candidate.action__path)}])
            endif
        endfor
    endfunction " }}}
    call unite#custom#action('file_base', 'backup', s:backup)

    let s:help = {'description' : 'open help'}
    function! s:help.func(candidate)
        call vimtools#OpenHelp(a:candidate.word)
    endfunction
    call unite#custom#action('source/help/common', 'help', s:help)
    call unite#custom#default_action('source/help/common', 'help')

    let s:jump_open = {
        \ 'description' : 'persistent open if Unite window is active else regular open',
        \ 'is_quit' : 0,
        \ }
    function! s:jump_open.func(candidate)
        let unite = unite#get_current_unite()
        call unite#take_action(bufwinnr(unite.bufnr) == winnr() ?
            \ 'persist_open' : 'open', a:candidate)
    endfunction
    call unite#custom#action('jump_list', 'jump_open', s:jump_open)
    call unite#custom#default_action(join(map(filter(keys(unite#get_all_sources()),
        \ 'v:val =~ "grep"'), '"source/" . v:val . "/jump_list"'), ','), 'jump_open')

    let s:search = {
        \ 'description' : 'search for word or text',
        \ 'is_quit' : 1,
        \ }
    function! s:search.func(candidate)
        let @/ = a:candidate.word
        try
            normal! nzv
        catch
            call unite#print_error(v:exception)
        endtry
    endfunction
    call unite#custom#action('common', 'search', s:search)

    let s:hash_command = {
        \ 'description': 'run command with git hash as argument',
        \ 'is_quit': 1,
        \ }
    function! s:hash_command.func(candidate)
        execute join([input('Command: ', 'Gedit', 'command'),
            \         matchstr(a:candidate.word, '\v\x{7,}')])
    endfunction
    call unite#custom#action('word', 'hash_command', s:hash_command)
    function! s:git_lg(...) abort
        call fugitive#detect(fnameescape(expand('%:p:h')))
        if !exists('b:git_dir') | return | endif
        let g:git_lg_args = get(g:, 'git_lg_args', [])
        let cmd = ['git', '--git-dir=' . shellescape(b:git_dir), '--no-pager', 'lg'] + g:git_lg_args
        if a:0
            let root = expand('%:p:h')
            while len(root) > 1 && !isdirectory(root . '/.git') && !filereadable(root . '/.git')
                let root = fnamemodify(root, ':h')
            endwhile
            call insert(cmd, '--work-tree=' . shellescape(root), 2)
            let cmd += ['--', shellescape(expand('%:p'))]
        endif
        call unite#start([['output/shellcmd', join(cmd)]],
            \ {'default_action': 'hash_command', 'wrap': 1})
    endfunction
    nnoremap <silent> g<Leader>G :<C-u>call <SID>git_lg()<CR>
    nnoremap <silent> gG :<C-u>call <SID>git_lg('file')<CR>

    " Override open action to avoid BufRead autocommands
    let s:open = {'description': 'open buffer', 'is_selectable': 1} " {{{
    function! s:open.func(candidates)
        for candidate in a:candidates
            execute 'buffer' candidate.action__buffer_nr
        endfor
    endfunction
    call unite#custom#action('buffer', 'open', s:open) " }}}

    " Use Unite for completion
    function! s:get_complete_pos(sources) abort " {{{
        return max(map(copy(a:sources), 'v:val.neocomplete__context.complete_pos'))
    endfunction
    function! s:start_complete()
        let text = neocomplete#get_cur_text(1)
        let sources = neocomplete#complete#_set_results_pos(text)
        return (get(s:, 'omni', 1) ? s:ResetCompletion() : '') .
            \ unite#start_complete(['neocomplete'], {
            \ 'auto_preview' : 1, 'here' : 0, 'resize' : 0, 'split' : 0, 'input' : escape(
            \ tolower(text[s:get_complete_pos(sources): ]), '~\.^$[]*') . ' '})
    endfunction
    function! s:set_omni()
        let s:omni = 1 | return "\<C-x>\<C-o>"
    endfunction " }}}
    inoremap <expr> <C-x><C-o> <SID>set_omni()
    inoremap <silent> <expr> <C-x><Space> <SID>start_complete()
    inoremap <silent> <expr> <C-x><C-@>   <SID>start_complete()
    call unite#custom#profile('completion', 'converters', ['converter_abbr_word'])
endfunc " }}}
" }}}

" mundo settings
if has('python') || has('python3')
    nnoremap <silent> <Leader>u :<C-u>MundoToggle<CR>
    if !has('python')
        let g:mundo_prefer_python3 = 1
    endif
    let g:mundo_help = 0
    let g:mundo_preview_bottom = 1
    let g:mundo_close_on_revert = 1
endif

" Surround settings
xmap <expr> S (mode() == 'v' && virtcol('.') == virtcol('$') ? "h" : "")."\<Plug>VSurround"
nmap gs <Plug>Ysurround
nmap gss <Plug>Yssurround
imap <C-g><C-s> <Plug>Isurround
let g:surround_input_complete = 'vimtools#CmdlineComplete'
" Make d surround with ['...'] and D with ["..."]
let g:surround_100 = "['\r']"
let g:surround_68 = "[\"\r\"]"
" Make e surround with \%(...\) and E with \(...\)
let g:surround_69 = "\\(\r\\)"
let g:surround_101 = "\\%(\r\\)"
" Single-element tuple with t
let g:surround_116 = "(\r,)"
" list() with l
let g:surround_108 = "list(\r)"

" Syntastic settings
let g:syntastic_filetype_map = {'arduino': 'cpp'}
let g:syntastic_mode_map = {'mode': 'passive', 'active_filetypes': [], 'passive_filetypes': []}
nnoremap <silent> ,sc :<C-u>execute "SyntasticCheck"<bar>execute "Errors"<bar>silent! lfirst<CR>
nnoremap <silent> <Leader>sc :<C-u>SyntasticReset<CR>

" Tabular settings
let g:no_default_tabular_maps=1

" Indent Guides settings
let g:indent_guides_auto_colors=0
nmap <silent> <Leader>i <Plug>IndentGuidesToggle

" Ack settings
if executable('ag') | let g:ackprg='ag --vimgrep -S' | endif
let g:ack_autofold_results=0
let g:ack_apply_lmappings=0
let g:ack_apply_qmappings=0
cnoreabbrev <expr> A getcmdtype() == ':' && getcmdpos() <= 2 ?
    \ 'Ack!' . (len(g:ag_flags) ? ' ' . g:ag_flags : '') : 'A'
cnoreabbrev <expr> a getcmdtype() == ':' && getcmdpos() <= 2 ?
    \ 'Ack!' . (len(g:ag_flags) ? ' ' . g:ag_flags : '') : 'a'
func! s:AckCurrentSearch(ignorecase, visual, args) " {{{
    let view = winsaveview() | call SaveRegs()
    execute printf('keepjumps normal! g%sy', a:visual ? 'v' : 'n')
    let pattern = @@
    call RestoreRegs() | call winrestview(view)
    let args = split(a:args ? input('Options: ', g:ag_flags) : g:ag_flags)
    if (a:visual && pattern ==# expand('<cword>')) || (@/ =~ '^\\v<.*>$' || @/ =~ '^\\<.*\\>$')
        call add(args, '-w')
    endif
    if a:visual | call histadd('/', pattern) | endif
    if a:visual && pattern =~? '[.^$*+?()[{\|]' | call add(args, '-Q') | endif
    if !&ignorecase || !a:ignorecase
        call add(args, '-s')
    elseif index(args, '-s') == -1 && (a:visual || @/ !~ '\u')
        let pattern = tolower(pattern)
    endif
    call unite#start([['grep', '.', join(args), pattern]], {'auto_resize': 1})
endfunc " }}}
nnoremap <silent> ga     :<C-u>call <SID>AckCurrentSearch(1, 0, 0)<CR>
nnoremap <silent> gA     :<C-u>call <SID>AckCurrentSearch(0, 0, 0)<CR>
nnoremap <silent> g<C-a> :<C-u>call <SID>AckCurrentSearch(1, 0, 1)<CR>
xnoremap <silent> ga     :<C-u>call <SID>AckCurrentSearch(1, 1, 0)<CR>
xnoremap <silent> gA     :<C-u>call <SID>AckCurrentSearch(0, 1, 0)<CR>
xnoremap <silent> g<C-a> :<C-u>call <SID>AckCurrentSearch(1, 1, 1)<CR>
let g:ag_flags = get(g:, 'ag_flags', '')

" tmux navigator settings
let g:tmux_navigator_no_mappings = 1
for dir in ['Left', 'Down', 'Up', 'Right'] | for mod in ['S-', 'M-']
    execute 'nnoremap <silent> <'.mod.dir.'> :<C-u>TmuxNavigate'.dir.'<CR>'
endfor | endfor

" Vimux settings
function! VimuxCompletionPrompt() abort " {{{
    let command = input('Command? ', '', 'customlist,vimtools#CmdlineComplete')
    if !empty(command)
        call VimuxRunCommand(command)
        let g:VimuxLastCommand = command
    endif
endfunction " }}}
let g:VimuxResetSequence = "S q C-u"
nnoremap <silent> <Leader>: :<C-u>call VimuxCompletionPrompt()<CR>
nnoremap <Leader>vo :call VimuxOpenRunner()<CR>
nnoremap <silent> @\ :<C-u>VimuxRunLastCommand<CR>
nnoremap <silent> @\| :<C-u>VimuxRunLastCommand<CR>
nnoremap <silent> g\| :VimuxPromptCommand<CR><C-f>
nnoremap <silent> g\ :VimuxPromptCommand<CR><C-f>
nnoremap <silent> <Leader>bb :call VimuxRunCommand('break '.expand('%:p').':'.line('.'))<CR>
nnoremap <silent> <Leader>bc :call VimuxRunCommand('clear '.expand('%:p').':'.line('.'))<CR>
let g:VimuxRunnerType = 'pane'
command! -nargs=0 VimuxToggleRunnerType let g:VimuxRunnerType =
    \ g:VimuxRunnerType == 'pane' ? 'window' : 'pane' | echo g:VimuxRunnerType

" Targets settings
let g:targets_aiAI = 'aiAI'
let g:targets_nlNL = 'nlNL'
let g:targets_pairs = '()b {}B []r <>a'
let g:targets_quotes = '" '' `'
let g:targets_separators = ', . : + - = ~ _ * # / | & $ %'
let g:targets_argOpening = '[([{"]'
let g:targets_argClosing = '[])}"]'
let g:targets_argTrigger = 'A'
if stridx($VIMBLACKLIST, 'targets') == -1
    let g:SelectTextObjectLoaded = 1
    onoremap <silent> iA :<C-u>call targets#o('AcI', v:count1)<CR>
    xnoremap <silent> iA :<C-u>call targets#x('AcI', v:count1)<CR>
endif

" fuzzyfinder settings
nnoremap <silent> <M-f> :FZF<CR>

" eunuch settings
cnoreabbrev <expr> loc getcmdtype() == ':' && getcmdpos() <= 4 ?
    \ 'Locate! --regex -i' : 'loc'

" vimtools functions
command! -nargs=? -complete=dir Tree call vimtools#Tree(<f-args>)
command! -nargs=0 FollowedBy call vimtools#FollowedBy(0)
command! -nargs=0 NotFollowedBy call vimtools#FollowedBy(1)
command! -nargs=0 PrecededBy call vimtools#PrecededBy(0)
command! -nargs=0 NotPrecededBy call vimtools#PrecededBy(1)
autocmd VimrcAutocmds FileType c,cpp,*sh call vimtools#SectionJumpMaps()
nnoremap <silent> g= :<C-u>call vimtools#MakeParagraph()<CR>
nnoremap <silent> <expr> gp (getregtype(v:register) ==# 'V' ? '' : 'o<Esc>') .
    \ 'p:<C-u>call vimtools#MakeParagraph()<CR>:silent! call repeat#set("gp")<CR>'
nnoremap <silent> <expr> gP (getregtype(v:register) ==# 'V' ? '' : 'O<Esc>') .
    \ 'P:<C-u>call vimtools#MakeParagraph()<CR>:silent! call repeat#set("gP")<CR>'
function! s:IndentMakeParagraph(how) abort " {{{
    execute "normal" a:how
    call vimtools#MakeParagraph()
endfunction
function! s:IndentMakeParagraphMap(map) abort
    execute 'nnoremap <silent>' a:map
        \ ':<C-u>call <SID>IndentMakeParagraph("' . a:map[0] . a:map[2] . '")<CR>' .
        \ ':silent! call repeat#set("' . a:map . '")<CR>'
endfunction " }}}
for map in ['>gp', '>gP', '<gp', '<gP', '=gp', '=gP']
    call s:IndentMakeParagraphMap(map)
endfor

" python-mode settings
let g:pymode_options = 0
let g:pymode_lint_on_write = 0
let g:pymode_breakpoint_cmd = "import clewn.vim\rclewn.vim.pdb()"
let g:pymode_trim_whitespaces = 0
let g:pymode_run_bind = ',r'
let g:pymode_breakpoint_bind = '<M-b>'
let g:pymode_doc = 1
let g:pymode_doc_bind = 'gK'
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_lint_checkers = ['pyflakes', 'pep8', 'mccabe', 'callable']

" VCSCommand settings
let VCSCommandCVSExec = ''
let VCSCommandBZRExec = ''
let VCSCommandSVKExec = ''
let VCSCommandDisableMappings = 1
let VCSCommandCVSDiffOpt = '--internal-diff'

" jedi settings
func! s:JediSetup() " {{{
    if exists('*jedi#completions') && &omnifunc != 'CompleteIPython'
        setlocal omnifunc=jedi#completions
    endif
    nnoremap <silent> <buffer> <M-]> :<C-u>call jedi#goto()<CR>zv
    nnoremap <silent> <buffer> <expr> gd exists('*jedi#goto_assignments') ?
        \ ':<C-u>call jedi#goto_assignments()<CR>zv' : 'gd'
endfunc " }}}
autocmd VimrcAutocmds FileType python call s:JediSetup()
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_select_first = 0
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#goto_command = ''
let g:jedi#rename_command = '<silent> <Leader>jr'
let g:jedi#usages_command = '<silent> <Leader>ju'
let g:jedi#auto_close_doc = 0
let g:jedi#show_call_signatures = 2
let g:jedi#smart_auto_mappings = 0
let g:jedi#use_tag_stack = 1
if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.python =
    \ '\%([^[(). \t]\.\|^\s*@\|^\s*from\s.\+import \(\w\+,\s\+\)*\|^\s*from \|^\s*import \)\w*'
if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.python =
    \ '\v<(cm|collections|colors|copy|ein|inspect|it|itertools|logging|ma|mathtools|matplotlib|'.
    \ 'mpl|mt|np|numpy|op|operator|opt|os|pickle|plottools|plt|pt|px|re|sc|scipy|si|sio|six|'.
    \ 'subprocess|sys)(\.\h\w*)*\.(\h\w*)?'

" DirDiff settings
let g:DirDiffExcludes = '.*.un~,.svn,.git,.hg,'.&wildignore
let g:DirDiffEnableMappings = 1

" EasyAlign settings
let g:easy_align_ignore_comment = 0
vmap <CR> <Plug>(LiveEasyAlign)
vmap <C-^> <Plug>(EasyAlignRepeat)

" C/C++ completion
if stridx($VIMBLACKLIST, 'clang_complete') == -1
    call add(g:pathogen_disabled, 'OmniCppComplete')
    if !exists('g:neocomplete#sources#omni#input_patterns')
        let g:neocomplete#sources#omni#input_patterns = {}
    endif
    let g:neocomplete#sources#omni#input_patterns.c =
        \ '\([^.[:digit:] *\t]\|\w\d\)\%(\.\|->\)\w*'
    let g:neocomplete#sources#omni#input_patterns.cpp =
        \ '\([^.[:digit:] *\t]\|\w\d\)\%(\.\|->\)\w*\|\h\w*::\w*'
    let g:neocomplete#sources#omni#input_patterns.objc =
        \ '\[\h\w*\s\h\?\|\h\w*\%(\.\|->\)'
    let g:neocomplete#sources#omni#input_patterns.objcpp =
        \ '\[\h\w*\s\h\?\|\h\w*\%(\.\|->\)\|\h\w*::\w*'
    let g:clang_complete_auto = 0
    let g:clang_auto_select = 0
    let g:clang_use_library = 1
    let g:clang_sort_algo = 'alpha'
    let g:clang_make_default_keymappings = 0
    function! s:clang_setup()
        nnoremap <silent> <buffer> <M-]> :<C-u>call ClangGotoDeclaration()<CR>
        nnoremap <silent> <buffer> <C-w><M-]> :<C-u>call ClangGotoDeclarationPreview()<CR>
    endfunction
    autocmd VimrcAutocmds FileType c,cpp,objc,objcpp call s:clang_setup()
else
    call add(g:pathogen_disabled, 'clang_complete')
    let g:OmniCpp_LocalSearchDecl = 1
endif

" FSwitch settings
nnoremap g<C-^> :<C-u>FSHere<CR>
nnoremap <C-w><C-^> :<C-u>FSSplitRight<CR>
nnoremap <C-w>g<C-^> :<C-u>FSSplitBelow<CR>

" Scriptease settings
func! s:ScripteaseMaps() " {{{
    nnoremap <buffer> <Leader>bb :<C-u>Breakadd<CR>
    nnoremap <buffer> <Leader>bc :<C-u>Breakdel *<CR>
    nnoremap <buffer> <Leader>r :<C-u>update<bar>Runtime<CR>
endfunc " }}}
autocmd VimrcAutocmds FileType vim call s:ScripteaseMaps()

" Unmap DirDiff unique maps
for m in ['Get', 'Put', 'Next', 'Prev', 'Quit']
    silent! execute 'unmap <Plug>DirDiff'.m
endfor

" Visual increment maps
vmap <C-a> <Plug>VisualIncrement
vmap <C-x> <Plug>VisualDecrement

" Abolish map
nmap cr <Plug>Coerce

" Fugitive maps
nnoremap gB         :<C-u>Gblame<CR>
nnoremap gC         :<C-u>Gdiff<CR>
nnoremap gL         :<C-u>Glog<CR>
nnoremap g<Leader>L :<C-u>Glog --<CR>
nnoremap gS         :<C-u>Gstatus<CR>
nnoremap gW         :<C-u>Gwrite<CR>
" Reload file with absolute path to create fugitive commands
nnoremap <Leader>L :<C-u>execute 'file '.fnameescape(resolve(expand('%:p')))<bar>
    \ call fugitive#detect(fnameescape(expand('%:p:h')))<CR>

" CountJump maps
autocmd VimrcAutocmds FileType c,cpp
    \ if maparg('ac', 'o') ==# '' |
    \ silent! call
    \     CountJump#TextObject#MakeWithCountSearch('<buffer>', 'c', 'ai', 'V',
    \                                              '^{\s*$', '^}\s*\(\w\+\s*\)\?;\s*$') |
    \ endif
autocmd VimrcAutocmds FileType vim
    \ silent! call
    \     CountJump#Motion#MakeBracketMotion('<buffer>', '', '',
    \                                        '^\s*fu\%[nction]\>',
    \                                        '^\s*endf*\%[unction]\>', 0)

" AnsiEsc map
nnoremap <Leader>A :<C-u>AnsiEsc<CR>

" textobj-function maps
xmap am <Plug>(textobj-function-A)
xmap im <Plug>(textobj-function-i)
omap am <Plug>(textobj-function-A)
omap im <Plug>(textobj-function-i)

" Haskell plugin settings
let g:haskellmode_completion_haddock = 0
let g:hindent_style = "gibiansky"
let g:haskell_indent_in = 0
let g:haskell_indent_if = 2
let maplocalleader = '&'
if !exists('g:syntastic_quiet_messages')
    let g:syntastic_quiet_messages = {}
endif
let g:syntastic_quiet_messages.regex = '^Defaulting the following constraint(s) to type [`‘]Int'.
    \ (get(g:syntastic_quiet_messages, 'regex', '') == '' ?
    \ '' : '\|'.g:syntastic_quiet_messages.regex)
let g:syntastic_quiet_messages.regex .= '\|The import of .Debug\.Trace. is redundant'

" Prevent folds updating spuriously on first write
autocmd VimrcAutocmds VimEnter * silent! FastFoldUpdate

" LaTeX-Box settings
autocmd VimrcAutocmds FileType plaintex,tex
    \ execute 'nnoremap <buffer> <F5> :<C-u>update<bar>Latexmk<CR>' |
    \ nnoremap <buffer> <S-F5> :<C-u>execute "LatexView"<bar>update<bar>execute "Latexmk"<CR>
let g:LatexBox_completion_close_braces = 0
let g:tex_flavor = "latex"
if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.tex = '\\\h\w*{'

" vim-exchange settings
let g:exchange_indent = '=='

" neomru settings
let g:neomru#do_validate = hasMac
let g:neomru#file_mru_limit = 2000
let g:neomru#update_interval = hasMac ? 0 : 1.0

" gitgutter configuration " {{{
let g:gitgutter_async = 0
let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '✹'
let g:gitgutter_sign_removed = '✖'
let g:gitgutter_sign_removed_first_line = '➜'
let g:gitgutter_sign_modified_removed = '✗'
nnoremap <silent> ,gg :<C-u>GitGutter<CR>
function! s:hunk(mode, sign, ...) abort
    if gitgutter#utility#is_active()
        let hunks = filter(copy(gitgutter#hunk#hunks()), 'v:val[2]' . a:sign . 'line(".")')
        if empty(hunks) && a:0 | let hunks = gitgutter#hunk#hunks() | endif
        if empty(hunks) | return | endif
        let l:count = a:0 ? get(g:, 'gitgutter_max_signs', 500) : v:count1
        if a:sign == '<'
            let hunk = get(hunks, -l:count, hunks[0])
        else
            let hunk = get(hunks, l:count - 1, hunks[-1])
        endif
        execute 'normal! ' . (a:mode == 'n' ? '' : 'V') . max([1, hunk[2]]) . 'G'
    endif
endfunction
for mode in ['n', 'x', 'o']
    execute mode.'noremap <silent> [h :<C-u>call <SID>hunk("'.mode.'", "<")<CR>zv'
    execute mode.'noremap <silent> ]h :<C-u>call <SID>hunk("'.mode.'", ">")<CR>zv'
    execute mode.'noremap <silent> [H :<C-u>call <SID>hunk("'.mode.'", "<", 1)<CR>zv'
    execute mode.'noremap <silent> ]H :<C-u>call <SID>hunk("'.mode.'", ">", 1)<CR>zv'
endfor " }}}

" neosnippet configuration
if !exists('g:neosnippet#snippets_directory')
    let g:neosnippet#snippets_directory = '$VIMCONFIG/vimfiles/snippets'
endif
xmap <C-t> <Plug>(neosnippet_expand_target)
imap <C-x><C-t> <Plug>(neosnippet_start_unite_snippet)

" Import scripts {{{
silent! if plug#begin('$VIMCONFIG/vimfiles/bundle')
if filereadable(expand('$HOME/.plugged'))
    source $HOME/.plugged
endif
Plug 'vim-scripts/DirDiff.vim', {'on': 'DirDiff'}
Plug 'Konfekt/FastFold'
Plug 'wilywampa/vim-mundo', {'on': 'MundoToggle'}
Plug 'LaTeX-Box-Team/LaTeX-Box', {'for': ['plaintext', 'context', 'tex']}
Plug 'vim-scripts/OmniCppComplete'
Plug 'tpope/vim-abolish', {'on': ['S', '<Plug>Coerce']}
Plug 'mileszs/ack.vim', {'on': 'Ack'}
Plug 'wilywampa/lightline.vim'
Plug 'wilywampa/clang_complete'
Plug 'wilywampa/vim-commentary'
Plug 'wilywampa/vim-dispatch'
Plug 'wilywampa/vim-easy-align', {'on': '<Plug>(LiveEasyAlign)'}
Plug 'wilywampa/vim-eunuch'
Plug 'tommcdo/vim-exchange'
Plug 'wilywampa/vim-fswitch', {'on': ['FSHere', 'FSSplitBelow', 'FSSplitRight']}
Plug 'wilywampa/vim-fugitive'
Plug 'wilywampa/gitv', {'on': 'Gitv'}
Plug 'wilywampa/vim-gtfo'
Plug 'wilywampa/vim-indent-guides', {'on': '<Plug>IndentGuidesToggle'}
Plug 'wilywampa/vim-ipython'
Plug 'davidhalter/jedi-vim'
Plug 'xolox/vim-misc'
Plug 'Shougo/neocomplete.vim'
Plug 'Shougo/neoinclude.vim'
Plug 'wilywampa/neomru.vim'
Plug 'wilywampa/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'wilywampa/patchreview-vim', {'on': ['DiffReview', 'PatchReview']}
Plug 'wilywampa/python-mode', {'branch': 'develop'}
Plug 'wilywampa/vim-repeat'
Plug 'wilywampa/vim-scriptease'
Plug 'xolox/vim-shell'
Plug 'wilywampa/vim-sleuth'
Plug 'wilywampa/vim-sneak'
Plug 'wilywampa/vim-colors-solarized', {'dir': '$VIMCONFIG/vimfiles/bundle/solarized'}
Plug 'ervandew/supertab'
Plug 'wilywampa/vim-surround'
Plug 'scrooloose/syntastic', {'on': ['SyntasticInfo', 'SyntasticCheck']}
Plug 'wellle/targets.vim', {'branch': 'improve-quotes'}
Plug 'wilywampa/tmux-complete.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'wilywampa/vim-unimpaired'
Plug 'wilywampa/unite.vim'
Plug 'Shougo/unite-outline'
Plug 'wilywampa/vcscommand.vim', {'on': ['Diff', 'Log']}
Plug 'wilywampa/vimfiler.vim'
Plug 'wilywampa/vimproc.vim', {'do': 'make'.(has('win32unix') ? ' -f make_cygwin.mak' : '')}
Plug 'wilywampa/vimshell.vim'
Plug 'wilywampa/vimux'
Plug 'triglav/vim-visual-increment', {'on': ['<Plug>VisualIncrement', '<Plug>VisualDecrement']}
Plug 'wilywampa/CountJump'
Plug 'vim-ruby/vim-ruby', {'for': ['ruby', 'eruby']}
Plug 'wilywampa/fzf', {'dir': '$VIMCONFIG/misc/fzf'}
Plug 'rhysd/vim-textobj-clang'
Plug 'kana/vim-textobj-user'
Plug 'rhysd/libclang-vim', {'do': 'make'}
Plug 'kana/vim-textobj-function'
Plug 'wilywampa/vim-textobj-function-clang'
Plug 'wilywampa/haskellmode-vim'
Plug 'eagletmt/ghcmod-vim'
Plug 'eagletmt/neco-ghc'
Plug 'Shougo/neco-vim', {'dir': '$VIMCONFIG/vimfiles/bundle/neco-vim'}
Plug 'Shougo/neco-syntax'
Plug 'Shougo/neoyank.vim'
Plug 'neovimhaskell/haskell-vim'
Plug 'ujihisa/unite-haskellimport'
Plug 'vim-scripts/CSApprox', {'for': 'fugitiveblame'}
Plug 'airblade/vim-gitgutter'
Plug '$VIMCONFIG/vimfiles/bundle/AnsiEsc', {'on': 'AnsiEsc'}
Plug '$VIMCONFIG/vimfiles/bundle/matlab'
Plug '$VIMCONFIG/vimfiles/bundle/matlab-complete'
call plug#end()
endif " }}}

" Shared after directory for syntax overrides
set runtimepath+=$VIMCONFIG/vimfiles/after

" Disable abbr entries for neocomplete include source
silent! call neocomplete#custom#source('include', 'converters',
    \ ['converter_remove_overlap', 'converter_remove_last_paren',
    \  'converter_delimiter', 'converter_case',
    \  'converter_disable_abbr', 'converter_abbr'])

" Don't re-sort omnifunc completions
silent! call neocomplete#custom#source('omni', 'sorters', [])

" Text object for a line and inner (exclude leading space) line
silent! call textobj#user#plugin('line', { '-': {
    \     'select-a-function': 'CurrentLineA', 'select-a': 'a\',
    \     'select-i-function': 'CurrentLineI', 'select-i': 'i\',
    \ }})
function! CurrentLineA()
    let [bufnr, lnum, _, offset] = getpos('.')
    return ['v', [bufnr, lnum, 1, offset], [bufnr, lnum, col('$') - 1, offset]]
endfunction
function! CurrentLineI()
    normal! ^
    let head_pos = getpos('.')
    normal! g_
    return getline('.') =~ '\S' ? ['v', head_pos, getpos('.')] : 0
endfunction
silent! TextobjLineDefaultKeyMappings!

" Solarized settings
if mobileSSH || $SOLARIZED != 1 | let g:solarized_termcolors=256 | endif
if !exists('colors_name') || colors_name != 'solarized'
    set background=dark
    sil! colorscheme solarized
endif
" }}} vim: fdm=marker fdl=1 tw=100:
