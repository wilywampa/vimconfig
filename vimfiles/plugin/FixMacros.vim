" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('FixMacrosLoaded')
    finish
endif

let FixMacrosLoaded=1

" Problem was fixed in patch 7.4.374
if v:version > 704 || has('patch-7.4.374')
    finish
endif

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
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\Cã','\\\\c','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\CÃ','\\\\C','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\Cä','\\\\d','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\CÄ','\\\\D','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\Có','\\\\s','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\CÓ','\\\\S','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\Cø','\\\\x','g'))
        call setreg(nr2char(l:reg), substitute(getreg(nr2char(l:reg)),'\CØ','\\\\X','g'))
    endfor

    return '@'
endfunction
