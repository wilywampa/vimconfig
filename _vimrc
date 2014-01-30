" {{{ Vim built-in configuration

" Allow settings that are not vi-compatible
set nocompatible

" Reset autocommands when vimrc is re-sourced
augroup VimrcAutocmds
    autocmd!
augroup END

set shiftwidth=4               " Number of spaces to indent
set expandtab                  " Use spaces instead of tabs
set tabstop=4                  " Length of indent
set softtabstop=4
set autoindent                 " Automatic indentation
set cinoptions=N-s             " Don't indent namespaces in C++
set nowrap                     " Don't wrap lines
set lazyredraw                 " Don't update display during macro execution
set encoding=utf-8             " Set default file encoding
set backspace=indent,eol,start " Backspace through everything in insert mode
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
set number                     " Turn on hybrid line numbers (or relative line numbers before Vim 7.4)
set relativenumber
set history=1000               " Remember more command history
set tabpagemax=20              " Allow more tabs
set hidden                     " Allow switching buffer without saving changes first
set wildmenu                   " Turn on autocompletion
set wildmode=full
set visualbell                 " Use visual bell instead of sound
set undofile                   " Enable persistent undo
set undolevels=1000
set undoreload=10000
set timeoutlen=500             " Shorter timeout length for multi-key mappings
set ttimeout                   " Even shorter delay for keycode mappings
set ttimeoutlen=50
set laststatus=2               " Always show statusline
set foldopen-=block            " Don't open folds when traversed block-wise

" Turn on filetype plugins and indent settings
filetype plugin indent on

" Turn on syntax highlighting
syntax enable

" Use four spaces to indent vim file line continuation
let g:vim_indent_cont=4

" Session settings
set sessionoptions=buffers,curdir,folds,help,tabpages,winsize
augroup VimrcAutocmds
    au VimLeavePre * mks! ~/session.vis
    au VimEnter * mks! ~/periodic_session.vis
    au VimEnter * exe "au BufEnter,BufRead,BufWrite,CursorHold * mks! ~/periodic_session.vis"
augroup END
nnoremap <silent> ,l :source ~/session.vis<CR>

" Like bufdo but return to starting buffer
func! Bufdo(command)
    let currBuff=bufnr("%")
    execute 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunc
com! -nargs=+ -complete=command Bufdo call Bufdo(<q-args>)

" Shortcut to switch to last active tab
let g:lastTab = 1
au TabLeave * let g:lastTab=tabpagenr()
nnoremap <Leader>l :exe "tabn ".g:lastTab<CR>

" {{{ Platform-specific configuration

let hasmac=has("mac")
let haswin=has("win16") || has("win32") || has("win64")
let hasunix=has("unix")

if hasmac
    " Enable use of option key as meta key
    set macmeta
endif

if haswin
    " Change where backups are saved
    if !isdirectory("C:\\temp\\vimtmp")
        call mkdir("C:\\temp\\vimtmp", "p")
    endif
    set backupdir=C:\temp\vimtmp,.
    set directory=C:\temp\vimtmp,.
    set undodir=C:\temp\vimtmp,.

    " Source Windows-specific settings
    source $VIMRUNTIME/mswin.vim
    unmap! <C-y>

    " Map increment/decrement function to Alt instead of Ctrl
    nnoremap <M-a> <C-a>
    nnoremap <M-x> <C-x>

    " Make Ctrl-c exit visual/select mode after copying
    vnoremap <C-c> "+y<Esc>
    snoremap <C-c> <C-g>"+y<Esc>

    " Shortcut to explore to current file
    nnoremap <silent> <F4> :silent execute "!start explorer /select,\"" . expand("%:p") . "\""<CR>
else
    " Change swap file location for unix
    if !isdirectory(expand("~/.tmp"))
        call mkdir(expand("~/.tmp"), "p")
    endif
    set backupdir=~/.tmp
    set directory=~/.tmp
    set undodir=~/.tmp

    if hasmac
        " Shortcut to reveal current file in Finder
        nnoremap <silent> <F4> :silent !reveal %:p > /dev/null<CR>:redraw!<CR>
    endif
endif

if hasunix
    " Enable mouse
    set mouse=a
endif

" }}}

" {{{ Mappings

" Shortcuts to save current file if modified
nn <silent> <Leader>s :update<CR>
nn <silent> <Leader>w :update<CR>

" <Ctrl-l> redraws the screen and removes any search highlighting.
nn <silent> <C-l> :nohl<CR><C-l>

" Execute q macro with Q
nn Q @q

" Shortcut to toggle paste mode
nn <silent> <Leader>p :set paste!<CR>

" Make F2 toggle line numbers
nn <silent> <F2> :se nu!|if &nu|se rnu|el|se nornu|en<CR>

" Make it easy to edit this file (, 'e'dit 'v'imrc)
nn <silent> ,ev :e $MYVIMRC<CR>

" Make it easy to source this file (, 's'ource 'v'imrc)
nn <silent> ,sv :so $MYVIMRC<CR>

