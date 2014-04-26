" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('ShortCWDloaded')
    finish
endif

let ShortCWDloaded=1

let s:hasWin = has("win16") || has("win32") || has("win64")
let s:cwdPrev=''
let s:bufNamePrev=''
let s:winWidthPrev=-1
let s:tagPrev=''
let s:bufModPrev=0

function! ShortCWD()
    if (getcwd() == s:cwdPrev) && (@% == s:bufNamePrev) && (winwidth(0) == s:winWidthPrev) && (&mod == s:bufModPrev)
        if g:airline_section_x =~? 'tagbar'
            if (tagbar#currenttag('%s','','') == s:tagPrev)
                return s:cwd
            endif
        else
            return s:cwd
        endif
    endif

    if s:hasWin && !&shellslash
        let pathSep='\'
    else
        let pathSep='/'
    endif

    let s:cwdPrev=getcwd()
    let s:bufNamePrev=@%
    let s:winWidthPrev=winwidth(0)
    let s:bufModPrev=&modified
    let s:cwd=fnamemodify(s:cwdPrev,':~')
    if g:airline_section_x =~? 'tagbar'
        let s:tagPrev=tagbar#currenttag('%s','','')
    endif

    let s:cwdMaxLen=winwidth(0)-strlen(expand('%:~:.'))-strlen(&filetype)
        \-strlen(s:tagPrev)-3*&mod-&ro-(strlen(s:tagPrev)?3:0)-50

    if strlen(s:cwd) > s:cwdMaxLen
        let parts=split(s:cwd,pathSep)
        if s:hasWin
            let partNum=1
        else
            let partNum=0
        endif
        while (strlen(s:cwd) >= s:cwdMaxLen) && (partNum < len(parts)-1)
            let parts[partNum]=parts[partNum][0]
            let s:cwd=join(parts,pathSep)
            if !s:hasWin && parts[0] != '~' | let s:cwd='/'.s:cwd | endif
            let partNum=partNum+1
        endwhile
    endif

    if strlen(s:cwd) > s:cwdMaxLen
        let s:cwd=''
    endif

    return s:cwd
endfunction
