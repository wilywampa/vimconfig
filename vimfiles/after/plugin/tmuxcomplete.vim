if !exists('g:tmuxcomplete#loaded')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name' : 'tmux-complete',
    \ 'kind' : 'keyword',
    \ 'mark' : '[tmux]',
    \ 'rank' : 4,
    \ }

function! s:source.gather_candidates(context)
  let save = get(g:, 'tmuxcomplete#mode', 'word')
  try
    let g:tmuxcomplete#mode = 'word'
    let candidates = tmuxcomplete#gather_candidates()
    let g:tmuxcomplete#mode = 'WORD'
    call extend(candidates, tmuxcomplete#gather_candidates())
    return candidates
  finally
    let g:tmuxcomplete#mode = save
  endtry
endfunction

silent! call neocomplete#define_source(s:source)

function! s:complete_tmux() abort " {{{
    let text = neocomplete#get_cur_text(1)
    let sources = neocomplete#complete#_set_results_pos(text)
    return unite#start_complete(['neocomplete'], {
        \ 'source__sources' : ['tmux-complete'], 'auto_preview' : 1,
        \ 'here' : 0, 'resize' : 0, 'split' : 0, 'input' : escape(tolower(
        \ text[neocomplete#complete#_get_complete_pos(sources): ]),
        \ '~\.^$[]*') . ' '})
endfunction " }}}
inoremap <silent> <expr> <C-x>t <SID>complete_tmux()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 fdm=marker:
