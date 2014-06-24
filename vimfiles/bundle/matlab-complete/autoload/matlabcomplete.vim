if !exists('g:matlab_dict')
  if has("mac") || has("win16") || has("win32") || has("win64")
    let g:matlab_dict = expand('~/Documents/MATLAB/dict.m')
  elseif system('echo $OSTYPE') =~ 'cygwin'
    let g:matlab_dict =
        \ system('cygpath -u "$USERPROFILE/Documents/MATLAB/dict.m" | tr -d \\n')
  else
    let g:matlab_dict = expand('~/MATLAB/dict.m')
  endif
endif

function! matlabcomplete#complete(findstart, base)
  let iskeyword_save = &iskeyword
  set iskeyword+=.
  try
    if a:findstart
      let l:line=getline('.')
      let l:start=col('.')-1
      while l:start > 0 && l:line[l:start-1] =~ '\w\|\.\|''\|('
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
  finally
    let &iskeyword = iskeyword_save
  endtry
endfunction
