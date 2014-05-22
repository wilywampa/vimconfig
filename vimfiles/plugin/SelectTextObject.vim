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

  let curline = getline('.')
  let curchar = curline[col('.')-1]

  if searchpair(left,'',right,'n')
    execute "normal! v".a:motion.a:obj
  elseif curline =~ escape(left,'[]').'.*'.escape(right,'[]')
    if curchar == left
      if curline[col('.')] == right
        execute "normal! ax\<Esc>h"
      endif
    elseif curchar == right
      if curline[col('.')-2] == left
        execute "normal! ix\<Esc>h"
      endif
    elseif curline[col('.'):-1] =~ escape(left,'[]').'.*'.escape(right,'[]')
      call search(right,'',line('.'))
      if curline[col('.')-2] == left
        execute "normal! ix\<Esc>h"
      endif
    elseif curline[0:col('.')-2] =~ escape(left,'[]').'.*'.escape(right,'[]')
      call search(left,'b',line('.'))
      if curline[col('.')] == left
        execute "normal! ax\<Esc>h"
      endif
    endif
  else
    return
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
onoremap <silent> a[ :<C-u>call <SID>SelectTextObject('[','a')<CR>
onoremap <silent> a] :<C-u>call <SID>SelectTextObject('[','a')<CR>

xnoremap <silent> i[ :<C-u>call <SID>SelectTextObject('[','i')<CR>
xnoremap <silent> i] :<C-u>call <SID>SelectTextObject('[','i')<CR>
xnoremap <silent> a[ :<C-u>call <SID>SelectTextObject('[','a')<CR>
xnoremap <silent> a] :<C-u>call <SID>SelectTextObject('[','a')<CR>

onoremap <silent> i< :<C-u>call <SID>SelectTextObject('<','i')<CR>
onoremap <silent> i> :<C-u>call <SID>SelectTextObject('<','i')<CR>
onoremap <silent> a< :<C-u>call <SID>SelectTextObject('<','a')<CR>
onoremap <silent> a> :<C-u>call <SID>SelectTextObject('<','a')<CR>

xnoremap <silent> i< :<C-u>call <SID>SelectTextObject('<','i')<CR>
xnoremap <silent> i> :<C-u>call <SID>SelectTextObject('<','i')<CR>
xnoremap <silent> a< :<C-u>call <SID>SelectTextObject('<','a')<CR>
xnoremap <silent> a> :<C-u>call <SID>SelectTextObject('<','a')<CR>

func! s:SelectTextObjectQuote(obj,motion)
  if getline('.') !~ a:obj
    return
  endif

  if !search(a:obj,'cn',line('.'))
    call search(a:obj,'b',line('.'))
  endif
  execute "normal! v".a:motion.a:obj."\<Esc>`<"
  if getline('.')[col('.')] == a:obj && a:motion == 'i'
    execute "normal! ax\<Esc>v"
  else
    execute "normal! v".a:motion.a:obj
  endif
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
