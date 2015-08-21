let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#history_ipython#define()
  return s:source
endfunction

let s:source = {
    \ 'name' : 'history/ipython',
    \ 'description' : 'candidates from IPython history',
    \ 'action_table' : {},
    \ 'hooks' : {},
    \ 'default_action' : 'send',
    \ 'default_kind' : 'word',
    \ 'syntax' : 'uniteSource__Python',
    \}

function! s:source.hooks.on_syntax(args, context)
  let save_current_syntax = get(b:, 'current_syntax', '')
  unlet! b:current_syntax

  try
    silent! syntax include @Python syntax/python.vim
    syntax region uniteSource__IPythonPython
        \ start=' ' end='$' contains=@Python containedin=uniteSource__IPython
  finally
    let b:current_syntax = save_current_syntax
  endtry
endfunction

function! s:source.hooks.on_init(args, context)
  let a:context.source__input = get(a:args, 0, a:context.input)
  if a:context.source__input == '' || a:context.unite__is_restart
    let a:context.source__input = unite#util#input('Pattern: ',
        \ a:context.source__input)
  endif

  call unite#print_source_message('Pattern: '
      \ . a:context.source__input, s:source.name)
endfunction

function! s:source.gather_candidates(args, context)
  return map(copy(IPythonHistory(a:context.source__input)), "{
      \ 'word' : v:val.code,
      \ 'abbr' : printf('# %d/%d -\n%s', v:val.session, v:val.line, v:val.code),
      \ 'is_multiline' : 1,
      \ }")
endfunction

let s:source.action_table.send = {
    \ 'description' : 'run in IPython',
    \ }

function! s:source.action_table.send.func(candidate)
  let g:ipy_input = a:candidate.word
  call IPyRunIPyInput()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
