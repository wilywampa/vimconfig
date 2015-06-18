let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
    \ 'name': 'vimuxindex',
    \ 'required_pattern_length': 0,
    \ }

function! s:unite_source.gather_candidates(args, context) abort
  let type = exists("g:VimuxRunnerType") ? g:VimuxRunnerType : "pane"

  if type == "window"
    silent let options = map(split(system(
        \ 'tmux list-windows'),
        \ '\n'), 'split(v:val, ''\v\s+\ze\S+$'')')
  else
    silent let options = map(split(system(
        \ 'tmux list-panes -s -F "#I.#P: #F #W ' .
        \ '(#{pane_current_command}) #D #{pane_active} #{window_active}"'),
        \ '\n'), 'split(v:val, ''\s\+\ze%'')')
    call filter(options, 'v:val[1] !~ " 1 1$"')
    call map(options, '[v:val[0], split(v:val[1], ''\s'')[0]]')
  endif

  return map(options,
      \ '{ "word": v:val[0],
      \    "source": s:unite_source.name,
      \    "kind": "command",
      \    "action__command": "let g:VimuxRunnerIndex = ''" . v:val[1] . "''",
      \  }')
endfunction

function! unite#sources#vimuxindex#define() abort
  return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
