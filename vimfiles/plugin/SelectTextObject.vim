" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('SelectTextObjectLoaded')
  finish
endif

let SelectTextObjectLoaded=1

func! s:SelectTextObject(obj, motion, visual)
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

func! s:Vis()
  return mode() =~? "[v\<C-v>]" ? 1 : 0
endfunc

let start = ":\<C-u>call \<SID>SelectTextObject("

onoremap <expr> ib ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
onoremap <expr> i( ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
onoremap <expr> i) ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
onoremap <expr> ab ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"
onoremap <expr> a( ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"
onoremap <expr> a) ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"

xnoremap <expr> ib ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i( ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i) ":\<C-u>call \<SID>SelectTextObject('b','i',".<SID>Vis().")\<CR>"
xnoremap <expr> ab ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a( ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a) ":\<C-u>call \<SID>SelectTextObject('b','a',".<SID>Vis().")\<CR>"

onoremap <expr> iB ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
onoremap <expr> i{ ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
onoremap <expr> i} ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
onoremap <expr> aB ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"
onoremap <expr> a{ ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"
onoremap <expr> a} ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"

xnoremap <expr> iB ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i{ ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i} ":\<C-u>call \<SID>SelectTextObject('B','i',".<SID>Vis().")\<CR>"
xnoremap <expr> aB ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a{ ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a} ":\<C-u>call \<SID>SelectTextObject('B','a',".<SID>Vis().")\<CR>"

onoremap <expr> i[ ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
onoremap <expr> i] ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
onoremap <expr> ir ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
onoremap <expr> a[ ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"
onoremap <expr> a] ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"
onoremap <expr> ar ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"

xnoremap <expr> i[ ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i] ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
xnoremap <expr> ir ":\<C-u>call \<SID>SelectTextObject('[','i',".<SID>Vis().")\<CR>"
xnoremap <expr> a[ ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a] ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"
xnoremap <expr> ar ":\<C-u>call \<SID>SelectTextObject('[','a',".<SID>Vis().")\<CR>"

onoremap <expr> i< ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
onoremap <expr> i> ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
onoremap <expr> ia ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
onoremap <expr> a< ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"
onoremap <expr> a> ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"
onoremap <expr> aa ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"

xnoremap <expr> i< ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
xnoremap <expr> i> ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
xnoremap <expr> ia ":\<C-u>call \<SID>SelectTextObject('<','i',".<SID>Vis().")\<CR>"
xnoremap <expr> a< ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"
xnoremap <expr> a> ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"
xnoremap <expr> aa ":\<C-u>call \<SID>SelectTextObject('<','a',".<SID>Vis().")\<CR>"

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
