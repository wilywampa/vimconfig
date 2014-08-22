function! matlabcomplete#complete(findstart, base)
  if a:findstart
    let l:line=getline('.')
    let l:start=col('.')-1
    let pat = '\v\h\w*(\{\d+\}|\{\d*)?(\.%[\(''])?\w*%[''\)]'
    while l:start > 0 && l:line[l:start-1:col('.')] !~ pat
      let l:start -= 1
    endwhile
    while l:start > 0 && match(l:line[l:start-1:col('.')], pat) == 0
      let l:start -= 1
    endwhile
    return l:start
  else
    let l:results=[]
    if &filetype != 'matlab' || !filereadable(g:matlab_dict)
      return
    endif
    let l:entries=readfile(g:matlab_dict)
    for l:entry in l:entries
      let l:split = split(l:entry, ' ')
      let l:word = l:split[0]
      if l:word =~ '^'.a:base
        let l:menu = join(l:split[1:-1])
        call add(l:results, {'word': l:word, 'menu': l:menu})
      endif
    endfor
    return l:results
  endif
endfunction
