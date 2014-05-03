" Vim indent file
" Language:	    C
" Maintainer:	Jacob Niehus
" Last Change:	2 May 2014

if exists("b:did_indent") && exists("b:did_my_indent")
    finish
endif
let b:did_indent = 1
let b:did_my_indent = 1

func! MyCIndent()
    if matchstr(getline(v:lnum),'\S') == '|'
        let l:prevBlockStart = search('\m\/\*','bncW')
        if l:prevBlockStart && v:lnum > l:prevBlockStart
            let l:prevBlockEnd = search('\m\*\/','bnW')
            if l:prevBlockEnd < l:prevBlockStart
                return cindent(l:prevBlockStart)
            endif
        endif
    endif
    return cindent(v:lnum)
endfunc

setlocal indentexpr=MyCIndent()

let b:undo_indent = "setl cin<"
