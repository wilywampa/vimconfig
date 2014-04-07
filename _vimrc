" {{{1 Vim built-in configuration

" Allow settings that are not vi-compatible
if &compatible
    set nocompatible
endif

" Reset autocommands when vimrc is re-sourced
augroup VimrcAutocmds
    autocmd!
augroup END

" Check if in read-only mode to disable unnecessary plugins
if !exists('s:readonly')
    let s:readonly=&readonly
endif

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
set listchars=tab:>\           " Configure display of whitespace
set listchars+=trail:-
set listchars+=extends:>
set listchars+=precedes:<
set listchars+=nbsp:+
set keywordprg=:help           " Use Vim help instead of man to look up keywords
set splitright                 " Vertical splits open on the right
set fileformats=unix,dos       " Always prefer unix format

" Turn on filetype plugins and indent settings
filetype plugin indent on

" Turn on syntax highlighting
if !exists("syntax_on")
    syntax enable
endif

" Use four spaces to indent vim file line continuation
let g:vim_indent_cont=4

" Session settings
if !s:readonly
    set sessionoptions=buffers,curdir,folds,help,tabpages,winsize
    augroup VimrcAutocmds
        au VimLeavePre * mks! ~/session.vis
        au VimEnter * mks! ~/periodic_session.vis
        au VimEnter * exe "au BufEnter,BufRead,BufWrite,CursorHold * silent! mks! ~/periodic_session.vis"
    augroup END
    nnoremap <silent> ,l :source ~/session.vis<CR>
endif

" Like bufdo but return to starting buffer
func! Bufdo(command)
    let currBuff=bufnr("%")
    execute 'bufdo ' . a:command
    execute 'buffer ' . currBuff
endfunc
com! -nargs=+ -complete=command Bufdo call Bufdo(<q-args>)

" Enable matchit plugin
runtime! macros/matchit.vim

" Use tree style for netrw
let g:netrw_liststyle=3

" {{{2 Switch to existing window if it exists or open in new tab
func! s:SwitchToOrOpen(fname)
    let l:bufnr=bufnr(expand(a:fname))
    if l:bufnr > 0 && buflisted(l:bufnr)
        for l:tab in range(1, tabpagenr('$'))
            let l:buflist = tabpagebuflist(l:tab)
            if index(l:buflist,l:bufnr) >= 0
                for l:win in range(1,tabpagewinnr(l:tab,'$'))
                    if l:buflist[l:win-1] == l:bufnr
                        exec 'tabn '.l:tab
                        exec l:win.'wincmd w'
                        return
                    endif
                endfor
            endif
        endfor
    endif
    exec 'tabedit '.a:fname
endfunc

" {{{2 Shortcuts to switch to last active tab/window
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
        set shellxquote=\" shellcmdflag=-c grepprg=grep\ -nH\ $*\ /dev/null
        nnoremap <silent> <F4> :call system('cygstart explorer /select,\"'.expand('%:p').'\"')<CR>
    endif
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
        nnoremap <silent> <F4> :call system('reveal '.expand('%:p').' > /dev/null')<CR>

        " Enable use of option key as meta key
        sil! set macmeta
    else
        " Shortcut to explore to current file from Cygwin vim
        nnoremap <silent> <F4> :call system('cygstart explorer /select,`cygpath -w "'.expand('%:p').'"`')<CR>
    endif
endif

if hasUnix
    " Enable mouse
    set mouse=a
endif

" {{{2 Mappings

" Shortcuts to save current file if modified or execute command if in command window
nn <silent> <expr> <C-s> g:inCmdwin? '<CR>' : ':update<CR>'
ino <silent> <expr> <C-s> g:inCmdwin? '<CR>' : '<Esc>:update<CR>'
vn <silent> <C-s> <C-c>:update<CR>

" <Ctrl-l> redraws the screen and removes any search highlighting.
nn <silent> <C-l> :nohl<CR><C-l>

" Execute q macro with Q
nm Q @q

" Execute q macro recursively
nn <silent> <Leader>q :set nows<CR>:let @q=@q."@q"<CR>:norm @q<CR>
    \:set ws<CR>:let @q=substitute(@q,'\(^.*\)@q','\1','')<CR>

" Shortcut to toggle paste mode
nn <silent> <Leader>p :set paste!<CR>

" Shortcut to select all
nn <Leader>a ggVG
vn <Leader>a <C-c>ggVG

" Make F2 toggle line numbers
nn <silent> <F2> :se nu!<bar>if &nu<bar>sil! se rnu<bar>el<bar>sil! se nornu<bar>en<CR>
vm <silent> <F2> <Esc><F2>gv

" Make it easy to edit this file (, 'e'dit 'v'imrc)
" Open in new tab if current window is not empty
nn <silent> ,ev :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|call <SID>SwitchToOrOpen($MYVIMRC)\|el\|e $MYVIMRC\|en<CR>

" Make it easy to edit bashrc
nn <silent> ,eb :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|call <SID>SwitchToOrOpen('~/.bashrc')\|el\|e ~/.bashrc\|en<CR>

" Make it easy to edit cshrc
nn <silent> ,ec :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|call <SID>SwitchToOrOpen('~/.cshrc')\|el\|e ~/.cshrc\|en<CR>

" Make it easy to edit zshrc
nn <silent> ,ez :if strlen(expand('%'))\|\|line('$')!=1\|\|getline(1)!=''
    \\|call <SID>SwitchToOrOpen('~/.zshrc')\|el\|e ~/.zshrc\|en<CR>

" Make it easy to source this file (, 's'ource 'v'imrc)
nn <silent> ,sv :so $MYVIMRC<CR>

" Shortcuts for switching buffer
nn <silent> <C-p> :bp<CR>
nn <silent> <C-n> :bn<CR>

" Shortcuts to search recursively or non-recursively
nn ,gr :vim // **/*<C-Left><C-Left><Right>
nn ,gn :vim // *<C-Left><C-Left><Right>
nn ,go :call setqflist([])<CR>:silent! Bufdo vimgrepa // %<C-Left><C-Left><Right>
nn <Leader>gr :grep `find . -type f` -e ''<Left>
nn <Leader>gn :grep `ls` -e ''<Left>

" Shortcut to delete trailing whitespace
nn <silent> ,ws :keepj sil!%s/\s\+$\\|\v$t^//g<CR>
    \:call histdel('/','\V$t^')<CR>:let @/=histget('/',-1)<CR>

" Open tag in vertical split with Alt-]
nn <M-]> <C-w><C-]><C-w>L

" Make Ctrl-c function the same as Esc in insert mode
ino <C-c> <Esc>

" Shortcuts for switching tab, including closing command window if it's open
nn <silent> <expr> <C-Tab>   g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <C-S-Tab> g:inCmdwin? ':q<CR>gT' : 'gT'
nn <silent> <expr> <M-l>     g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <M-h>     g:inCmdwin? ':q<CR>gT' : 'gT'
nn <silent> <expr> <F15>     g:inCmdwin? ':q<CR>gt' : 'gt'
nn <silent> <expr> <F16>     g:inCmdwin? ':q<CR>gT' : 'gT'

" Shortcut to open new tab
nn <silent> <M-t> :tabnew<CR>

" Shortcut to print number of occurences of last search
nn <silent> <M-n> :%s///gn<CR>

" Shortcut to make last search a whole word
nn <silent> <Leader>n :let @/='\<'.@/.'\>'<CR>n
nn <silent> <Leader>N :let @/='\<'.@/.'\>'<CR>N

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
nn <C-g> :let @+=expand('%:p')<CR>:let @*=@+<CR><C-g>

" Move current tab to last position
nn <silent> <C-w><C-e> :tabm<CR>
nn <silent> <C-w>e     :tabm<CR>

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

" Ctrl-c copies visual selection to system clipboard
vn <silent> <C-c> "+y:let @*=@+<CR>

" File explorer at current buffer with -
nn <silent> - :Explore<CR>

" Repeat last command with a bang
nn @! :<Up><Home><C-Right>!<CR>

" Repeat last command with case of first character switched
nn @~ :<Up><C-f>^~<CR>

" <C-v> pastes from system clipboard
map <C-v> "+gP
cmap <C-v> <C-r>+
exe 'inoremap <script> <C-v> <C-g>u'.paste#paste_cmd['i']
exe 'vnoremap <script> <C-v> '.paste#paste_cmd['v']

" Use <C-q> to do what <C-v> used to do
noremap <C-q> <C-v>

" Show current line of diff at bottom of tab
nn <Leader>dl <C-w>t<C-w>s<C-w>j<C-w>J<C-w>t<C-w>l<C-w>s<C-w>j<C-w>J<C-w>t:res<CR><C-w>b

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
nn <silent> ,n :<C-u>exe v:count1.'cn'<CR>zv
nn <silent> ,N :<C-u>exe v:count1.'cp'<CR>zv
nn <silent> ,p :<C-u>exe v:count1.'cp'<CR>zv

" Use ,,n and ,,N or ,,p to cycle through location list results
nn <silent> ,,n :<C-u>exe v:count1.'lne'<CR>zv
nn <silent> ,,N :<C-u>exe v:count1.'lp'<CR>zv
nn <silent> ,,p :<C-u>exe v:count1.'lp'<CR>zv

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

" Shortcut to search for first non-blank
cno <expr> ^ ((getcmdtype()=='/'&&getcmdline()=='^')?'<BS>\(^\s*\)\@<=':'^')

" Execute line under cursor
nn <silent> <Leader>x :exec getline('.')<CR>

" Shortcut to close quickfix window/location list
nn <silent> <Leader>w :ccl\|lcl<CR>

" Shortcut to make current buffer a scratch buffer
nn <silent> <Leader>s :set bt=nofile<CR>

" {{{2 Abbreviations to open help
func! s:OpenHelp(topic)
    let v:errmsg=""
    " Open in same window if current tab is empty, or else open in new window
    if strlen(expand('%')) || line('$')!=1 || getline(1)!='' || winnr('$')>1
        " Open vertically if there's enough room
        let l:split=0
        let l:helpWin=0
        for l:win in range(1,winnr('$'))
            if winwidth(l:win) < &columns
                let l:split=1
                if getwinvar(l:win,'&ft') == 'help'
                    let l:helpWin=l:win
                endif
            endif
        endfor
        if l:helpWin
            " If help is already open in a window, use that window
            exe l:helpWin.'wincmd w'
            setl bt=help
            exe 'sil! help '.a:topic
        elseif (&columns > 160) && !l:split
            " Open help in vertical split if window is not already split
            exe 'sil! vert help '.a:topic
        else
            exe 'sil! help '.a:topic
        endif
    else
        setl ft=help bt=help noma
        exe 'sil! help '.a:topic
    endif
    if v:errmsg != ""
        echohl ErrorMsg | redraw | echo v:errmsg | echohl None
    endif
endfunc
com! -nargs=? -complete=help Help call <SID>OpenHelp(<q-args>)
cnorea <expr> ht ((getcmdtype()==':'&&getcmdpos()<=3)?'tab help':'ht')
cnorea <expr> h ((getcmdtype()==':'&&getcmdpos()<=2)?'Help':'h')
cnorea <expr> H ((getcmdtype()==':'&&getcmdpos()<=2)?'Help':'H')
cnoremap <expr> <Up> ((getcmdtype()==':'&&getcmdline()=='h')?'<BS>H<Up>':'<Up>')
func! s:OpenHelpVisual()
    let g:oldreg=@"
    let l:cmd=":call setreg('\"',g:oldreg) | Help \<C-r>\"\<CR>"
    return g:inCmdwin? "y:quit\<CR>".l:cmd : 'y'.l:cmd
endfunc
nmap <silent> <expr> K g:inCmdwin? 'viwK' : ":exec 'Help '.expand('<cword>')<CR>"
vnoremap <expr> <silent> K <SID>OpenHelpVisual()

" {{{2 Cscope configuration

" Use quickfix list for cscope results
set cscopequickfix=s-,c-,d-,i-,t-,e-

" Use cscope instead of ctags when possible
set cscopetag

" Abbreviations for diff commands
cnorea <expr> dt ((getcmdtype()==':'&&getcmdpos()<=3)?'windo diffthis':'dt')
cnorea <expr> do ((getcmdtype()==':'&&getcmdpos()<=3)?'windo diffoff' :'do')
cnorea <expr> du ((getcmdtype()==':'&&getcmdpos()<=3)?'diffupdate'    :'du')

" Abbreviations for cscope commands
cnorea <expr> csa ((getcmdtype()==':'&&getcmdpos()<=4)?'cs add'  :'csa')
cnorea <expr> csf ((getcmdtype()==':'&&getcmdpos()<=4)?'cs find' :'csf')
cnorea <expr> csk ((getcmdtype()==':'&&getcmdpos()<=4)?'cs kill' :'csk')
cnorea <expr> csr ((getcmdtype()==':'&&getcmdpos()<=4)?'cs reset':'csr')
cnorea <expr> css ((getcmdtype()==':'&&getcmdpos()<=4)?'cs show' :'css')
cnorea <expr> csh ((getcmdtype()==':'&&getcmdpos()<=4)?'cs help' :'csh')

" Mappings for cscope find commands
no <C-\>s :cs find s <C-r>=expand("<cword>")<CR><CR>
no <C-\>g :cs find g <C-r>=expand("<cword>")<CR><CR>
no <C-\>c :cs find c <C-r>=expand("<cword>")<CR><CR>
no <C-\>t :cs find t <C-r>=expand("<cword>")<CR><CR>
no <C-\>e :cs find e <C-r>=expand("<cword>")<CR><CR>
no <C-\>f :cs find f <C-r>=expand("<cfile>")<CR><CR>
no <C-\>i :cs find i ^<C-r>=expand("<cfile>")<CR>$<CR>
no <C-\>d :cs find d <C-r>=expand("<cword>")<CR><CR>
vm <C-\> <Esc><C-\>

" }}}2

if has('gui_running')
    " Copy mouse modeless selection to clipboard
    set guioptions+=A

    " Don't use scrollbars
    set guioptions-=L
    set guioptions-=r

    " Hide menu/toolbars
    set guioptions-=m
    set guioptions-=T

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
        set guifont=Meslo\ LG\ S\ Regular\ for\ Powerline:h15

        " Start in fullscreen mode
        augroup VimrcAutocmds
            autocmd VimEnter * sil! set fullscreen
        augroup END
    else
        " Always show tabline (prevent resizing issues)
        set showtabline=2

        " Set font for gVim
        set guifont=DejaVu\ Sans\ Mono\ for\ Powerline\ 10.5

        " Don't use clipboard for visual selection
        set clipboard=
    endif
else
    " Make control + arrow keys work in terminal
    exec "set <F13>=\<Esc>[A <F14>=\<Esc>[B <C-Right>=\<Esc>[C <C-Left>=\<Esc>[D"
    map <F13> <C-Up>
    map <F14> <C-Down>
    map! <F13> <C-Up>
    map! <F14> <C-Down>

    augroup VimrcAutocmds
        " Use correct background color
        autocmd VimEnter * set t_ut=|redraw!
    augroup END
endif

" Function to set key codes for terminals
func! s:KeyCodes()
    " Shortcuts to change tab in MinTTY
    "         <C-Tab>           <C-S-Tab>
    exec "set <F15>=\<Esc>[1;5I <F16>=\<Esc>[1;6I"

    " Set key codes to work as meta key combinations
    let ns=range(65,90)+range(92,123)+range(125,126)
    for n in ns
        exec "set <M-".nr2char(n).">=\<Esc>".nr2char(n)
    endfor
    exec "set <M-\\|>=\<Esc>\\| <M-'>=\<Esc>'"
endfunc
nnoremap <silent> <Leader>k :call <SID>KeyCodes()<CR>

if hasSSH
    " Increase time allowed for multi-key mappings
    set timeoutlen=1000

    " Increase time allowed for keycode mappings
    if macSSH
        set ttimeoutlen=250
    else
        set ttimeoutlen=100
    endif
endif

augroup VimrcAutocmds
    " Don't auto comment new line made with 'o' or 'O'
    autocmd FileType * set formatoptions-=o

    " Use line wrapping for plain text files (but not help files)
    autocmd FileType text setl wrap linebreak
    autocmd FileType help setl nowrap nolinebreak

    " Highlight current line in active window
    autocmd BufRead,BufNewFile,VimEnter * set cul
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul

    " Disable paste mode after leaving insert mode
    autocmd InsertLeave * set nopaste

    " Open quickfix window automatically if not empty
    autocmd QuickFixCmdPost * cw

    " Always make quickfix full-width on the bottom
    autocmd FileType qf wincmd J

    " Use to check if inside command window
    au VimEnter,CmdwinLeave * let g:inCmdwin=0
    au CmdwinEnter          * let g:inCmdwin=1
augroup END

" Make <C-d>/<C-d> scroll 1/4 page
func! s:SetScroll(in)
    set scroll=0
    exec "set scroll=".&scroll/2
    return a:in
endfunc
noremap <expr> <C-d> <SID>SetScroll('<C-d>')
noremap <expr> <C-u> <SID>SetScroll('<C-u>')

" Delete hidden buffers
func! DeleteHiddenBuffers()
    let tpbl=[]
    call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
    for l:buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
        silent! execute 'bd' l:buf
    endfor
endfunc
nnoremap <silent> <Leader>dh :call DeleteHiddenBuffers()<CR>

" Remove last newline after copying visual selection to clipboard
func! RemoveClipboardNewline()
    if &updatetime==1
        let @+=substitute(@+,'\n$','','g')
        let @*=@+
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
augroup VimrcAutocmds
    au QuickFixCmdPost * call s:ToggleFoldOpen()
augroup END

" Function to redirect output of ex command to clipboard
func! Redir(cmd)
    redir @+
    execute a:cmd
    redir END
    let @+=substitute(@+,"\<CR>",'','g')
    let @*=@+
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

" Set color scheme
colorscheme desert

" {{{1 Plugin configuration

" Make empty list of disabled plugins
let g:pathogen_disabled=[]

" Disable some plugins if in read-only mode
if s:readonly
    call add(g:pathogen_disabled, 'nerdcommenter')
    call add(g:pathogen_disabled, 'syntastic')
    call add(g:pathogen_disabled, 'tabular')
endif

" Set airline color scheme
let g:airline_theme='badwolf'
let g:airline#extensions#ctrlp#color_template='normal'

" Use powerline font unless in Mac SSH session or in old Vim
if macSSH || v:version < 703
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

" Make B an alias for Bclose
command! -nargs=* -bang B Bclose<bang><args>

" Shortcut to force close buffer without closing window
nnoremap <silent> <Leader><Leader>bd :Bclose!<CR>

" Tagbar configuration
func! s:TagbarToggle()
    if !exists('s:tagbar_init')
        call TagbarInit()
    endif
    TagbarToggle
endfunc
nnoremap <silent> <Leader>t :call <SID>TagbarToggle()<CR>
let g:tagbar_iconchars=['▶','▼']
let g:tagbar_sort=0

" OmniCppComplete options
let OmniCpp_ShowPrototypeInAbbr=1
let OmniCpp_MayCompleteScope=1
augroup VimrcAutocmds
    au CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif
augroup END

" NERDCommenter configuration
let g:NERDCustomDelimiters={'arduino': { 'left': '//', 'leftAlt': '/*', 'rightAlt': '*/' } }
let g:NERDCreateDefaultMappings=0
map <Leader>cc       <Plug>NERDCommenterAlignLeft
map <Leader>cu       <Plug>NERDCommenterUncomment
map <Leader>c<Space> <Plug>NERDCommenterToggle

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

if !has('gui_running')
    " Disable CSApprox if color palette is too small
    if &t_Co < 88
        call add(g:pathogen_disabled, 'CSApprox')
    else
        " Use a snapshot if available or else make one
        if filereadable(expand('~/.CSApproxSnapshot'))
            call add(g:pathogen_disabled, 'CSApprox')
            source ~/.CSApproxSnapshot
            sil! AirlineTheme badwolf
        else
            augroup VimrcAutocmds
                autocmd VimEnter * sil! CSApproxSnapshot ~/.CSApproxSnapshot
                    \| sil! AirlineTheme badwolf
            augroup END
        endif
    endif
endif

