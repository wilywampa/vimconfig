" {{{1 Vim built-in configuration

" Allow settings that are not vi-compatible
if &compatible
    set nocompatible
endif

" Reset autocommands when vimrc is re-sourced
augroup VimrcAutocmds
    autocmd!
augroup END

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
set wildmode=full
set visualbell                 " Use visual bell instead of sound
sil! set undofile              " Enable persistent undo
set undolevels=1000
sil! set undoreload=10000
set timeoutlen=500             " Shorter timeout length for multi-key mappings
set ttimeout                   " Even shorter delay for keycode mappings
set ttimeoutlen=50
set laststatus=2               " Always show statusline
set listchars=tab:>\           " Configure display of whitespace
set listchars+=trail:-
set listchars+=extends:>
set listchars+=precedes:<
set listchars+=nbsp:+

" Turn on filetype plugins and indent settings
filetype plugin indent on

" Turn on syntax highlighting
if !exists("syntax_on")
    syntax enable
endif

" Use four spaces to indent vim file line continuation
let g:vim_indent_cont=4

" Session settings
set sessionoptions=buffers,curdir,folds,help,tabpages,winsize
augroup VimrcAutocmds
    au VimLeavePre * mks! ~/session.vis
    au VimEnter * mks! ~/periodic_session.vis
    au VimEnter * exe "au BufEnter,BufRead,BufWrite,CursorHold * silent! mks! ~/periodic_session.vis"
augroup END
nnoremap <silent> ,l :source ~/session.vis<CR>

" Like bufdo but return to starting buffer
func! Bufdo(command)
    let currBuff=bufnr("%")
    execute 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunc
com! -nargs=+ -complete=command Bufdo call Bufdo(<q-args>)

" Shortcuts to switch to last active tab/window
let g:lastTab=1
let g:lastWin=1
let g:lastWinTab=1
augroup VimrcAutocmds
    au TabLeave * let g:lastTab=tabpagenr()
    au WinLeave * let g:lastWin=winnr() | let g:lastWinTab=tabpagenr()
