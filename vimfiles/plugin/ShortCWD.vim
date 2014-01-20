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

let s:cwdMaxLen=40
let s:cwdPrev=''
let s:bufNamePrev=''
let s:winWidthPrev=-1
let s:tagPrev=''

function! ShortCWD()
    if (getcwd() ==# s:cwdPrev)
  \ && (@% == s:bufNamePrev)
  \ && (winwidth(0) == s:winWidthPrev)
  \ && (tagbar#currenttag('%s','','') ==# s:tagPrev)
        return s:cwd
    endif

    let s:cwdPrev=getcwd()
    let s:bufNamePrev=@%
    let s:winWidthPrev=winwidth(0)
    let s:cwd=substitute(s:cwdPrev,substitute(expand('~'),s:pathSep,'\\'.s:pathSep,'g'),'~','')
    let s:tagPrev=tagbar#currenttag('%s','','')

    let s:cwdMaxLen=winwidth(0)-strlen(expand('%:~:.'))-strlen(&filetype)-strlen(s:tagPrev)-50

    if strlen(s:cwd) > s:cwdMaxLen
        let s:cwdPrev=''
        while (strlen(s:cwd) >= s:cwdMaxLen) && !(s:cwd ==# s:cwdPrev)
            let s:cwdPrev=s:cwd
            let s:cwd=substitute(s:cwd,'\('.s:pathSep.'\)\('.s:charSet.'\)\('.s:charSet.'\+\)\ze\.*'.s:pathSep.'\@=','\1\2','')
        endwhile
    endif

    return s:cwd
endfunction
