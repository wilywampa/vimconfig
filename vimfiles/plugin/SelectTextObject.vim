" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('SelectTextObjectLoaded')
  finish
endif

let SelectTextObjectLoaded=1

func! s:SelectTextObject(obj,motion)
  if a:obj ==# 'b'
    let left = '('
    let right = ')'
  elseif a:obj ==# 'B'
    let left = '{'
    let right = '}'
  elseif a:obj == '['
    let left = '['
    let right = ']'
  elseif a:obj == '<'
    let left = '<'
    let right = '>'
  endif

  let curpos = getpos('.')

  while !<SID>CursorInPair(left,right)
    if getline('.')[col('.'):-1] =~ escape(left,'[]').'.*'.escape(right,'[]')
      execute "normal! f".left
    elseif getline('.')[0:col('.')-2] =~ escape(left,'[]').'.*'.escape(right,'[]')
      execute "normal! F".right
    else
      call setpos('.',curpos)
      execute "normal! v\<Esc>"
      return
    endif
  endwhile

  if a:motion == 'i'
    let curchar = getline('.')[col('.')-1]
    if curchar == right && getline('.')[col('.')-2] == left
      execute "normal! i\<Space>\<Esc>"
    elseif curchar == left && getline('.')[col('.')] == right
      execute "normal! a\<Space>\<Esc>"
    elseif curchar != left
      execute "normal! F".left
    endif
  endif

  execute "normal! v".a:motion.a:obj
endfunc

func! s:CursorInPair(left,right)
  let curpos = getpos('.')
  execute "normal! v\<Esc>va".a:right."\<Esc>"
  call setpos('.',curpos)

  " Left or right char must be on cursor line
  if getpos("'<")[1] == line('.') || getpos("'>")[1] == line('.')
    return getpos("'<") != getpos("'>")
  else
    return 0
  endif
endfunc

onoremap <silent> ib :<C-u>call <SID>SelectTextObject('b','i')<CR>
onoremap <silent> i( :<C-u>call <SID>SelectTextObject('b','i')<CR>
onoremap <silent> i) :<C-u>call <SID>SelectTextObject('b','i')<CR>
onoremap <silent> ab :<C-u>call <SID>SelectTextObject('b','a')<CR>
onoremap <silent> a( :<C-u>call <SID>SelectTextObject('b','a')<CR>
onoremap <silent> a) :<C-u>call <SID>SelectTextObject('b','a')<CR>

xnoremap <silent> ib :<C-u>call <SID>SelectTextObject('b','i')<CR>
xnoremap <silent> i( :<C-u>call <SID>SelectTextObject('b','i')<CR>
xnoremap <silent> i) :<C-u>call <SID>SelectTextObject('b','i')<CR>
xnoremap <silent> ab :<C-u>call <SID>SelectTextObject('b','a')<CR>
xnoremap <silent> a( :<C-u>call <SID>SelectTextObject('b','a')<CR>
xnoremap <silent> a) :<C-u>call <SID>SelectTextObject('b','a')<CR>

onoremap <silent> iB :<C-u>call <SID>SelectTextObject('B','i')<CR>
onoremap <silent> i{ :<C-u>call <SID>SelectTextObject('B','i')<CR>
onoremap <silent> i} :<C-u>call <SID>SelectTextObject('B','i')<CR>
onoremap <silent> aB :<C-u>call <SID>SelectTextObject('B','a')<CR>
onoremap <silent> a{ :<C-u>call <SID>SelectTextObject('B','a')<CR>
onoremap <silent> a} :<C-u>call <SID>SelectTextObject('B','a')<CR>

xnoremap <silent> iB :<C-u>call <SID>SelectTextObject('B','i')<CR>
xnoremap <silent> i{ :<C-u>call <SID>SelectTextObject('B','i')<CR>
xnoremap <silent> i} :<C-u>call <SID>SelectTextObject('B','i')<CR>
xnoremap <silent> aB :<C-u>call <SID>SelectTextObject('B','a')<CR>
xnoremap <silent> a{ :<C-u>call <SID>SelectTextObject('B','a')<CR>
xnoremap <silent> a} :<C-u>call <SID>SelectTextObject('B','a')<CR>

