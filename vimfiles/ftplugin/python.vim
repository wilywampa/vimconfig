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

setlocal define=^\s*\\(def\\\\|class\\)

noremap  <silent> <buffer> <F5> :up<CR>:<C-u>call <SID>RunPython()<CR>
imap     <silent> <buffer> <F5> <Esc><F5>
nnoremap <silent> <buffer> K :<C-u>execute "!pydoc " . expand("<cword>")<CR>
nnoremap <silent> <buffer> <S-F5> :up<CR>:exe "SyntasticCheck" \| exe "Errors"<CR>
imap     <silent> <buffer> <S-F5> <Esc><S-F5>

" Move around functions
nnoremap <silent> <buffer> [[ m':call search('^\s*def ', "bW")<CR>
vnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "bW")<CR>
nnoremap <silent> <buffer> ]] m':call search('^\s*def ', "W")<CR>
vnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "W")<CR>

" Enable omni completion
setlocal omnifunc=pythoncomplete#Complete
