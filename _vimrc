" {{{ Vim built-in configuration

" Allow settings that are not vi-compatible
set nocompatible

" Reset autocommands when vimrc is re-sourced
augroup VimrcAugroup
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
set ic                         " Make search case-insensitive and smart
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
set vb                         " Use visual bell instead of sound
set undofile                   " Enable persistent undo
set undolevels=1000
set undoreload=10000
set history=1000               " Make vim remember more commands
set timeoutlen=500             " Shorter timeout length for multi-key mappings
set ttimeout                   " Even shorter delay for keycode mappings
set ttimeoutlen=50
set laststatus=2               " Always show statusline
set foldopen-=block            " Don't open folds when traversed block-wise

" Turn on filetype plugins and indent settings
filetype plugin indent on

" Turn on syntax highlighting
syntax enable

" {{{ Mappings

" Shortcuts to save current file if modified
noremap <silent> <Leader>s :update<CR>
noremap <silent> <Leader>w :update<CR>

" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

" Execute q macro with Q
nnoremap Q @q

" Shortcut to toggle paste mode
nnoremap <silent> <Leader>p :set paste!<CR>

" Make F2 toggle line numbers
nnoremap <silent> <F2> :se nu!|if &nu|se rnu|el|se nornu|en<CR>

" Make it easy to edit this file (, 'e'dit 'v'imrc)
nmap <silent> ,ev :e $MYVIMRC<CR>

" Make it easy to source this file (, 's'ource 'v'imrc)
nmap <silent> ,sv :so $MYVIMRC<CR>

" Shortcuts for switching buffer
nmap <silent> <C-p> :bp<CR>
nmap <silent> <C-n> :bn<CR>

" Shortcuts to use vim grep recursively or non-recursively
nnoremap ,gr :vim //j **/*<C-Left><C-Left><Right>
nnoremap ,gn :vim //j *<C-Left><C-Left><Right>
nnoremap ,go :call setqflist([])<CR>:Bufdo vimgrepa //j %<C-Left><C-Left><Right>

" Open tag in vertical split with Alt-]
nnoremap <M-]> <C-w><C-]><C-w>L

" Make Ctrl-c function the same as Esc in insert mode
imap <C-c> <Esc>

" Shortcuts for switching tab
nmap <silent> <C-tab>   :tabnext<CR>
nmap <silent> <F12>     :tabnext<CR>
nmap <silent> <C-S-tab> :tabprevious<CR>
nmap <silent> <F11>     :tabprevious<CR>

" Shortcut to open new tab
nnoremap <silent> <M-t> :tabnew<CR>

" Shortcut to print number of occurences of last search
nnoremap <silent> <M-n> <Esc>:%s///gn<CR>
nnoremap <silent> <Leader>n <Esc>:%s///gn<CR>

" Delete without yank by default, and <M-d> for delete with yank
nnoremap c "_c|nnoremap <M-c> c|nnoremap \\c c|vnoremap c "_c|vnoremap <M-c> c|vnoremap \\c c
nnoremap C "_C|nnoremap <M-C> C|nnoremap \\C C|vnoremap C "_C|vnoremap <M-C> C|vnoremap \\C C
nnoremap d "_d|nnoremap <M-d> d|nnoremap \\d d|vnoremap d "_d|vnoremap <M-d> d|vnoremap \\d d
nnoremap D "_D|nnoremap <M-D> D|nnoremap \\D D|vnoremap D "_D|vnoremap <M-D> D|vnoremap \\D D
nnoremap s "_s|nnoremap <M-s> s|nnoremap \\s s|vnoremap s "_s|vnoremap <M-s> s|vnoremap \\s s
nnoremap S "_S|nnoremap <M-S> S|nnoremap \\S S|vnoremap S "_S|vnoremap <M-S> S|vnoremap \\S S
nnoremap x "_x|nnoremap <M-x> x|nnoremap \\x x|vnoremap x "_x|vnoremap <M-x> x|vnoremap \\x x
nnoremap X "_X|nnoremap <M-X> X|nnoremap \\X X|vnoremap X "_X|vnoremap <M-X> X|vnoremap \\X X

" Copy full file path to clipboard on Ctrl-g
nnoremap <C-g> :let @+=expand('%:p')<CR><C-g>

" Move current tab to last position
nnoremap <silent> <C-w><C-e> :tabm +99<CR>
nnoremap <silent> <C-w>e     :tabm +99<CR>

" }}}

" Session settings
set sessionoptions=buffers,curdir,folds,help,tabpages,winsize
augroup VimrcAutocmds
    autocmd VimLeavePre * mksession! ~/session.vis
    autocmd BufRead,BufEnter * mksession! ~/periodic_session.vis
augroup END
nnoremap <silent> ,l :source ~/session.vis<CR>

" Highlight current line in active window
augroup BgHighlight
    autocmd!
    autocmd BufRead,BufNewFile * set cul
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END

" Like bufdo but return to starting buffer
function! Bufdo(command)
  let currBuff=bufnr("%")
  execute 'bufdo ' . a:command
  execute 'buffer ' . currBuff
endfunction
com! -nargs=+ -complete=command Bufdo call Bufdo(<q-args>)

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
    unmap <C-y>

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

if has('gui_running')
    " Copy mouse modeless selection to clipboard
    set guioptions+=A

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

" Don't auto comment new line made with 'o' or 'O'
augroup VimrcAutocmds
    autocmd FileType * set formatoptions-=o
augroup END

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

" Don't use tagbar integration in airline in csh (slow startup)
if &shell ==# '/bin/csh'
    let g:airline#extensions#tagbar#enabled=1
endif

" Shortcut to toggle warnings in airline
function! s:ToggleAirlineWarnings()
    if g:airline_section_warning == ''
        let g:airline_section_warning='%{airline#util#wrap(airline#extensions#whitespace#check(),0)}'
    else
        let g:airline_section_warning=''
    endif
    exe 'AirlineToggle' | exe 'AirlineToggle'
endfunction
nnoremap <silent> <M-w> :call <SID>ToggleAirlineWarnings()<CR>

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

" Enable Arduino syntax highlighting
augroup VimrcAutocmds
    autocmd BufRead,BufNewFile *.ino set filetype=arduino
    autocmd BufRead,BufNewFile */arduino/*.cpp set filetype=arduino
    autocmd BufRead,BufNewFile */arduino/*.h set filetype=arduino
    autocmd FileType arduino setlocal cindent
    autocmd FileType arduino nnoremap <F7> :wa<CR>:silent !open $ARDUINO_DIR/build.app<CR>
                \:silent !$ARDUINO_DIR/mk_arduino_tags.sh teensy3<CR>
    autocmd FileType arduino nnoremap <S-F7> :wa<CR>:silent !$ARDUINO_DIR/mk_arduino_tags.sh teensy3<CR>
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
    nnoremap <buffer> <silent> <C-q> :call <sid>DeleteBuffer()<cr>
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
    autocmd VimEnter * silent! unmap <ScrollWheelUp>
    autocmd VimEnter * silent! unmap <ScrollWheelDown>
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

" }}}

" vim: set fdm=marker:
