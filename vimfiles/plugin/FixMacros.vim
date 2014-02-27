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
    let regnum =  range(char2nr('a'), char2nr('z'))
    let regnum += range(char2nr('0'), char2nr('9'))
    let regstr =  ['"']
    let regnum += map(regstr, 'char2nr(v:val)')

    " Remove the registers that are empty
    let regnum = filter( regnum, 'getreg(nr2char(v:val)) != ""' )
    let regnum = filter( regnum, 'getreg(nr2char(v:val)) !~ "^$"' )

    " Remove the registers that are just spaces
    let regnum = filter( regnum, 'getreg(nr2char(v:val)) !~ "^\s\+$"' )

    " Remove the registers that have no alpha-num
    let regnum = filter( regnum, 'getreg(nr2char(v:val)) !~ "^\W\+$"' )

    for reg in regnum
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'ã','\\\\c','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'Ã','\\\\C','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'ä','\\\\d','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'Ä','\\\\D','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'ó','\\\\s','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'Ó','\\\\S','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'ø','\\\\x','g'))
        call setreg(nr2char(reg), substitute(getreg(nr2char(reg)),'Ø','\\\\X','g'))
    endfor

    return '@'
endfunction
