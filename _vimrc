" Allow settings that are not vi-compatible
set nocompatible

" Number of spaces to indent
set shiftwidth=4

" Use spaces instead of tabs
set expandtab

" Length of indent
set tabstop=4
set softtabstop=4

" Automatic indentation
set autoindent

" Don't indent namespaces in C++
set cinoptions=N-s

" Don't wrap lines
set nowrap

" Don't update display during macro execution
set lazyredraw

" Turn on filetype plugins and indent settings
filetype plugin on
filetype indent on

" Set default file encoding
set encoding=utf-8

" Backspace through everything in insert mode
set backspace=indent,eol,start

" Highlight search terms
set hlsearch

" Incremental searching
set incsearch

" Make search case-insensitive and smart
set ic
set smartcase

" Show information about running command
set showcmd

" Show current mode
set showmode

" Shortcuts to save current file if modified
noremap <silent> <Leader>s :update<CR>
noremap <silent> <Leader>w :update<CR>

" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

" Execute q macro with Q
nnoremap Q @q

" Turn on hybrid line numbers (or relative line numbers before Vim 7.4)
set number
set relativenumber

" Make F2 toggle line numbers
nnoremap <silent> <F2> :set nu! <bar> if &nu <bar> set rnu <bar> else <bar>
            \set nornu <bar> endif<CR>

let hasmac=has("mac")
let haswin=has("win16") || has("win32") || has("win64")
let hasunix=has("unix")

" Allow switching buffer without saving changes first
set hidden

" Turn on syntax highlighting
syntax enable

" Turn on autocompletion
set wildmenu
set wildmode=full

" Make it easy to edit this file (, 'e'dit 'v'imrc)
nmap <silent> ,ev :e $MYVIMRC<CR>

" Make it easy to source this file (, 's'ource 'v'imrc)
nmap <silent> ,sv :so $MYVIMRC<CR>

" Highlight current line in active window
augroup BgHighlight
    autocmd!
    autocmd BufRead,BufNewFile * set cul
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END

" Shortcuts for switching buffer
nmap <silent> <C-p> :bp<CR>
nmap <silent> <C-n> :bn<CR>

" Shortcut to use vim grep recursively or non-recursively
nmap ,gr :vim //j **/*.*<C-Left><C-Left><Right>
nmap ,gn :vim //j *.*<C-Left><C-Left><Right>

" Open tag in vertical split with Alt-]
nnoremap <M-]> <C-w><C-]><C-w>L

" Use visual bell instead of sound
set vb

" Enable persistent undo
set undofile
set undolevels=1000
set undoreload=10000

" Make vim remember more commands
set history=1000

" Shorter timeout length for multi-key mappings
set timeoutlen=500

" Import scripts (e.g. NERDTree)
execute pathogen#infect()

" Automatically close NERDTree after opening a buffer
let NERDTreeQuitOnOpen=1

" Don't let NERDTree override netrw
let NERDTreeHijackNetrw=0

" Map Alt-- to navigate to current file in NERDTree
nnoremap <silent> <M--> :NERDTreeFind<CR>

" Make B an alias for Bclose
command! -nargs=* -bang B Bclose<bang><args>

" Shortcut to toggle taglist
autocmd VimEnter * if exists(":TlistToggle") | exe "nnoremap <silent> <Leader>t :TlistToggle<CR>" | endif

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr = 1
let OmniCpp_MayCompleteScope = 1
au CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif

if hasmac
    " Enable use of option key as meta key
    set macmeta
endif

" Enable Arduino syntax highlighting
autocmd BufRead,BufNewFile *.ino set filetype=arduino
autocmd BufRead,BufNewFile */arduino/*.cpp set filetype=arduino
autocmd BufRead,BufNewFile */arduino/*.h set filetype=arduino
autocmd FileType arduino setlocal cindent
autocmd FileType arduino map <F7> :wa<CR>:silent !open $ARDUINO_DIR/build.app<CR>
            \:silent !$ARDUINO_DIR/mk_arduino_tags.sh teensy3<CR>
autocmd FileType arduino map <S-F7> :wa<CR>:silent !$ARDUINO_DIR/mk_arduino_tags.sh teensy3<CR>

" Set comment delimiters for Arduino
let g:NERDCustomDelimiters={
            \ 'arduino': { 'left': '//', 'leftAlt': '/*', 'rightAlt': '*/' },
            \ }

" Add Arduino support to taglist.vim plugin
let tlist_arduino_settings = 'c++;n:namespace;v:variable;d:macro;t:typedef;' .
            \ 'c:class;g:enum;s:struct;u:union;f:function'

" Override some default settings for Processing files
autocmd FileType processing setl softtabstop=2|setl formatoptions-=o
autocmd FileType processing map <F7> :w<bar>call RunProcessing()<CR>|unmap <F5>

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
    unmap <C-y>

    " Map increment/decrement function to Alt instead of Ctrl
    nnoremap <M-a> <C-a>
    nnoremap <M-x> <C-x>

    " Make Ctrl-c exit visual/select mode after copying
    vnoremap <C-c> "+y<Esc>
    snoremap <C-c> <C-g>"+y<Esc>

    " Make NERDCommenter work in select mode
    smap <Bslash> <C-g><Bslash>

    " Shortcut to explore to current file
    nnoremap <silent> <F5> :silent execute "!start explorer /select,\"" . expand("%:p") . "\""<CR>
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
    	nnoremap <silent> <F5> :silent !reveal %:p > /dev/null<CR>:redraw!<CR>
    endif
endif

" Make Ctrl-c function the same as Esc in insert mode
imap <C-c> <Esc>

" Set color scheme
colorscheme desert

" Make background darker in CSApprox
let g:CSApprox_hook_post = 'highlight Normal ctermbg=234'

" Assume powerline characters are available
let g:airline_powerline_fonts = 1

if has('gui_running')
    " Copy mouse modeless selection to clipboard
    set guioptions+=A

    if haswin
        " Set font for gVim
        if hostname() ==? 'Jake-Desktop'
            " Big font for big TV
            set guifont=Inconsolata:h14
        else
            set guifont=Inconsolata:h14
        endif

        " Disable airline special characters in Windows
        let g:airline_powerline_fonts = 0
        let g:airline_left_sep=''
        let g:airline_right_sep=''

        " Hide menu/toolbars
        set guioptions-=m
        set guioptions-=T
    elseif hasmac
        " Set font for MacVim
        set guifont=Inconsolata\ for\ Powerline:h18

        " Start in fullscreen mode
        autocmd VimEnter * set fullscreen
    else
        " Set font for gVim
        set guifont=Inconsolata\ for\ Powerline\ Medium\ 15
    endif
endif

if hasunix
    " Enable mouse
    set mouse=a

    " Run commands in interactive shell
    set shellcmdflag=-ic
endif

" Shortcuts for switching tab
nmap <silent> <C-tab>   :tabnext<CR>
nmap <silent> <F12>     :tabnext<CR>
nmap <silent> <C-S-tab> :tabprevious<CR>
nmap <silent> <F11>     :tabprevious<CR>

" Always show statusline
set laststatus=2

" Settings for Mac SSH session
if (hasmac && !empty($SSH_CLIENT))
    " Disable graphical plugins
    let g:CSApprox_verbose_level = 0
    let g:airline_powerline_fonts = 0

    " Increase time allowed for multi-key mappings
    set timeoutlen=1000
endif

" Settings for running in a terminal under Windows
if !haswin && !hasmac
    " Shortcuts for moving cursor in command in PuTTY
    cmap <ESC>[C <C-Right>
    cmap <ESC>[D <C-Left>

    " Shortcuts to change tab in MinTTY
    nnoremap [1;5I gt
    nnoremap [1;6I gT

    " Map escape sequences to act as meta keys in normal mode
    let ns  = range(33,78) + range(80,90) + range(92,123) + range(125,126)
    for n in ns
        exec "nmap ".nr2char(n)." <M-".nr2char(n).">"
    endfor
    unlet ns n
endif

" Shortcut to print number of occurences of last search
nnoremap <silent> <M-n> <Esc>:%s///gn<CR>
nnoremap <silent> <Leader>n <Esc>:%s///gn<CR>

" Delete without yank by default, and <M-d> for delete with yank
nnoremap c "_c|nnoremap <M-c> c|nnoremap ,c c|vnoremap c "_c|vnoremap <M-c> c|vnoremap ,c c
nnoremap C "_C|nnoremap <M-C> C|nnoremap ,C C|vnoremap C "_C|vnoremap <M-C> C|vnoremap ,C C
nnoremap d "_d|nnoremap <M-d> d|nnoremap ,d d|vnoremap d "_d|vnoremap <M-d> d|vnoremap ,d d
nnoremap D "_D|nnoremap <M-D> D|nnoremap ,D D|vnoremap D "_D|vnoremap <M-D> D|vnoremap ,D D
nnoremap s "_s|nnoremap <M-s> s|nnoremap ,s s|vnoremap s "_s|vnoremap <M-s> s|vnoremap ,s s
nnoremap S "_S|nnoremap <M-S> S|nnoremap ,S S|vnoremap S "_S|vnoremap <M-S> S|vnoremap ,S S
nnoremap x "_x|nnoremap <M-x> x|nnoremap ,x x|vnoremap x "_x|vnoremap <M-x> x|vnoremap ,x x
nnoremap X "_X|nnoremap <M-X> X|nnoremap ,X X|vnoremap X "_X|vnoremap <M-X> X|vnoremap ,X X

" Copy full file path to clipboard on Ctrl-g
nnoremap <C-g> :let @+=expand('%:p')<CR><C-g>

" Move current tab to last position
nnoremap <silent> <C-w><C-e> :tabm +99<CR>
nnoremap <silent> <C-w>e     :tabm +99<CR>

" Remove last newline after copying visual selection to clipboard
function! RemoveClipboardNewline()
    if &updatetime==1
        let @*=substitute(@*,'\n$','','g')
        set updatetime=4000
    endif
endfunction
function! s:VisualEnter(arg)
    set updatetime=1
    return a:arg
endfunction
vnoremap <expr> <SID>VisualEnter VisualEnter()
nnoremap <expr> v <SID>VisualEnter('v')
nnoremap <expr> V <SID>VisualEnter('V')
autocmd CursorHold * call RemoveClipboardNewline()

" Override plugin mappings after startup
autocmd VimEnter * silent! unmap <Tab>

" Don't auto comment new line made with 'o' or 'O'
autocmd BufNewFile,BufRead * setlocal formatoptions-=o
