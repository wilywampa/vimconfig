" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('CommentToolsLoaded')
    finish
endif

let CommentToolsLoaded=1

if !exists('g:findInComments')
    let g:findInComments=1
endif

" Replace C-style comments with asterisks (excepts newlines and spaces)
func! StripComments()
    let s:curPos=getpos('.')
    if v:version >= 704
        silent! %s/\(\/\*\)\(\_.\{-}\)\(\*\/\)/\=submatch(1)
            \ .substitute(submatch(2),'[^ \n]','*','g')
            \ .submatch(3)/g
    else
        silent! %s/\(\/\*\)\(\_.\{-}\)\(\*\/\)/\=submatch(1).
            \ substitute(substitute(substitute(submatch(2),' ',
            \ nr2char(1),'g'),'\p','*','g'),nr2char(1),' ','g')
            \ .submatch(3)/g
    endif
    silent! %s/\(\/\/\)\(.*\)$/\=submatch(1)
        \ .substitute(submatch(2),'[^ \n]','*','g')/g
    call histdel('/','[-1,-2]')
    call setpos('.',s:curPos)
endfunc

com! StripComments call StripComments()

func! FindNotInComment(dir)
    if v:version >= 704
        let s:undo_file = tempname()
        execute "wundo" s:undo_file
    endif
    let s:search=histget('/')
    let s:change=changenr()
    call StripComments()
    let @/=s:search
    if a:dir
        normal! n
    else
        normal! N
    endif
    let s:curPos=getpos('.')
    if s:change!=changenr()
        normal! u
    endif
    call setpos('.',s:curPos)
    if v:version >= 704 && filereadable(s:undo_file)
        silent execute "rundo" s:undo_file
        unlet s:undo_file
    endif
endfunc

func! ToggleFindInComments()
    if g:findInComments
        nnoremap <silent> n :call FindNotInComment(1)<CR>
        nnoremap <silent> N :call FindNotInComment(0)<CR>
        let g:findInComments=0
        echo "Searching text not in C-style comments"
    else
        silent! unmap n
        silent! unmap N
        let g:findInComments=1
        echo "Searching everywhere"
    endif
endfunc

com! ToggleFindInComments call ToggleFindInComments()

