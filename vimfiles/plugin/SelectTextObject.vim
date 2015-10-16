" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('SelectTextObjectLoaded')
  finish
endif

let SelectTextObjectLoaded=1

func! s:SelectTextObject(obj, motion, visual)
  let eventignore = &eventignore
  set eventignore+=all
  try
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

    let linewise = 0
    if stridx(line, left) < strridx(line, right)
      " Expand selection
      let did_expand = 0
      if a:visual && col("'<") != col("'>")
        if line("'<") == line('.') && line("'>") == line('.') &&
            \ line[col("'<")-1] == left && line[col("'>")-1] == right
          execute "normal! `<v`>loh\<Esc>"
          let did_expand = 1
        endif
      endif

      while !s:CursorInPair(left,right)
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

      " Handle empty pair by inserting a space
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
    elseif stridx(line, left) == -1 && stridx(line, right) == -1
      let linewise = s:GetLinewise(left, right)
    endif

    if mode() =~# "[Vv\<C-v>]"
      execute "normal! \<Esc>"
    endif

    " Need to manually select character if single character in pair for inner motion
    if a:motion == 'i' && line[col('.')-1] == left && line[col('.')+1] == right
      execute "normal! lv"
    elseif a:motion == 'i' && line[col('.')-2] == left && line[col('.')] == right
      execute "normal! v"
    elseif a:motion == 'i' && line[col('.')-3] == left && line[col('.')-1] == right
        \ && line[col('.')-2] != right && line[col('.')-2] != left
      execute "normal! hv"
    else
      execute "normal! v".a:motion.a:obj.(linewise ? 'V' : '')
    endif
  finally
    let &eventignore = eventignore
    echo
  endtry
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

func! s:GetLinewise(left, right)
  let curpos = getpos('.')
  let cb_save = &clipboard
  set clipboard=
  let reg_save = @@
  try
    execute "normal! v\<Esc>vi".a:right."y"
    if match(@@, "\n$") == -1
      return stridx(getline("'<"), a:left) == -1 &&
          \  stridx(getline("'>"), a:right) == -1
    else
      return 1
    endif
  finally
    call setpos('.',curpos)
    let &clipboard = cb_save
    let @@ = reg_save
  endtry
endfunc

onoremap ib :<C-u>call <SID>SelectTextObject('b','i',0)<CR>
onoremap i( :<C-u>call <SID>SelectTextObject('b','i',0)<CR>
onoremap i) :<C-u>call <SID>SelectTextObject('b','i',0)<CR>
onoremap ab :<C-u>call <SID>SelectTextObject('b','a',0)<CR>
onoremap a( :<C-u>call <SID>SelectTextObject('b','a',0)<CR>
onoremap a) :<C-u>call <SID>SelectTextObject('b','a',0)<CR>

xnoremap ib :<C-u>call <SID>SelectTextObject('b','i',1)<CR>
xnoremap i( :<C-u>call <SID>SelectTextObject('b','i',1)<CR>
xnoremap i) :<C-u>call <SID>SelectTextObject('b','i',1)<CR>
xnoremap ab :<C-u>call <SID>SelectTextObject('b','a',1)<CR>
xnoremap a( :<C-u>call <SID>SelectTextObject('b','a',1)<CR>
xnoremap a) :<C-u>call <SID>SelectTextObject('b','a',1)<CR>

onoremap iB :<C-u>call <SID>SelectTextObject('B','i',0)<CR>
onoremap i{ :<C-u>call <SID>SelectTextObject('B','i',0)<CR>
onoremap i} :<C-u>call <SID>SelectTextObject('B','i',0)<CR>
onoremap aB :<C-u>call <SID>SelectTextObject('B','a',0)<CR>
onoremap a{ :<C-u>call <SID>SelectTextObject('B','a',0)<CR>
onoremap a} :<C-u>call <SID>SelectTextObject('B','a',0)<CR>

