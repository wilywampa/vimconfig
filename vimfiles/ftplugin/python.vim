" Vim ftplugin file
" Language: Python
" Author: Jacob Niehus

if exists("b:did_ftplugin")
    finish
endif

let b:did_ftplugin = 1

func! s:RunPython()
    if !has('gui_running') && !empty($TMUX)
        call VimuxRunCommand('python '.expand('%:p'))
    else
        !python %
    endif
endfunc

noremap <silent> <buffer> <F5> :up<CR>:<C-u>call <SID>RunPython()<CR>
imap <silent> <buffer> <F5> <Esc><F5>
nnoremap <silent> <buffer> K :<C-u>execute "!pydoc " . expand("<cword>")<CR>
nnoremap <silent> <buffer> <S-F5> :up<CR>:exe "SyntasticCheck" \| exe "Errors"<CR>
imap <silent> <buffer> <S-F5> <Esc><S-F5>
