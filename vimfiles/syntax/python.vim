if get(b:, 'did_magic_highlighting', 0)
  finish
endif
let b:did_magic_highlighting = 1
let b:undo_ftplugin = (exists('b:undo_ftplugin') ?
    \ (b:undo_ftplugin . ' | ') : '') .
    \ 'silent! unlet b:did_magic_highlighting'

" Load pymode syntax
runtime! syntax/python.vim

" Highlight IPython magic syntax
syntax region pythonMagic
    \ start="^\s*\zs\(#\s\)\?\s*[!%].\+"
    \ start="^\s*'''[^']\{-}'''\s*[!%].\+"
    \ start="^\(\s*#\s\+\)\?\(\h\w*,\?\s*\)\+\s*=\s*\(%sx\|!.\+\)"
    \ start="^\s*'''[^']\{-}'''\s*\(\h\w*,\?\s*\)\+\s*=\s*\(%sx\|!.\+\)"
    \ skip="\s*\(\h\w*,\?\s*\)\+\s*=\s*[!%]\+" end=+\s['"0-9]\@=\|%\h\w*\s\|$+ display

syntax match  pythonMagicInit   "^\s*'''[^']\{-}'''\s*\(#\s\)\?\s*" contained containedin=pythonMagic nextgroup=pythonMagicAssign display
syntax match  pythonMagicInit   "#\s" conceal contained containedin=pythonMagic nextgroup=pythonMagicAssign display
syntax match  pythonMagicAssign "\(\h\w*,\?\s*\)\+\s*=\s*" containedin=pythonMagic display
syntax match  pythonMagicPct    "\s*%%\?\s*" nextgroup=pythonMagicBang contained containedin=pythonMagic display
syntax match  pythonMagicBang   "\s*!" contained containedin=pythonMagic nextgroup=pythonMagicName display
syntax match  pythonMagicName   "%\@<=\h\w*" containedin=pythonMagic display
syntax match  pythonMagicCmd    "!\@<=\h\w*" containedin=pythonMagic display
syntax match  pythonMagicQuote  "\(^\s*#\s\s*[!%].*\)\@<=`" display
highlight def link pythonMagic      Normal
highlight def link pythonMagicInit  Comment
highlight def link pythonMagicName  Type
highlight def link pythonMagicCmd   Function
highlight def link pythonMagicQuote Special
highlight def link pythonMagicBang  Special
highlight def link pythonMagicPct   Define

if &syntax ==# 'python'
  for lang in ['Cython', 'Sh']
    silent! unlet s:current
    if exists('b:current_syntax')
      let s:current = b:current_syntax
      unlet b:current_syntax
    endif
    execute 'syntax include @' . lang . ' syntax/' . tolower(lang) . '.vim'
    if exists('s:current')
      let b:current_syntax = s:current
    endif
  endfor
  syntax region cythonMagic start="\(#\s\+%%cython\(\s.*\)\?\n\)\@<=.*$" end="^\s*$" contains=@Cython,pythonMagic
  syntax region shellMagic start="\(#\s\+%%\(sx\|!\)\(\s.*\)\?\n\)\@<=.*$" end="^\s*$" contains=@Sh,pythonMagic
endif