onoremap <silent> i[ :<C-u>call <SID>SelectTextObject('[','i')<CR>
onoremap <silent> i] :<C-u>call <SID>SelectTextObject('[','i')<CR>
onoremap <silent> ir :<C-u>call <SID>SelectTextObject('[','i')<CR>
onoremap <silent> a[ :<C-u>call <SID>SelectTextObject('[','a')<CR>
onoremap <silent> a] :<C-u>call <SID>SelectTextObject('[','a')<CR>
onoremap <silent> ar :<C-u>call <SID>SelectTextObject('[','a')<CR>

xnoremap <silent> i[ :<C-u>call <SID>SelectTextObject('[','i')<CR>
xnoremap <silent> i] :<C-u>call <SID>SelectTextObject('[','i')<CR>
xnoremap <silent> ir :<C-u>call <SID>SelectTextObject('[','i')<CR>
xnoremap <silent> a[ :<C-u>call <SID>SelectTextObject('[','a')<CR>
xnoremap <silent> a] :<C-u>call <SID>SelectTextObject('[','a')<CR>
xnoremap <silent> ar :<C-u>call <SID>SelectTextObject('[','a')<CR>

onoremap <silent> i< :<C-u>call <SID>SelectTextObject('<','i')<CR>
onoremap <silent> i> :<C-u>call <SID>SelectTextObject('<','i')<CR>
onoremap <silent> ia :<C-u>call <SID>SelectTextObject('<','i')<CR>
onoremap <silent> a< :<C-u>call <SID>SelectTextObject('<','a')<CR>
onoremap <silent> a> :<C-u>call <SID>SelectTextObject('<','a')<CR>
onoremap <silent> aa :<C-u>call <SID>SelectTextObject('<','a')<CR>

xnoremap <silent> i< :<C-u>call <SID>SelectTextObject('<','i')<CR>
xnoremap <silent> i> :<C-u>call <SID>SelectTextObject('<','i')<CR>
xnoremap <silent> ia :<C-u>call <SID>SelectTextObject('<','i')<CR>
xnoremap <silent> a< :<C-u>call <SID>SelectTextObject('<','a')<CR>
xnoremap <silent> a> :<C-u>call <SID>SelectTextObject('<','a')<CR>
xnoremap <silent> aa :<C-u>call <SID>SelectTextObject('<','a')<CR>

func! s:SelectTextObjectQuote(obj,motion)
  if getline('.') !~ a:obj.".*".a:obj
    return
  endif

  if getline('.')[col('.')-1:-1] !~ a:obj
    execute "normal! F".a:obj
  elseif getline('.')[0:col('.')-1] !~ a:obj
    execute "normal! f".a:obj
  endif

  let curchar = getline('.')[col('.')-1]
  if curchar == a:obj && getline('.')[col('.')-2] == a:obj
    execute "normal! i\<Space>\<Esc>"
  elseif curchar == a:obj && getline('.')[col('.')] == a:obj
    execute "normal! a\<Space>\<Esc>"
  endif

  execute "normal! v".a:motion.a:obj
endfunc

onoremap <silent> i" :<C-u>call <SID>SelectTextObjectQuote('"','i')<CR>
onoremap <silent> a" :<C-u>call <SID>SelectTextObjectQuote('"','a')<CR>
onoremap <silent> i' :<C-u>call <SID>SelectTextObjectQuote("'",'i')<CR>
onoremap <silent> a' :<C-u>call <SID>SelectTextObjectQuote("'",'a')<CR>
onoremap <silent> i` :<C-u>call <SID>SelectTextObjectQuote("`",'i')<CR>
onoremap <silent> a` :<C-u>call <SID>SelectTextObjectQuote("`",'a')<CR>

xnoremap <silent> i" :<C-u>call <SID>SelectTextObjectQuote('"','i')<CR>
xnoremap <silent> a" :<C-u>call <SID>SelectTextObjectQuote('"','a')<CR>
xnoremap <silent> i' :<C-u>call <SID>SelectTextObjectQuote("'",'i')<CR>
xnoremap <silent> a' :<C-u>call <SID>SelectTextObjectQuote("'",'a')<CR>
xnoremap <silent> i` :<C-u>call <SID>SelectTextObjectQuote("`",'i')<CR>
xnoremap <silent> a` :<C-u>call <SID>SelectTextObjectQuote("`",'a')<CR>

" vim:set et ts=2 sts=2 sw=2:
