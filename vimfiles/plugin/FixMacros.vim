" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('FixMacrosLoaded')
    finish
endif

let FixMacrosLoaded=1

nnoremap <expr> @ <SID>FixMacros()

function! s:FixMacros()
    " Create the list of register 'indexes' where the the elements are in char2nr form
    let l:regnum =  range(char2nr('a'), char2nr('z'))
    let l:regnum += range(char2nr('0'), char2nr('9'))
    let l:regstr =  ['"']
    let l:regnum += map(l:regstr, 'char2nr(v:val)')

    " Remove the registers that are empty
    let l:regnum = filter( l:regnum, 'getreg(nr2char(v:val)) != ""' )
    let l:regnum = filter( l:regnum, 'getreg(nr2char(v:val)) !~ "^$"' )

    " Remove the registers that are just spaces
    let l:regnum = filter( l:regnum, 'getreg(nr2char(v:val)) !~ "^\s\+$"' )

    " Remove the registers that have no alpha-num
    let l:regnum = filter( l:regnum, 'getreg(nr2char(v:val)) !~ "^\W\+$"' )

    for l:reg in l:regnum
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'ã','\\\\c','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'Ã','\\\\C','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'ä','\\\\d','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'Ä','\\\\D','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'ó','\\\\s','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'Ó','\\\\S','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'ø','\\\\x','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'Ø','\\\\X','g'))
    endfor

    return '@'
endfunction
