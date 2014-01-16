" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('ShortCWDloaded')
    finish
endif

let ShortCWDloaded=1

if has("win16") || has("win32") || has("win64")
    let s:pathSep='\\'
    let s:charSet='[^\\]'
else
    let s:pathSep='\/'
    let s:charSet='[^\/]'
endif

if !exists('g:cwdMaxLen')
    let g:cwdMaxLen=40
endif

function! ShortCWD()
    let s:cwd=fnamemodify(getcwd(),':~')

    let g:cwdMaxLen=winwidth(0)-strlen(expand('%:.:~'))-strlen(&filetype)-50
    if strlen(s:cwd) > g:cwdMaxLen
        let s:cwdPrev=''
        while (strlen(s:cwd) >= g:cwdMaxLen) && !(s:cwd ==# s:cwdPrev)
            let s:cwdPrev=s:cwd
            let s:cwd=substitute(s:cwd,'\('.s:pathSep.'\)\('.s:charSet.'\)\('.s:charSet.'\+\)\ze\.*'.s:pathSep.'\@=','\1\2','')
        endwhile
    endif

    return s:cwd
endfunction