" {{{2 Completion settings
if has('lua')
    call add(g:pathogen_disabled, 'supertab')

    " NeoComplete settings
    let g:neocomplete#enable_at_startup=1
    let g:neocomplete#enable_smart_case=1
    if !exists('g:neocomplete#same_filetypes')
        let g:neocomplete#same_filetypes={}
    endif
    let g:neocomplete#same_filetypes.arduino='c,cpp'
    let g:neocomplete#same_filetypes.c='arduino,cpp'
    let g:neocomplete#same_filetypes.cpp='arduino,c'
    if !exists('g:neocomplete#force_omni_input_patterns')
        let g:neocomplete#force_omni_input_patterns={}
    endif
    let g:neocomplete#force_omni_input_patterns.matlab='\h\w*\.\w*'
    func! s:StartManualComplete()
        " Indent if only whitespace behind cursor
        let l:match=match(getline('.'),'\S')
        if l:match >= 0 && l:match < col('.')
            return pumvisible() ? "\<C-n>" : neocomplete#start_manual_complete()
        else
            return "\<Tab>"
        endif
    endfunc
    inoremap <expr> <Tab>   <SID>StartManualComplete()
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <expr> <CR>    neocomplete#close_popup()."\<CR>"
    inoremap <expr> <C-d>   neocomplete#close_popup()
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
        autocmd InsertEnter * let g:neo_ignorecase_save=&ignorecase
        autocmd InsertLeave * let &ignorecase=g:neo_ignorecase_save
        autocmd VimEnter * sil! call neocomplete#init#enable()
        autocmd InsertLeave * if &ft=='vim' | sil! exe 'NeoCompleteVimMakeCache' | en
    augroup END
else
    call add(g:pathogen_disabled, 'neocomplete.vim')

    " Choose SuperTab completion type based on context
    let g:SuperTabDefaultCompletionType="context"
endif

" {{{2 CtrlP configuration
let g:ctrlp_cmd='CtrlPMRU'
let g:ctrlp_map='<M-p>'
let g:ctrlp_clear_cache_on_exit=0
let g:ctrlp_tabpage_position='al'
let g:ctrlp_show_hidden=1
let g:ctrlp_custom_ignore='\v[\/]\.(git|hg|svn)$'
let g:ctrlp_follow_symlinks=1
let g:ctrlp_by_filename=1
let g:ctrlp_working_path_mode='rw'
let g:ctrlp_regexp=1
let g:ctrlp_match_window='max:20'
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
    let l:line=getline('.')
    " Use substitute to remove status characters after filename
    let l:bufid=l:line =~ '\[\d\+\*No Name\]\( [#-=+.]*\)\?$' ? str2nr(matchstr(l:line, '\d\+'))
        \ : substitute(fnamemodify(l:line[2:], ':p'),'\m\(.*\) [#-=+.]*$','\1','')
    exec "bd" l:bufid
    exec "norm \<F5>"
endfunc

" {{{2 EasyMotion settings
map <S-Space> <Space>
map! <S-Space> <Space>
let g:EasyMotion_keys='ABCDEFGIMNOPQRSTUVWXYZLKJH'
let g:EasyMotion_use_upper=1
map <Space> <Plug>(easymotion-bd-f)
map <Space>/ <Plug>(easymotion-sn)
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
augroup VimrcAutocmds
    autocmd VimEnter * sil! unmap <Leader><Leader>
augroup END
" }}}2

" Undotree/Gundo settings
if has('python')
    call add(g:pathogen_disabled, 'undotree')
    nnoremap <silent> <Leader>u :GundoToggle<CR>
    let g:gundo_help=0
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

" Indent Guides settings
let g:indent_guides_auto_colors=0
nmap <silent> <Leader>i <Plug>IndentGuidesToggle
augroup VimrcAutocmds
    autocmd VimEnter,Colorscheme * hi link IndentGuidesOdd Normal
    autocmd VimEnter,Colorscheme * hi IndentGuidesEven ctermbg=237 guibg=#3d3d3d
augroup END

" Import scripts
execute pathogen#infect()

" Add current directory to status line
sil! let g:airline_section_b=airline#section#create(['%{ShortCWD()}'])

" Default whitespace symbol not available everywhere
if exists('g:airline_symbols')
    let g:airline_symbols.whitespace='!'
endif

" vim: fdm=marker fdl=1:
