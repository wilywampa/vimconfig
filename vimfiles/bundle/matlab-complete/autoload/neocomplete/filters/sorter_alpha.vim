let s:save_cpo = &cpo
set cpo&vim

function! neocomplete#filters#sorter_alpha#define()
  return s:sorter
endfunction

let s:sorter = {
    \ 'name' : 'sorter_alpha',
    \ 'description' : 'sort by word order with letters before symbols',
    \}

function! s:sorter.filter(context)
  return sort(a:context.candidates, 's:compare')
endfunction

function! s:compare(i1, i2)
  return
      \ substitute(a:i1.word, '[^[:alpha:]]',
      \   '\=nr2char(char2nr(submatch(0))+122)', 'g') >#
      \ substitute(a:i2.word, '[^[:alpha:]]',
      \   '\=nr2char(char2nr(submatch(0))+122)', 'g')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
