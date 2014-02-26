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
func! s:StripComments()
    " Save window, cursor, etc. positions
    let s:winSave=winsaveview()

    if v:version >= 703
        keepj silent! %s/\m\(\/\*\)\(\_.\{-}\)\(\*\/\)/\=submatch(1)
            \ .substitute(submatch(2),'[^ \n]','*','g')
            \ .submatch(3)/g
    else
        keepj silent! %s/\m\(\/\*\)\(\_.\{-}\)\(\*\/\)/\=submatch(1).
            \ substitute(substitute(substitute(submatch(2),' ',
            \ nr2char(1),'g'),'\p','*','g'),nr2char(1),' ','g')
            \ .submatch(3)/g
    endif

    keepj silent! %s/\m\(\/\/\)\(.*\)$/\=submatch(1)
        \ .substitute(submatch(2),'[^ \n]','*','g')/g

    " Restore window, cursor, etc. positions
    call winrestview(s:winSave)
endfunc

com! StripComments call <SID>StripComments()

" Use StripComments functions to search in non-commented text only
func! s:FindNotInComment(direction)
    if v:version >= 703
        let s:undo_file = tempname()
        execute "wundo" s:undo_file
    endif

    " Save last search and last change for later use
    let s:search=@/
    let s:change=changenr()

    call s:StripComments()
    let @/=s:search

    " Jump to next or previous match depending on search direction and n/N
    let v:errmsg=""
    if (a:direction && g:sfsave) || (!a:direction && !g:sfsave)
        silent! normal! /
    else
        silent! normal! ?
    endif
    let s:errmsg=v:errmsg

    " Undo changes caused by StripComments
    let s:winSave=winsaveview()
    if s:change!=changenr()
        keepj normal! u
    endif
    call winrestview(s:winSave)

    if v:version >= 703 && filereadable(s:undo_file)
        silent execute "rundo" s:undo_file
        unlet s:undo_file
    endif

    if s:errmsg != ""
        echohl ErrorMsg
        redraw
        echo s:errmsg
        echohl None
    endif
endfunc

func! s:UnmapCR()
    silent! cunmap <CR>
    silent! cunmap <Esc>
    silent! cunmap <C-c>
endfunc

func! s:MapCR()
    cnoremap <silent> <CR> <CR>``:call <SID>FindNotInComment(1)<CR>:call <SID>MapN()<CR>:call <SID>UnmapCR()<CR>
    cnoremap <silent> <Esc> <Esc>:call <SID>UnmapCR()<CR>
    cnoremap <silent> <C-c> <C-c>:call <SID>UnmapCR()<CR>
endfunc

func! s:MapN()
    nnoremap <silent> n :call <SID>FindNotInComment(1)<CR>
    nnoremap <silent> N :call <SID>FindNotInComment(0)<CR>
endfunc

func! s:ToggleFindInComments()
    if g:findInComments
        let g:sfsave=v:searchforward
        call s:MapN()
        nnoremap <silent> / m`:call <SID>MapCR()<CR>:let g:sfsave=1<CR>/
        nnoremap <silent> ? m`:call <SID>MapCR()<CR>:let g:sfsave=0<CR>?
        nnoremap <silent> * m`:let @/='\<'.expand('<cword>').'\>'<CR>:let g:sfsave=1<CR>:call
            \<SID>FindNotInComment(1)<CR>:set hlsearch<CR>
        nnoremap <silent> # m`:let @/='\<'.expand('<cword>').'\>'<CR>:let g:sfsave=0<CR>:call
            \<SID>FindNotInComment(1)<CR>:set hlsearch<CR>
        let g:findInComments=0
        redraw
        echo "Searching text not in C-style comments"
    else
        silent! unmap n
        silent! unmap N
        silent! unmap /
        silent! unmap ?
        silent! unmap *
        silent! unmap #
        call s:UnmapCR()

        " Handle case where previous search was backwards
        if g:sfsave==0
            nnoremap <silent> n ?:unmap n<CR>:unmap N<CR>
            nnoremap <silent> N ?NN:unmap n<CR>:unmap N<CR>
        endif
        let g:findInComments=1
        redraw
        echo "Searching everywhere"
    endif
endfunc

com! ToggleFindInComments call <SID>ToggleFindInComments()

nnoremap ,c :ToggleFindInComments<CR>