" Shortcuts for switching buffer
nn <silent> <C-p> :bp<CR>
nn <silent> <C-n> :bn<CR>

" Shortcuts to use vim grep recursively or non-recursively
nn ,gr :vim //j **/*<C-Left><C-Left><Right>
nn ,gn :vim //j *<C-Left><C-Left><Right>
nn ,go :call setqflist([])<CR>:silent! Bufdo vimgrepa //j %<C-Left><C-Left><Right>

" Open tag in vertical split with Alt-]
nn <M-]> <C-w><C-]><C-w>L

" Make Ctrl-c function the same as Esc in insert mode
imap <C-c> <Esc>

" Shortcuts for switching tab
nn <silent> <C-Tab>   :tabnext<CR>
nn <silent> <F12>     :tabnext<CR>
nn <silent> <C-S-Tab> :tabprevious<CR>
nn <silent> <F11>     :tabprevious<CR>

" Shortcut to open new tab
nn <silent> <M-t> :tabnew<CR>

" Shortcut to print number of occurences of last search
nn <silent> <M-n> <Esc>:%s///gn<CR>
nn <silent> <Leader>n <Esc>:%s///gn<CR>

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
nn <C-g> :let @+=expand('%:p')<CR><C-g>

" Move current tab to last position
nn <silent> <C-w><C-e> :tabm +99<CR>
nn <silent> <C-w>e     :tabm +99<CR>

" Insert result of visually selected expression
vn <C-e> c<C-o>:let @"=substitute(@",'\n','','g')<CR><C-r>=<C-r>"<CR><Esc>

" ZZ and ZQ close buffer instead of just closing window
nn ZZ :up<CR>:Bclose<CR>:q<CR>
nn ZQ :Bclose!<CR>:q!<CR>

" Make <C-c> cancel <C-w> instead of closing window
nn <C-w><C-c> <NOP>
vn <C-w><C-c> <NOP>

" <C-k>/<C-j> inserts blank line above/below
nn <silent><C-j> :set paste<CR>m`o<Esc>``:set nopaste<CR>
nn <silent><C-k> :set paste<CR>m`O<Esc>``:set nopaste<CR>

" <M-k>/<M-j> deletes blank line above/below
nn <silent><M-j> m`:silent +g/\m^\s*$/d<CR>``:noh<CR>
nn <silent><M-k> m`:silent -g/\m^\s*$/d<CR>``:noh<CR>

" }}}

if has('gui_running')
    " Copy mouse modeless selection to clipboard
    set guioptions+=A

    " Don't use second vertical scrollbar
    set guioptions-=L

    if haswin
        " Set font for gVim
        if hostname() ==? 'Jake-Desktop'
            " Big font for big TV
            set guifont=Consolas:h14
        else
            set guifont=Consolas:h11
        endif

        " Hide menu/toolbars
        set guioptions-=m
        set guioptions-=T
    elseif hasmac
        " Set font for MacVim
        set guifont=Consolas:h17

        " Start in fullscreen mode
        augroup VimrcAutocmds
            autocmd VimEnter * set fullscreen
        augroup END
    else
        " Set font for gVim
        set guifont=Inconsolata\ for\ Powerline\ Medium\ 15
    endif
else
    " Shortcuts for moving cursor in command in PuTTY
    cmap <ESC>[C <C-Right>
    cmap <ESC>[D <C-Left>

    " Shortcuts to change tab in MinTTY
    nnoremap [1;5I gt
    nnoremap [1;6I gT

    " Map escape sequences to act as meta keys in normal/visual mode
    let ns=range(33,78) + range(80,90) + range(92,123) + range(125,126)
    for n in ns
        exec "nmap ".nr2char(n)." <M-".nr2char(n).">"
        exec "vmap ".nr2char(n)." <M-".nr2char(n).">"
    endfor
    unlet ns n
endif

if !empty($SSH_CLIENT)
    " Increase time allowed for multi-key mappings
    set timeoutlen=1000

    " Increase time allowed for keycode mappings
    set ttimeoutlen=100
endif

augroup VimrcAutocmds
    " Don't auto comment new line made with 'o' or 'O'
    autocmd FileType * set formatoptions-=o

    " Use line wrapping for plain text files (but not help files)
    autocmd FileType text setl wrap | setl linebreak
    autocmd FileType help setl nowrap | setl nolinebreak

    " Highlight current line in active window
    autocmd BufRead,BufNewFile * set cul
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END

" Remove last newline after copying visual selection to clipboard
func! RemoveClipboardNewline()
    if &updatetime==1
        let @*=substitute(@*,'\n$','','g')
        set updatetime=4000
    endif
endfunc
func! s:VisualEnter(arg)
    set updatetime=1
    return a:arg
endfunc
vnoremap <expr> <SID>VisualEnter VisualEnter()
nnoremap <expr> v <SID>VisualEnter('v')
nnoremap <expr> V <SID>VisualEnter('V')
augroup VimrcAutocmds
    autocmd CursorHold * call RemoveClipboardNewline()
augroup END

" Set color scheme
colorscheme desert

" }}}

" {{{ Plugin configuration

" Set airline color scheme
let g:airline_theme='badwolf'
let g:airline#extensions#ctrlp#color_template = 'normal'

" Use powerline font unless in Mac SSH session
if hasmac && !empty($SSH_CLIENT)
    let g:airline_powerline_fonts=0
    let g:airline_left_sep=''
    let g:airline_right_sep=''
else
    let g:airline_powerline_fonts=1
endif

" Force airline to update when switching to a buffer
augroup VimrcAutocmds
    autocmd BufEnter,VimEnter * AirlineRefresh
augroup END

" Shortcut to toggle warnings in airline
nnoremap <silent> <M-w> :AirlineToggleWhitespace<CR>

" Automatically close NERDTree after opening a buffer
let NERDTreeQuitOnOpen=1

" Don't let NERDTree override netrw
let NERDTreeHijackNetrw=0

" Map Alt-- to navigate to current file in NERDTree
nnoremap <silent> <M--> :NERDTreeFind<CR>

" Make B an alias for Bclose
command! -nargs=* -bang B Bclose<bang><args>

" Tagbar configuration
augroup VimrcAutocmds
    autocmd VimEnter * if exists(":TagbarToggle") | exe "nnoremap <silent> <Leader>t :TagbarToggle<CR>" | endif
augroup END
let g:tagbar_iconchars=['+','-']

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr=1
let OmniCpp_MayCompleteScope=1
augroup VimrcAutocmds
    au CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif
augroup END

" Set comment delimiters for Arduino
let g:NERDCustomDelimiters={
    \ 'arduino': { 'left': '//', 'leftAlt': '/*', 'rightAlt': '*/' },
    \ }

" Add Arduino support to Tagbar
let g:tagbar_type_arduino = {
    \   'ctagstype' : 'c++',
    \   'kinds'     : [
    \     'd:macros:1:0',
    \     'p:prototypes:1:0',
    \     'g:enums',
    \     'e:enumerators:0:0',
    \     't:typedefs:0:0',
    \     'n:namespaces',
    \     'c:classes',
    \     's:structs',
    \     'u:unions',
    \     'f:functions',
    \     'm:members:0:0',
    \     'v:variables:0:0'
    \   ],
    \   'sro'        : '::',
    \   'kind2scope' : {
    \     'g' : 'enum',
    \     'n' : 'namespace',
    \     'c' : 'class',
    \     's' : 'struct',
    \     'u' : 'union'
    \   },
    \   'scope2kind' : {
    \     'enum'      : 'g',
    \     'namespace' : 'n',
    \     'class'     : 'c',
    \     'struct'    : 's',
    \     'union'     : 'u'
    \   }
    \ }

" Override some default settings for Processing files
augroup VimrcAutocmds
    autocmd FileType processing setl softtabstop=2|setl formatoptions-=o
    autocmd FileType processing nnoremap <F7> :update<bar>call RunProcessing()<CR>|unmap <F5>
augroup END

" Make NERDCommenter work in select mode
smap <Bslash> <C-g><Bslash>

" CtrlP configuration
let g:ctrlp_cmd='CtrlPMRU'
let g:ctrlp_map='<M-p>'
let g:ctrlp_clear_cache_on_exit=0
let g:ctrlp_tabpage_position='al'
let g:ctrlp_show_hidden=1
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_follow_symlinks=1
nnoremap <silent> <M-f> :CtrlPBuffer<CR>
nnoremap <silent> <Leader>be :CtrlPBuffer<CR>

" Map <C-q> to delete buffer in CtrlP
let g:ctrlp_buffer_func = { 'enter': 'MyCtrlPMappings' }
func! MyCtrlPMappings()
    nnoremap <buffer> <silent> <C-q> :call <SID>DeleteBuffer()<cr>
endfunc
func! s:DeleteBuffer()
    let line = getline('.')
    let bufid = line =~ '\[\d\+\*No Name\]$' ? str2nr(matchstr(line, '\d\+'))
        \ : fnamemodify(line[2:], ':p')
    exec "bd" bufid
    exec "norm \<F5>"
endfunc

" Disable CSApprox if color palette is too small
if !has('gui_running') && (&t_Co < 88)
    let g:pathogen_disabled=[]
    call add(g:pathogen_disabled, 'CSApprox')
endif

" Override plugin mappings after startup
augroup VimrcAutocmds
    autocmd VimEnter * silent! unmap <Tab>
    autocmd VimEnter * silent! unmap <Space>
augroup END

" EasyMotion settings
let g:EasyMotion_leader_key='<Space>'
nmap <S-Space> <Space>
vmap <S-Space> <Space>

" Undotree settings
nnoremap <Leader>u :UndotreeToggle<CR>
let g:undotree_SplitWidth=40

" Import scripts (e.g. NERDTree)
execute pathogen#infect()

" Add current directory to status line
let g:airline_section_b=airline#section#create(['%{ShortCWD()}'])

" Default whitespace symbol not available everywhere
if exists('g:airline_symbols')
    let g:airline_symbols.whitespace='!'
endif

" }}}

" vim: set fdm=marker:
