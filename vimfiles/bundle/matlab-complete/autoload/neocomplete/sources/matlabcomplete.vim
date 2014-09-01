let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name'    : 'matlab-complete',
    \ 'kind'    : 'keyword',
    \ 'mark'    : '[MATLAB]',
    \ 'rank'    :  200,
    \ 'sorters' : 'sorter_alpha',
    \ }

function! s:source.gather_candidates(context)
  return matlabcomplete#complete(0, '')
endfunction

function! neocomplete#sources#matlabcomplete#define()
  return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