augroup END
nnoremap <silent> <Leader>l :exe "tabn ".g:lastTab<CR>
nnoremap <silent> ` :exe 'tabn '.g:lastWinTab' \| '.g:lastWin.'wincmd w'<CR>

" {{{2 Platform-specific configuration

let hasMac=has("mac")
let hasWin=has("win16") || has("win32") || has("win64")
let hasUnix=has("unix")
let hasSSH=!empty($SSH_CLIENT)
let macSSH=hasMac && hasSSH

if hasWin
    " Change where backups are saved
    if !isdirectory("C:\\temp\\vimtmp")
        call mkdir("C:\\temp\\vimtmp", "p")
    endif
    set backupdir=C:\temp\vimtmp,.
    set directory=C:\temp\vimtmp,.
    sil! set undodir=C:\temp\vimtmp,.

    " Shortcut to explore to current file
    nnoremap <silent> <F4> :silent execute "!start explorer /select,\"" . expand("%:p") . "\""<CR>
else
    " Change swap file location for unix
    if !isdirectory(expand("~/.tmp"))
        call mkdir(expand("~/.tmp"), "p")
    endif
    set backupdir=~/.tmp
    set directory=~/.tmp
    sil! set undodir=~/.tmp

    if hasMac
        " Shortcut to reveal current file in Finder
        nnoremap <silent> <F4> :silent !reveal %:p > /dev/null<CR>:redraw!<CR>

        " Enable use of option key as meta key
        sil! set macmeta
    endif
endif

if hasUnix
    " Enable mouse
    set mouse=a
endif

" {{{2 Mappings

" Shortcuts to save current file if modified
nn <silent> <Leader>w :update<CR>
no <silent> <C-s> :update<CR>
vn <silent> <C-s> <C-c>:update<CR>
ino <silent> <C-s> <Esc>:update<CR>

" <Ctrl-l> redraws the screen and removes any search highlighting.
nn <silent> <C-l> :nohl<CR><C-l>

" Execute q macro with Q
nm Q @q

" Execute q macro recursively
nn <silent> <Leader>q :set nows<CR>:let @q=@q."@q"<CR>:norm @q<CR>:set ws<CR>

" Shortcut to toggle paste mode
nn <silent> <Leader>p :set paste!<CR>

" Shortcut to select all
nn <Leader>a ggVG
vn <Leader>a <C-c>ggVG

" Make F2 toggle line numbers
nn <silent> <F2> :se nu!\|if &nu\|sil! se rnu\|el\|sil! se nornu\|en<CR>

" Make it easy to edit this file (, 'e'dit 'v'imrc)
" Open in new tab if current window is not empty
nn <silent> ,ev :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|tab drop $MYVIMRC\|el\|e $MYVIMRC\|en<CR>

" Make it easy to edit bashrc
nn <silent> ,eb :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|tab drop ~/.bashrc\|el\|e ~/.bashrc\|en<CR>

" Make it easy to edit cshrc
nn <silent> ,ec :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|tab drop ~/.cshrc\|el\|e ~/.cshrc\|en<CR>

" Make it easy to edit zshrc
nn <silent> ,ez :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|tab drop ~/.zshrc\|el\|e ~/.zshrc\|en<CR>

" Make it easy to source this file (, 's'ource 'v'imrc)
nn <silent> ,sv :so $MYVIMRC<CR>

" Shortcuts for switching buffer
nn <silent> <C-p> :bp<CR>
nn <silent> <C-n> :bn<CR>

" Shortcuts to use vim grep recursively or non-recursively
nn ,gr :vim // **/*<C-Left><C-Left><Right>
nn ,gn :vim // *<C-Left><C-Left><Right>
nn ,go :call setqflist([])<CR>:silent! Bufdo vimgrepa // %<C-Left><C-Left><Right>

" Shortcut to delete trailing whitespace
nn <silent> ,ws :keepj %s/\s\+$//g<CR>:call histdel('/',-1)<CR>

" Open tag in vertical split with Alt-]
nn <M-]> <C-w><C-]><C-w>L

" Make Ctrl-c function the same as Esc in insert mode
ino <C-c> <Esc>

" Shortcuts for switching tab, including closing command window if it's open
augroup VimrcAutocmds
    au VimEnter,CmdwinLeave * nn <silent> <C-Tab>    gt
    au VimEnter,CmdwinLeave * nn <silent> <C-S-Tab>  gT
    au VimEnter,CmdwinLeave * nn <silent> <M-l>      gt
    au VimEnter,CmdwinLeave * nn <silent> <M-h>      gT
    au VimEnter,CmdwinLeave * nn <M-(>               gt
    au VimEnter,CmdwinLeave * nn <M-)>               gT

    au CmdwinEnter * nn <silent> <C-Tab>   <C-c><C-c>gt
    au CmdwinEnter * nn <silent> <C-S-Tab> <C-c><C-c>gT
    au CmdwinEnter * nn <silent> <M-l>     <C-c><C-c>gt
    au CmdwinEnter * nn <silent> <M-h>     <C-c><C-c>gT
    au CmdwinEnter * nn <silent> <M-(>     <C-c><C-c>gt
    au CmdwinEnter * nn <silent> <M-)>     <C-c><C-c>gT
augroup END

" Shortcut to open new tab
nn <silent> <M-t> :tabnew<CR>

" Shortcut to print number of occurences of last search
nn <silent> <M-n> :%s///gn<CR>

" Shortcut to make last search a whole word
nn <silent> <Leader>n :let @/='\<'.@/.'\>'<CR>

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
nn <C-g> :let @*=expand('%:p')<CR><C-g>

" Move current tab to last position
nn <silent> <C-w><C-e> :tabm<CR>
nn <silent> <C-w>e     :tabm<CR>

" Insert result of visually selected expression
vn <C-e> c<C-o>:let @"=substitute(@",'\n','','g')<CR><C-r>=<C-r>"<CR><Esc>

" Make <C-c> cancel <C-w> instead of closing window
no <C-w><C-c> <NOP>

augroup VimrcAutocmds
    " Don't let <C-w>q/<C-w><C-q> close last window
    au VimEnter,CmdwinLeave * no <C-w><C-q> <C-w>c
    au VimEnter,CmdwinLeave * no <C-w>q <C-w>c
    au VimEnter,CmdwinLeave * sil! nun <C-w><C-w>

    " Close command window with <C-w>q/<C-w><C-q>/<C-w><C-w>
    au CmdwinEnter * no <C-w><C-q> <C-c><C-c>
    au CmdwinEnter * no <C-w>q <C-c><C-c>
    au CmdwinEnter * no <C-w><C-w> <C-c><C-c>
augroup END

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

" Ctrl-c copies visual selection to system clipboard
vn <C-c> "*y<C-c>

" File explorer at current buffer with -
nn <silent> - :Explore<CR>

" Repeat last command with a bang
nn @! :<Up><Home><C-Right>!<CR>

" Repeat last command with case of first character switched
nn @~ :<Up><C-f>^~<CR>

" <C-v> pastes from system clipboard
map <C-V> "*gP
cmap <C-V> <C-R>*
exe 'inoremap <script> <C-V> <C-G>u'.paste#paste_cmd['i']
exe 'vnoremap <script> <C-V> '.paste#paste_cmd['v']

" Use <C-q> to do what <C-v> used to do
noremap <C-q> <C-v>

" Show current line of diff at bottom of tab
nn <Leader>dl tsjJtlsjJt:res<CR>b

" Make Y behave like other capital letters
map Y y$

" Navigate windows with arrow keys
no <Down>  <C-w>j
no <Up>    <C-w>k
no <Left>  <C-w>h
no <Right> <C-w>l

" Change window size with control + arrow keys
no <C-Down>  <C-w>-
no <C-Up>    <C-w>+
no <C-Left>  <C-w><
no <C-Right> <C-w>>

" Use ,n and ,N or ,p to cycle through quickfix results
no ,n :cn<CR>
no ,N :cp<CR>
no ,p :cp<CR>

" Use ,,n and ,,N or ,,p to cycle through location list results
no ,,n :lne<CR>
no ,,N :lp<CR>
no ,,p :lp<CR>

" Stay in visual mode after indent change
vn < <gv
vn > >gv

" Copy WORD above/below cursor with <M-y>/<M-e>
ino <expr> <M-y> matchstr(getline(line('.')-1),'\%'.virtcol('.').'v\%(\S\+\\|.\)')
ino <expr> <M-e> matchstr(getline(line('.')+1),'\%'.virtcol('.').'v\%(\S\+\\|.\)')

" {{{2 Cscope configuration

" Use quickfix list for cscope results
set cscopequickfix=s-,c-,d-,i-,t-,e-

" Use cscope instead of ctags when possible
set cscopetag

" Abbreviations for diff commands
cnoreabbrev <expr> dt ((getcmdtype() == ':' && getcmdpos() <= 3)? 'windo diffthis' : 'dt')
cnoreabbrev <expr> do ((getcmdtype() == ':' && getcmdpos() <= 3)? 'windo diffoff'  : 'do')
cnoreabbrev <expr> du ((getcmdtype() == ':' && getcmdpos() <= 3)? 'diffupdate'     : 'du')

" Abbreviations for cscope commands
cnoreabbrev <expr> csa ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs add'   : 'csa')
cnoreabbrev <expr> csf ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs find'  : 'csf')
cnoreabbrev <expr> csk ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs kill'  : 'csk')
cnoreabbrev <expr> csr ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs reset' : 'csr')
cnoreabbrev <expr> css ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs show'  : 'css')
cnoreabbrev <expr> csh ((getcmdtype() == ':' && getcmdpos() <= 4)? 'cs help'  : 'csh')

" Mappings for cscope find commands
no <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
no <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
no <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
no <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
no <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
no <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
no <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
no <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>

" }}}2

if has('gui_running')
    " Copy mouse modeless selection to clipboard
    set guioptions+=A

    " Don't use second vertical scrollbar
    set guioptions-=L

    " Hide menu/toolbars
    set guioptions-=m
    set guioptions-=T

    if hasWin
        " Set font for gVim
        if hostname() ==? 'Jake-Desktop'
            " Big font for big TV
            set guifont=Consolas:h14
        else
            set guifont=Consolas:h11
        endif
    elseif hasMac
        " Set font for MacVim
        set guifont=Consolas:h17

        " Start in fullscreen mode
        augroup VimrcAutocmds
            autocmd VimEnter * sil! set fullscreen
        augroup END
    else
        " Set font for gVim
        set guifont=Inconsolata\ for\ Powerline\ Medium\ 15
    endif
else
    " Make control + arrow keys work in PuTTY
    set <M-:>=[A " <C-Up>
    set <M-'>=[B " <C-Down>
    map <M-:> <C-Up>
    map <M-'> <C-Down>
    map! <M-:> <C-Up>
    map! <M-'> <C-Down>
    set <C-Right>=[C
    set <C-Left> =[D

    " Shortcuts to change tab in MinTTY
    set <M-(>=[1;5I " <C-Tab>
    set <M-)>=[1;6I " <C-S-Tab>

    " Set key codes to work as meta key combinations
    let ns=range(65,90)+range(92,123)+range(125,126)
    for n in ns
        exec "set <M-".nr2char(n).">=".nr2char(n)
    endfor
    set <M-\|>=\| " Bar needs special handling
endif

if hasSSH
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

    " Disable paste mode after leaving insert mode
    autocmd InsertLeave * set nopaste
augroup END

" Delete hidden buffers
func! DeleteHiddenBuffers()
    let tpbl=[]
    call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
    for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
        silent! execute 'bd' buf
    endfor
endfunc
nnoremap <silent> <Leader>dh :call DeleteHiddenBuffers()<CR>

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

" Abbreviation to open help in new tab
cnoreabbrev <expr> ht ((getcmdtype() == ':' && getcmdpos() <= 3)? 'tab help'  : 'ht')

" Set color scheme
colorscheme desert

" {{{1 Plugin configuration

" Set airline color scheme
let g:airline_theme='badwolf'
let g:airline#extensions#ctrlp#color_template='normal'

" Use powerline font unless in Mac SSH session or in old Vim
if macSSH || v:version < 704
    let g:airline_powerline_fonts=0
    let g:airline_left_sep=''
    let g:airline_right_sep=''

    " Disable background color erase
    set t_ut=
else
    let g:airline_powerline_fonts=1
endif

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

" Shortcut to force close buffer without closing window
nnoremap <silent> <Leader><Leader>bd :Bclose!<CR>

" ZZ and ZQ close buffer instead of just closing window
nn <silent> ZZ :up<CR>:sil! Bclose<CR>:q<CR>
nn <silent> ZQ :sil! Bclose!<CR>:q!<CR>

" Tagbar configuration
augroup VimrcAutocmds
    autocmd VimEnter * if exists(":TagbarToggle") | exe "nnoremap <silent>
        \ <Leader>t :TagbarToggle<CR>" | endif
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
let g:tagbar_type_arduino={
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

" Add Processing support to Tagbar (Processing is not C++, but is close enough
" for C++ tags to be useful)
let g:tagbar_type_processing=g:tagbar_type_arduino

" Override some default settings for Processing files
augroup VimrcAutocmds
    autocmd FileType processing setl softtabstop=2|setl formatoptions-=o
    autocmd FileType processing nnoremap <buffer> <silent> <F5> :cd %:p:h<CR>:up<bar>call
        \ RunProcessing()<CR>:silent !ctags --language-force=c++ %<CR>:cd -<CR>
    autocmd FileType processing nnoremap <buffer> <silent> <S-F5> :silent
        \ !ctags --language-force=c++ %<CR>
augroup END

" Make NERDCommenter work in select mode
smap <Bslash> <C-g><Bslash>

" CtrlP configuration
let g:ctrlp_cmd='CtrlPMRU'
let g:ctrlp_map='<M-p>'
let g:ctrlp_clear_cache_on_exit=0
let g:ctrlp_tabpage_position='al'
let g:ctrlp_show_hidden=1
let g:ctrlp_custom_ignore='\v[\/]\.(git|hg|svn)$'
let g:ctrlp_follow_symlinks=1
let g:ctrlp_by_filename=1
let g:ctrlp_regexp=1
augroup VimrcAutocmds
    autocmd VimEnter * nnoremap <silent> <M-p> :let v:errmsg=""<CR>:CtrlPMRU<CR>
augroup END
nnoremap <silent> <M-f> :let v:errmsg=""<CR>:CtrlPBuffer<CR>

" Map <C-q> to delete buffer in CtrlP
let g:ctrlp_buffer_func={ 'enter': 'MyCtrlPMappings' }
func! MyCtrlPMappings()
    nnoremap <buffer> <silent> <C-q> :call <SID>DeleteBuffer()<cr>
endfunc
func! s:DeleteBuffer()
    let line=getline('.')
    " Use substitute to remove status characters after filename
    let bufid=line =~ '\[\d\+\*No Name\]\( [#-=+.]*\)\?$' ? str2nr(matchstr(line, '\d\+'))
        \ : substitute(fnamemodify(line[2:], ':p'),'\m\(.*\) [#-=+.]*$','\1','')
    exec "bd" bufid
    exec "norm \<F5>"
endfunc

" Disable CSApprox if color palette is too small
if !has('gui_running') && (&t_Co < 88)
    let g:pathogen_disabled=[]
    call add(g:pathogen_disabled, 'CSApprox')
endif

" {{{2 EasyMotion settings
map <S-Space> <Space>
map! <S-Space> <Space>
let g:EasyMotion_keys='ABCDEFGIMNOPQRSTUVWXYZLKJH'
let g:EasyMotion_use_upper=1
map <Space> <Plug>(easymotion-bd-f)
map <Space><Space>f <Plug>(easymotion-bd-f)
map <Space><Space>F <Plug>(easymotion-bd-f)
map <Space><Space>t <Plug>(easymotion-bd-t)
map <Space><Space>T <Plug>(easymotion-bd-t)
map <Space><Space>w <Plug>(easymotion-bd-w)
map <Space><Space>W <Plug>(easymotion-bd-W)
map <Space><Space>b <Plug>(easymotion-bd-w)
map <Space><Space>B <Plug>(easymotion-bd-W)
map <Space><Space>e <Plug>(easymotion-bd-e)
map <Space><Space>E <Plug>(easymotion-bd-E)
map <Space><Space>j <Plug>(easymotion-bd-jk)
map <Space><Space>k <Plug>(easymotion-bd-jk)
map <Space><Space>n <Plug>(easymotion-bd-n)
map <Space><Space>N <Plug>(easymotion-bd-n)
map <Space><Space>/ <Plug>(easymotion-sn)
augroup VimrcAutocmds
    autocmd VimEnter * unmap <Leader><Leader>
augroup END
" }}}2

" Undotree settings
nnoremap <Leader>u :UndotreeToggle<CR>
let g:undotree_SplitWidth=40

" Surround settings
xmap S <Plug>VSurround

" Choose SuperTab completion type based on context
let g:SuperTabDefaultCompletionType="context"

" Tabular configuration
augroup VimrcAutocmds
    autocmd VimEnter * AddTabularPipeline! align_with_equals
        \ /^[^=]*\zs=\([^;]*$\)\@=
        \\|^\s*\zs=\@<!\S[^=]*;.*$
        \\|^\s*\zs\([{}]\)\@!\(\/\/\)\@!\S[^;]*\(\*\/\)\@<!$/
        \ map(a:lines,"substitute(v:val,'^\\s*\\(.*=\\)\\@!','','g')")
        \ | tabular#TabularizeStrings(a:lines,
        \ '^\s*\zs\S\(.*=\)\@!.*$\|^[^=]*\zs=\([^;]*$\)\@=.*$','l1')
augroup END

" Function to find and align lines of a C assignment
func! s:AlignUnterminatedAssignment()
    if !hlexists('cComment') | return | endif
    let s:pat='^.*[=!<>]\@<!\zs=\ze=\@![^;]*$'
    call search(s:pat,'W')
    while (synIDattr(synID(line("."), col("."), 1), "name")) =~? 'comment'
        call search(s:pat,'W')
    endwhile
    .,/;/Tabularize align_with_equals
    call search(';','W')
endfunc
com! AlignUnterminatedAssignment call <SID>AlignUnterminatedAssignment()

" Import scripts (e.g. NERDTree)
execute pathogen#infect()

" Add current directory to status line
let g:airline_section_b=airline#section#create(['%{ShortCWD()}'])

" Default whitespace symbol not available everywhere
if exists('g:airline_symbols')
    let g:airline_symbols.whitespace='!'
endif

" vim: set fdm=marker:
