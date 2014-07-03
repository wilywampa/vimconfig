" Vim ftplugin file
" Language: Man page
" Author: Jacob Niehus

if exists("b:did_my_ftplugin")
    finish
endif

let b:did_my_ftplugin = 1

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
