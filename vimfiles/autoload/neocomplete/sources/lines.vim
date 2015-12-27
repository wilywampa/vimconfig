let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name'     : 'lines',
    \ 'kind'     : 'manual',
    \ 'mark'     : '[L]',
    \ 'rank'     : 1,
    \ 'disabled' : 1,
    \ }

function! s:source.gather_candidates(context)
  if col('.') != col('$')
    return []
  endif
  let buffers = filter(neocomplete#util#uniq(
      \ [bufnr('#')] + map(range(1, winnr('$')), 'winbufnr(v:val)')),
      \ 'buflisted(v:val)')
  let candidates = []
  let curline = getline('.')
  for buffer in buffers
    let bufname = fnamemodify(bufname(buffer), ':t')
    call extend(candidates, map(filter(getbufline(buffer, 1, '$'),
        \                              'v:val !=# curline'), '{
        \ "word" : substitute(v:val, "^\\s*", "", ""),
        \ "menu" : bufname,
        \ }'))
  endfor
  return candidates
endfunction

function! s:source.get_complete_position(context)
  if col('.') != col('$')
    return -1
  endif
  return strchars(substitute(getline('.'), '^\s*\zs\S.*$', '', ''))
endfunction

function! neocomplete#sources#lines#define()
  return s:source
endfunction

function! neocomplete#sources#lines#start()
  let s:completefunc = &l:completefunc
  setlocal completefunc=neocomplete#sources#lines#complete
  augroup lines_completefunc
    autocmd!
    autocmd InsertEnter,InsertLeave *
        \ let &l:completefunc = s:completefunc |
        \ autocmd! lines_completefunc
    autocmd InsertCharPre * if v:char !~ '\w' |
        \ let &l:completefunc = s:completefunc |
        \ execute 'autocmd! lines_completefunc' | endif
  augroup END
  return "\<C-x>\<C-u>"
endfunction

function! neocomplete#sources#lines#complete(findstart, base)
  if a:findstart
    return s:source.get_complete_position({})
  else
    return filter(s:source.gather_candidates({}),
        \ "stridx(tolower(v:val.word), tolower(a:base)) == 0")
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
