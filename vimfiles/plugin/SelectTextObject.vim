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
  let line = getline('.')

  if stridx(line, left) < strridx(line, right)
    " Expand selection
    let did_expand = 0
    if line("'<") == line('.') && line("'>") == line('.') &&
        \ line[col("'<")-2] == left && line[col("'>")] == right
      execute "normal! `<v`>loh\<Esc>"
      let did_expand = 1
    endif

    while !<SID>CursorInPair(left,right)
      if line[col('.'):-1] =~ escape(left,'[]').'.*'.escape(right,'[]')
        execute "normal! f".left
      elseif line[0:col('.')-2] =~ escape(left,'[]').'.*'.escape(right,'[]')
        execute "normal! F".right
      else
        call setpos('.',curpos)
        execute "normal! v\<Esc>"
        return
      endif
    endwhile

    if a:motion == 'i'
      let curchar = line[col('.')-1]
      if curchar == right && line[col('.')-2] == left
        execute "normal! i\<Space>\<Esc>"
      elseif curchar == left && line[col('.')] == right
        execute "normal! a\<Space>\<Esc>"
      elseif line[col('.')-2] == left && did_expand
        execute "normal! F".left
      endif
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
  let line = getline('.')
  if line !~ a:obj.".*".a:obj
    return
  endif

  if stridx(line[col('.')-1:-1] ,a:obj) == -1
    execute "normal! F".a:obj
  elseif stridx(line[0:col('.')-1], a:obj) == -1
    execute "normal! f".a:obj
  endif

  let curchar = line[col('.')-1]
  if curchar == a:obj && line[col('.')-2] == a:obj
    execute "normal! i\<Space>\<Esc>"
  elseif curchar == a:obj && line[col('.')] == a:obj
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
