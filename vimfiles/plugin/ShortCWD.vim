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
let s:wsPrev=''
let s:wsEnabledPrev=0

function! s:TagbarSame()
    try
        return g:airline_section_x =~? 'tagbar'
            \ && (tagbar#currenttag('%s','','') == s:tagPrev)
    catch
        return 0
    endtry
endfunction

function! s:WhitespaceSame()
    return (airline#extensions#whitespace#get_enabled()
        \ && !exists('b:airline_whitespace_check')) ||
        \ (exists('b:airline_whitespace_check')
        \ && b:airline_whitespace_check == s:wsPrev
        \ && airline#extensions#whitespace#get_enabled() == s:wsEnabledPrev)
endfunction

function! ShortCWD()
    if (getcwd() == s:cwdPrev) && (@% == s:bufNamePrev)
        \ && (winwidth(0) == s:winWidthPrev) && (&mod == s:bufModPrev)
        \ && <SID>TagbarSame() && <SID>WhitespaceSame()
        return s:cwd
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
    if exists('*airline#extensions#whitespace#get_enabled')
        let s:wsEnabledPrev=airline#extensions#whitespace#get_enabled()
    endif
    if g:airline_section_x =~? 'tagbar'
        let s:tagPrev=tagbar#currenttag('%s','','')
    endif
    if exists('b:airline_whitespace_check')
        \ && s:wsEnabledPrev
        let s:wsPrev=b:airline_whitespace_check
    else
        let s:wsPrev=''
    endif

    let git = 0
    if g:airline_powerline_fonts == 1 && exists('*fugitive#head')
        \ && len(fugitive#head())
        let git = 1
    endif

    if &buftype == 'help'
        let s:cwdMaxLen=winwidth(0)-strlen(expand('%:t'))-40+(git?2:0)
    else
        let s:cwdMaxLen=winwidth(0)-strlen(expand('%:~:.'))-strlen(&filetype)
            \-strlen(s:tagPrev)-3*&mod-&ro-(strlen(s:tagPrev)?3:0)-43
            \-strlen(s:wsPrev)-(strlen(s:wsPrev)?3:0)+(git?2:0)
    endif

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
        if strlen(s:cwd) > s:cwdMaxLen && exists('parts[-1]')
            let s:cwd=parts[-1]
        endif
    endif
    if s:cwd=='~/' | let s:cwd='~' | endif

    if git | let s:cwd = nr2char(57504).' '.s:cwd | endif

    if strlen(s:cwd) > s:cwdMaxLen
        let s:cwd=''
    endif

    return s:cwd
endfunction
