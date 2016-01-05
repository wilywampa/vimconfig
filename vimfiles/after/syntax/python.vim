" numpy types
syntax keyword pythonBuiltinType complex128 complex256 complex64 float128
syntax keyword pythonBuiltinType float16 float32 float64 int16 int32 int64
syntax keyword pythonBuiltinType int8 uint16 uint32 uint64 uint8 void

if !get(g:, 'highlight_ipython_magics', 1)
  finish
endif

if stridx(&l:concealcursor, 'n') == -1
  setlocal concealcursor+=n
endif

" IPython magics (%name, %%name)
syntax region pythonMagic keepend
    \ start="^\s*\%(##\?\s\)\?%%\?\h\w*"
    \ start="^\s*'''[^']*'''\s*%%\?\h\w*"
    \ end=+\s['"`0-9]\@=\|%\h\w*\s\|$+ transparent oneline display

syntax region pythonMagicCell
    \ start="^\s*\%(##\?\s\)\?%%\h\w*"
    \ start="^\s*'''[^']*'''\s*%%\h\w*"
    \ end="^\s*$" transparent

syntax match  pythonMagicInit  "\%(^\s*\)\@<=##\?\%(\s\|$\)" conceal contained containedin=pythonMagic,pythonMagicCell nextgroup=pythonMagicPct skipwhite display
syntax match  pythonMagicInit  "^\s*'''[^']\{-}'''\s*" contained containedin=pythonMagic,pythonMagicCell display
syntax match  pythonMagicInit  "\%(^\s*\)\@<=##\?\%(\s\|$\)" conceal contained containedin=pythonMagicCell nextgroup=pythonMagicPct skipwhite display
syntax match  pythonMagicName  "%\@<=\h\w*" contained containedin=pythonMagic,pythonMagicCell display
syntax match  pythonMagicName  "\%(%%\)\@<=\h\w*" contained containedin=pythonMagicCell display
syntax match  pythonMagicPct   "%%\?\%(\h\w*\)\@=" contained containedin=pythonMagic display
syntax match  pythonMagicPct   "%%\%(\h\w*\)\@=" contained containedin=pythonMagicCell display
syntax match  pythonMagicQuote "\%(^\s*'''[^']\{-}'''\s*%.*\)\@<=`" display
syntax match  pythonMagicQuote "\%(^\s*\%(##\?\s\)\?%.*\)\@<=`" display

highlight def link pythonMagicBang  Special
highlight def link pythonMagicInit  Comment
highlight def link pythonMagicName  Type
highlight def link pythonMagicPct   Define
highlight def link pythonMagicQuote Special

" IPython shell magics (!, !!, %%!, %sx, %%sx, %system, %%system)
syntax region shellMagic keepend
    \ start="^\s*\%(##\?\s\)\?\%(\%(\h\w*\%(,\s*\|\s\+\)\)*=\s*\)\?\%(%%\?\%(!\|sx\>\|system\>\)\|!!\?\)"
    \ start="^\s*'''[^']*'''\s*\%(\%(\h\w*\%(,\s*\|\s\+\)\)*=\s*\)\?\%(%%\?\%(!\|sx\>\|system\>\)\|!!\?\)"
    \ end="$" oneline

syntax match  shellMagicInit "^\s*'''[^']*'''\s*" contained containedin=shellMagic display
syntax match  shellMagicInit "\%(^\s*\)\@<=##\?\%(\s\|$\)" conceal contained containedin=shellMagic nextgroup=shellMagicPct,shellMagicBang skipwhite display
syntax match  shellMagicEq   "=\s*\%(%\%(sx\|system\)\s\|!!\?\)\@=" contained containedin=shellMagic display
syntax match  shellMagicPct  "%%\?\s*" contained containedin=shellMagic nextgroup=shellMagicSx,shellMagicBang display
syntax match  shellMagicSx   "\%(sx\|system\)\>" contained containedin=shellMagic display
syntax match  shellMagicBang "!!\?" contained containedin=shellMagic nextgroup=shellMagicLine display

highlight def link shellMagicBang   Special
highlight def link shellMagicEq     Operator
highlight def link shellMagicInit   Comment
highlight def link shellMagicOpts   Normal
highlight def link shellMagicPct    Define
highlight def link shellMagicSx     Type

silent! unlet b:current_syntax
let g:sh_noisk = 1
syntax include @Sh syntax/sh.vim
let b:current_syntax = 'pymode'

syntax region shellMagicLine keepend
    \ start="\%(\%('''\|##\?\s\|^\).\{-}=\?\s*\%(%\%(sx\|system\)\s\|!!\?\)\)\@<=."
    \ end="$" contains=@Sh contained containedin=shellMagic oneline display

syntax region shellMagicCell keepend
    \ start="^\s*\%(##\?\s\)\?%%\%(\%(sx\|system\)\|!\)"
    \ end="^\s*$\|.*\%(\n\s*'''\)\@=" contains=@Sh,shellMagic
syntax match  shellMagicInit "\%(^\s*\)\@<=##\?\%(\s\|$\)" conceal contained containedin=shellMagicCell nextgroup=shellMagicPct skipwhite display
syntax match  shellMagicPct  "%%\%(\%(sx\|system\)\>\|!\)\@=" contained containedin=shellMagicCell nextgroup=shellMagicSx,shellMagicBang display
syntax match  shellMagicSx   "\%(sx\|system\)\>" contained containedin=shellMagicCell nextgroup=shellMagicOpts display
syntax match  shellMagicBang "!!\?" contained containedin=shellMagicCell nextgroup=shellMagicOpts display
syntax match  shellMagicOpts "\%(%%\%(\%(sx\|system\)\|!\)\%(\s.*\)\?\)\@<=.*$" contained containedin=shellMagicCell display

if &syntax !=# 'python'
  finish
endif

silent! unlet b:current_syntax
syntax include @Cython syntax/cython.vim
let b:current_syntax = 'pymode'

syntax region cythonMagic
    \ start="^\s*\%(##\?\s\)\?%%cython\%(\s\|$\)"
    \ end="^\s*$" contains=@Cython,pythonMagic
syntax match  pythonMagicInit "\%(^\s*\)\@<=##\?\%(\s\|$\)" conceal contained containedin=cythonMagic nextgroup=cythonMagicPct skipwhite display
syntax match  pythonMagicPct  "%%\%(cython\)\@=" contained containedin=cythonMagic display
syntax match  pythonMagicName "\%(%%\)\@<=cython" contained containedin=cythonMagic display

" vim: set sw=2:
