if !(has('python') || has('python3'))
  function! neocomplete#sources#ipython_history#define() abort
    return {}
  endfunction
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

function! s:default(name, default) abort
  if !exists(a:name) | let {a:name} = a:default | endif
endfunction
call s:default('g:ipython_history_auto', 0)
call s:default('g:ipython_history_complete_len',
    \ g:ipython_history_auto ? 20 : 100)
call s:default('g:ipython_history_complete_maxchars', 1000)

if !exists('s:V')
  let s:V = vital#of('neocomplete')
  let s:List = s:V.import('Data.List')
endif

call s:default('s:history', {})

let s:source = {
    \ 'name' : 'ipython_history',
    \ 'kind' : 'manual',
    \ 'mark' : '[Py]',
    \ 'rank' : 10,
    \ 'sorters' : ['sorter_ipython_history'],
    \ 'matchers' : ['matcher_ipython_history'],
    \ 'filetypes' : {'python' : 1},
    \ 'is_volatile' : 1,
    \ }

function! neocomplete#sources#ipython_history#define() abort
  return s:source
endfunction

let s:sorter = {'name' : 'sorter_ipython_history'}
function! s:sorter.filter(context) abort
  return sort(copy(a:context.candidates), 's:compare')
endfunction
function! s:compare(a, b) abort
  for [a, b] in filter(s:List.zip(a:a._rank, a:b._rank), "
      \ v:val[0] != v:val[1]")
    return a == 0 ? -1 : (b == 0 ? 1 : (a > b ? -1 : 1))
  endfor
  return 0
endfunction
call neocomplete#define_filter(s:sorter)

let s:matcher = {'name' : 'matcher_ipython_history'}
function! s:matcher.filter(context) abort
  return a:context.candidates
endfunction
call neocomplete#define_filter(s:matcher)

function! neocomplete#sources#ipython_history#insert() abort
  let key = exists('v:completed_item') ?
      \ matchstr(get(v:completed_item, 'menu', ''), '\d\+/\d\+') : ''
  if empty(key)
    let items = sort(filter(s:List.flatten(map(copy(values(s:history)),
        \ 'v:val.candidates')), "
        \ stridx(tolower(v:val.info), tolower(getline('.'))) >= 0
        \ "), 's:compare')
    let key = matchstr(get(get(items, 0, {}), 'menu', ''), '\d\+/\d\+')
  endif
  let item = get(s:history, key, -1)
  if type(item) != type({})
    return neocomplete#start_manual_complete(['ipython_history'])
  endif
  return printf("\<Esc>:\<C-u>call ".
      \ "neocomplete#sources#ipython_history#_insert('%s')\<CR>", key)
endfunction
function! neocomplete#sources#ipython_history#_insert(key) abort
  let item = get(s:history, a:key, {'code' : ''})
  let lines = split(item.code, '\n', 1)
  call setline('.', lines[0])
  call append('.', lines[1:])
  let lnum = getline('.')
  call setpos("'[", [0, lnum, 1, 0])
  call setpos("']", [0, lnum + len(lines) - 1, 1, 0])
endfunction

" @vimlint(EVL103, 1, a:context)
function! s:source.gather_candidates(context) abort
  if col('.') != col('$') ||
      \ (!g:ipython_history_auto && neocomplete#is_auto_complete())
    return []
  endif

  let word = matchstr(getline('.'), '\h\w*')
  let s:history = {}
  let parts = split(substitute(
      \ getline('.'), '^[# ]*', '', ''), '[[\](),=* ]\+')
  let biggest = s:List.sort_by(copy(parts), '-strchars(v:val)')
  let pattern = join(filter(parts, "
      \ index(biggest, v:val) >= 0 && index(biggest, v:val) <= 2"), '*')

  let ipython_history_len_save = g:ipython_history_len
  let g:ipython_history_len = g:ipython_history_complete_len
  try
    for history in filter(IPythonHistory(pattern),
        \ "len(v:val.code) < g:ipython_history_complete_maxchars")
      let lines = split(history.code, "\n")
      let s:history[printf('%s/%s', history.session, history.line)] = {
          \ 'code' : history.code,
          \ 'candidates' : map(s:List.with_index(lines), "{
          \   'word' : v:val[0],
          \   'menu' : printf('%s/%s%s', history.session, history.line,
          \                   len(lines) == 1 ? '' : '.' . v:val[1]),
          \   'info' : history.code,
          \   '_rank' : [
          \     (stridx(tolower(history.code), tolower(word)) == 0) + 1,
          \     history.session, history.line, v:val[1]],
          \   }"),
          \ }
    endfor
  finally
    let g:ipython_history_len = ipython_history_len_save
  endtry

  return filter(s:List.flatten(map(copy(values(s:history)),
      \ 'v:val.candidates')), 'v:val.word =~? "' . word . '"')
endfunction

function! s:source.get_complete_position(context) abort
  if col('.') != col('$')
    return -1
  endif
  return strchars(substitute(getline('.'), '^\s*\zs\S.*$', '', ''))
endfunction
" @vimlint(EVL103, 0, a:context)

inoremap <silent> <expr> <Plug>(insert_ipython_history)
    \ neocomplete#sources#ipython_history#insert()
inoremap <silent> <expr> <Plug>(complete_ipython_history)
    \ neocomplete#start_manual_complete(['ipython_history'])

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
