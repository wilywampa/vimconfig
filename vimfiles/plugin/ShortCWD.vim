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

let s:cwdPrev=''
let s:bufNamePrev=''
let s:winWidthPrev=-1
let s:tagPrev=''
let s:bufModPrev=0

function! ShortCWD()
    if (getcwd() ==# s:cwdPrev) && (@% == s:bufNamePrev) && (winwidth(0) == s:winWidthPrev) && (&mod == s:bufModPrev)
        if exists(':TagbarToggle')
            if (tagbar#currenttag('%s','','') ==# s:tagPrev)
                return s:cwd
            endif
        else
            return s:cwd
        endif
    endif

    let s:cwdPrev=getcwd()
    let s:bufNamePrev=@%
    let s:winWidthPrev=winwidth(0)
    let s:bufModPrev=&modified
    let s:cwd=substitute(s:cwdPrev,substitute(expand('~'),s:pathSep,'\\'.s:pathSep,'g'),'~','')
    if exists(':TagbarToggle')
        let s:tagPrev=tagbar#currenttag('%s','','')
    endif

    if strlen(s:tagPrev)
        let s:cwdMaxLen=winwidth(0)-strlen(expand('%:~:.'))-strlen(&filetype)-strlen(s:tagPrev)-3*&mod-&ro-53
    else
        let s:cwdMaxLen=winwidth(0)-strlen(expand('%:~:.'))-strlen(&filetype)-strlen(s:tagPrev)-3*&mod-&ro-50
    endif

    if strlen(s:cwd) > s:cwdMaxLen
        let s:shortCWDprev=''
        while (strlen(s:cwd) >= s:cwdMaxLen) && !(s:cwd ==# s:shortCWDprev)
            let s:shortCWDprev=s:cwd
            let s:cwd=substitute(s:cwd,'\('.s:pathSep.'\)\('.s:charSet.'\)\('.s:charSet.'\+\)\ze\.*'.s:pathSep.'\@=','\1\2','')
        endwhile
    endif

    if strlen(s:cwd) > s:cwdMaxLen
        let s:cwd=''
    endif

    return s:cwd
endfunction
