if exists("b:did_matlab_abbrevs")
  finish
endif

let b:did_matlab_abbrevs = 1

func! s:Abbreviations()
  let start = getline('.')[0:col('.')-1]
  if     start =~# '\v<len$'    | return 'gth('
  elseif start =~# '\v<fig$'    | return 'ure('
  elseif start =~# '\v<sub$'    | return 'plot('
  elseif start =~# '\v<leg$'    | return 'end('
  elseif start =~# '\v<[xyz]l$' | return 'abel('
  else
    return '('
  endif
endfunc

inoremap <buffer> <expr> ( <SID>Abbreviations()
