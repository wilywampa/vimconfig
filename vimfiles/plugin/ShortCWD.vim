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

if !exists('s:cwdMaxLen')
    let s:cwdMaxLen=40
endif

if !exists('s:cwdPrev')
    let s:cwdPrev=''
endif

if !exists('s:bufnrPrev')
    let s:bufnrPrev=-1
endif

function! s:ShortCWDupdateMaxLen()
    let s:cwdMaxLen=winwidth(0)-strlen(expand('%:.:~'))-strlen(&filetype)-50
endfunction

function! ShortCWD()
    if (getcwd() ==# s:cwdPrev) && (winbufnr(0) == s:bufnrPrev)
        return s:cwd
    endif

    let s:cwdPrev=getcwd()
    let s:bufnrPrev=winbufnr(0)
    let s:cwd=substitute(s:cwdPrev,substitute(expand('~'),s:pathSep,'\\'.s:pathSep,'g'),'~','')

    if strlen(s:cwd) > s:cwdMaxLen
        let s:cwdPrev=''
        while (strlen(s:cwd) >= s:cwdMaxLen) && !(s:cwd ==# s:cwdPrev)
            let s:cwdPrev=s:cwd
            let s:cwd=substitute(s:cwd,'\('.s:pathSep.'\)\('.s:charSet.'\)\('.s:charSet.'\+\)\ze\.*'.s:pathSep.'\@=','\1\2','')
        endwhile
    endif

    return s:cwd
endfunction

autocmd BufEnter,VimResized * call s:ShortCWDupdateMaxLen()
