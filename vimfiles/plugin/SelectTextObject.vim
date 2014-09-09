" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('SelectTextObjectLoaded')
  finish
endif

let SelectTextObjectLoaded=1

func! SelectTextObject(obj, motion, visual)
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
    if a:visual && col("'<") != col("'>")
      if line("'<") == line('.') && line("'>") == line('.') &&
          \ line[col("'<")-1] == left && line[col("'>")+1] == right
        execute "normal! `<v`>loh\<Esc>"
        let did_expand = 1
      endif
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

  if line[col('.')-1] == left && line[col('.')+1] == right && a:motion == 'i'
    execute "normal! lv"
  elseif line[col('.')-2] == left && line[col('.')] == right && a:motion == 'i'
    execute "normal! v"
  elseif line[col('.')-3] == left && line[col('.')-1] == right && a:motion == 'i'
    execute "normal! hv"
  else
    execute "normal! v".a:motion.a:obj
  endif
endfunc

func! s:CursorInPair(left, right)
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

func! s:WrapSelectTextObject(obj, motion)
  return ":"."\<C-u>call SelectTextObject('".
      \ a:obj."','".a:motion."','".
      \ (mode() =~? "[v\<C-v>]" ? 1 : 0)."')\<CR>"
endfunc

onoremap <silent> <expr> ib <SID>WrapSelectTextObject('b','i')
onoremap <silent> <expr> i( <SID>WrapSelectTextObject('b','i')
onoremap <silent> <expr> i) <SID>WrapSelectTextObject('b','i')
onoremap <silent> <expr> ab <SID>WrapSelectTextObject('b','a')
onoremap <silent> <expr> a( <SID>WrapSelectTextObject('b','a')
onoremap <silent> <expr> a) <SID>WrapSelectTextObject('b','a')

xnoremap <silent> <expr> ib <SID>WrapSelectTextObject('b','i')
xnoremap <silent> <expr> i( <SID>WrapSelectTextObject('b','i')
xnoremap <silent> <expr> i) <SID>WrapSelectTextObject('b','i')
xnoremap <silent> <expr> ab <SID>WrapSelectTextObject('b','a')
xnoremap <silent> <expr> a( <SID>WrapSelectTextObject('b','a')
xnoremap <silent> <expr> a) <SID>WrapSelectTextObject('b','a')

onoremap <silent> <expr> iB <SID>WrapSelectTextObject('B','i')
onoremap <silent> <expr> i{ <SID>WrapSelectTextObject('B','i')
onoremap <silent> <expr> i} <SID>WrapSelectTextObject('B','i')
onoremap <silent> <expr> aB <SID>WrapSelectTextObject('B','a')
onoremap <silent> <expr> a{ <SID>WrapSelectTextObject('B','a')
onoremap <silent> <expr> a} <SID>WrapSelectTextObject('B','a')

xnoremap <silent> <expr> iB <SID>WrapSelectTextObject('B','i')
xnoremap <silent> <expr> i{ <SID>WrapSelectTextObject('B','i')
xnoremap <silent> <expr> i} <SID>WrapSelectTextObject('B','i')
xnoremap <silent> <expr> aB <SID>WrapSelectTextObject('B','a')
xnoremap <silent> <expr> a{ <SID>WrapSelectTextObject('B','a')
xnoremap <silent> <expr> a} <SID>WrapSelectTextObject('B','a')

onoremap <silent> <expr> i[ <SID>WrapSelectTextObject('[','i')
onoremap <silent> <expr> i] <SID>WrapSelectTextObject('[','i')
onoremap <silent> <expr> ir <SID>WrapSelectTextObject('[','i')
onoremap <silent> <expr> a[ <SID>WrapSelectTextObject('[','a')
onoremap <silent> <expr> a] <SID>WrapSelectTextObject('[','a')
onoremap <silent> <expr> ar <SID>WrapSelectTextObject('[','a')

xnoremap <silent> <expr> i[ <SID>WrapSelectTextObject('[','i')
xnoremap <silent> <expr> i] <SID>WrapSelectTextObject('[','i')
xnoremap <silent> <expr> ir <SID>WrapSelectTextObject('[','i')
xnoremap <silent> <expr> a[ <SID>WrapSelectTextObject('[','a')
xnoremap <silent> <expr> a] <SID>WrapSelectTextObject('[','a')
xnoremap <silent> <expr> ar <SID>WrapSelectTextObject('[','a')

onoremap <silent> <expr> i< <SID>WrapSelectTextObject('<','i')
onoremap <silent> <expr> i> <SID>WrapSelectTextObject('<','i')
onoremap <silent> <expr> ia <SID>WrapSelectTextObject('<','i')
onoremap <silent> <expr> a< <SID>WrapSelectTextObject('<','a')
onoremap <silent> <expr> a> <SID>WrapSelectTextObject('<','a')
onoremap <silent> <expr> aa <SID>WrapSelectTextObject('<','a')

xnoremap <silent> <expr> i< <SID>WrapSelectTextObject('<','i')
xnoremap <silent> <expr> i> <SID>WrapSelectTextObject('<','i')
xnoremap <silent> <expr> ia <SID>WrapSelectTextObject('<','i')
xnoremap <silent> <expr> a< <SID>WrapSelectTextObject('<','a')
xnoremap <silent> <expr> a> <SID>WrapSelectTextObject('<','a')
xnoremap <silent> <expr> aa <SID>WrapSelectTextObject('<','a')

func! s:SelectTextObjectQuote(obj, motion)
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
