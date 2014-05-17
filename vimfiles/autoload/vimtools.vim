" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#SynNames(...) abort
    if a:0
        let [line, col] = [a:1, a:2]
    else
        let [line, col] = [line('.'), col('.')]
    endif
    return reverse(map(synstack(line, col), 'synIDattr(v:val,"name")'))
endfunction

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#HelpTopic()
    if &syntax != 'vim'
        return expand('<cword>')
    endif
    let col = col('.') - 1
    while col && getline('.')[col] =~# '\k'
        let col -= 1
    endwhile
    let pre = col == 0 ? '' : getline('.')[0 : col]
    let col = col('.') - 1
    while col && getline('.')[col] =~# '\k'
        let col += 1
    endwhile
    let post = getline('.')[col : -1]
    let syn = get(vimtools#SynNames(), 0, '')
    let cword = expand('<cword>')
    if syn ==# 'vimFuncName'
        return cword.'()'
    elseif syn ==# 'vimOption'
        return "'".cword."'"
    elseif syn ==# 'vimUserAttrbKey'
        return ':command-'.cword
    elseif pre =~# '^\s*:\=$'
        return ':'.cword
    elseif pre =~# '\<v:$'
        return 'v:'.cword
    elseif cword ==# 'v' && post =~# ':\w\+'
        return 'v'.matchstr(post, ':\w\+')
    else
        return cword
    endif
endfunction

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#EchoSyntax(count)
    if a:count
        let name = get(vimtools#SynNames(), a:count-1, '')
        if name !=# ''
            return 'syntax list '.name
        endif
    else
        echo join(vimtools#SynNames(), ' ')
    endif
    return ''
endfunction

function! vimtools#OpenHelp(topic)
    let v:errmsg=""
    " Open in same window if current tab is empty, or else open in new window
    if vimtools#TabUsed()
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
            let splitbelow_save = &splitbelow
            set nosplitbelow
            try
                set nosplitbelow
                exe 'sil! help '.a:topic
            finally
                let &splitbelow = splitbelow_save
            endtry
        endif
    else
        setl ft=help bt=help noma
        exe 'sil! help '.a:topic
    endif
    if v:errmsg != ""
        echohl ErrorMsg | redraw | echo v:errmsg | echohl None
    endif
endfunction

function! vimtools#OpenHelpVisual()
    let g:oldreg=@"
    let l:cmd=":call setreg('\"',g:oldreg) | Help \<C-r>\"\<CR>"
    return g:inCmdwin? "y:quit\<CR>".l:cmd : 'y'.l:cmd
endfunction

function! vimtools#TabUsed()
    return strlen(expand('%')) || line('$')!=1 || getline(1)!='' || winnr('$')>1
endfunction

function! vimtools#SwitchToOrOpen(fname)
    let l:bufnr=bufnr(expand(a:fname).'$')
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
    if vimtools#TabUsed()
        exec 'tabedit '.a:fname
    else
        exec 'edit '.a:fname
    endif
endfunction

nnoremap <silent> <Leader>y :<C-U>exe vimtools#EchoSyntax(v:count)<CR>