xnoremap iB :<C-u>call <SID>SelectTextObject('B','i',1)<CR>
xnoremap i{ :<C-u>call <SID>SelectTextObject('B','i',1)<CR>
xnoremap i} :<C-u>call <SID>SelectTextObject('B','i',1)<CR>
xnoremap aB :<C-u>call <SID>SelectTextObject('B','a',1)<CR>
xnoremap a{ :<C-u>call <SID>SelectTextObject('B','a',1)<CR>
xnoremap a} :<C-u>call <SID>SelectTextObject('B','a',1)<CR>

onoremap i[ :<C-u>call <SID>SelectTextObject('[','i',0)<CR>
onoremap i] :<C-u>call <SID>SelectTextObject('[','i',0)<CR>
onoremap ir :<C-u>call <SID>SelectTextObject('[','i',0)<CR>
onoremap a[ :<C-u>call <SID>SelectTextObject('[','a',0)<CR>
onoremap a] :<C-u>call <SID>SelectTextObject('[','a',0)<CR>
onoremap ar :<C-u>call <SID>SelectTextObject('[','a',0)<CR>

xnoremap i[ :<C-u>call <SID>SelectTextObject('[','i',1)<CR>
xnoremap i] :<C-u>call <SID>SelectTextObject('[','i',1)<CR>
xnoremap ir :<C-u>call <SID>SelectTextObject('[','i',1)<CR>
xnoremap a[ :<C-u>call <SID>SelectTextObject('[','a',1)<CR>
xnoremap a] :<C-u>call <SID>SelectTextObject('[','a',1)<CR>
xnoremap ar :<C-u>call <SID>SelectTextObject('[','a',1)<CR>

onoremap i< :<C-u>call <SID>SelectTextObject('<','i',0)<CR>
onoremap i> :<C-u>call <SID>SelectTextObject('<','i',0)<CR>
onoremap ia :<C-u>call <SID>SelectTextObject('<','i',0)<CR>
onoremap a< :<C-u>call <SID>SelectTextObject('<','a',0)<CR>
onoremap a> :<C-u>call <SID>SelectTextObject('<','a',0)<CR>
onoremap aa :<C-u>call <SID>SelectTextObject('<','a',0)<CR>

xnoremap i< :<C-u>call <SID>SelectTextObject('<','i',1)<CR>
xnoremap i> :<C-u>call <SID>SelectTextObject('<','i',1)<CR>
xnoremap ia :<C-u>call <SID>SelectTextObject('<','i',1)<CR>
xnoremap a< :<C-u>call <SID>SelectTextObject('<','a',1)<CR>
xnoremap a> :<C-u>call <SID>SelectTextObject('<','a',1)<CR>
xnoremap aa :<C-u>call <SID>SelectTextObject('<','a',1)<CR>

func! s:SelectTextObjectQuote(obj, motion)
  try
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
  finally
    echo
  endtry
endfunc

onoremap i" :<C-u>call <SID>SelectTextObjectQuote('"','i')<CR>
onoremap a" :<C-u>call <SID>SelectTextObjectQuote('"','a')<CR>
onoremap i' :<C-u>call <SID>SelectTextObjectQuote("'",'i')<CR>
onoremap a' :<C-u>call <SID>SelectTextObjectQuote("'",'a')<CR>
onoremap i` :<C-u>call <SID>SelectTextObjectQuote("`",'i')<CR>
onoremap a` :<C-u>call <SID>SelectTextObjectQuote("`",'a')<CR>

xnoremap i" :<C-u>call <SID>SelectTextObjectQuote('"','i')<CR>
xnoremap a" :<C-u>call <SID>SelectTextObjectQuote('"','a')<CR>
xnoremap i' :<C-u>call <SID>SelectTextObjectQuote("'",'i')<CR>
xnoremap a' :<C-u>call <SID>SelectTextObjectQuote("'",'a')<CR>
xnoremap i` :<C-u>call <SID>SelectTextObjectQuote("`",'i')<CR>
xnoremap a` :<C-u>call <SID>SelectTextObjectQuote("`",'a')<CR>

" vim:set et ts=2 sts=2 sw=2:
