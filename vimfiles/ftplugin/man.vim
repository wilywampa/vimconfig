" Vim ftplugin file
" Language: Man page
" Author: Jacob Niehus

function! s:ManSectionJump(b, count)
    let cnt = a:count
    normal! 0
    while cnt
        call search('^\a', 'W' . (a:b ? 'b' : ''))
        let cnt -= 1
    endwhile
endfunction

function! s:ManFlagJump()
    let flag = substitute(expand('<cWORD>'), '^.*\ze-', '', '')
    normal! gg
    call search('\C^\s*'.flag)
    normal! ^zz
endfunction

nnoremap <silent> <buffer> <CR> :call <SID>ManFlagJump()<CR>
nnoremap <silent> <buffer> ]] :<C-u>call <SID>ManSectionJump(0, v:count1)<CR>
nnoremap <silent> <buffer> [[ :<C-u>call <SID>ManSectionJump(1, v:count1)<CR>

function! s:ManFold(lnum)
    if getline(a:lnum) =~ '^\u\+'
        return '>1'
    elseif getline(a:lnum + 1) =~ '^\u\+'
        return 0
    else
        return 1
    endif
endfunction
setlocal foldmethod=expr foldexpr=s:ManFold(v:lnum) foldlevel=1
nnoremap G G

" Set tmux window title to title of man page
function! s:SetTmuxTitle()
    if !empty($TMUX)
        let panes = system("tmux display-message -p -t $TMUX_PANE '#{window_panes}'")
        let linenr = nextnonblank(1)
        let page = tolower(matchstr(getline(linenr), '^\s*\zs\S\+\ze(\d\+\u*)'))
        if panes == 1 && empty($NOAUTONAME) && !empty(page)
            call system("tmux rename-window -t $TMUX_PANE 'man ".page."'")
            autocmd VimLeave * call system('tmux setw -q -t automatic-rename on')
        endif
    endif
endfunction
call s:SetTmuxTitle()

augroup man_tmux_title
    autocmd!
    autocmd BufEnter * if &filetype == 'man' | call SetTmuxTitle() | endif
augroup END
