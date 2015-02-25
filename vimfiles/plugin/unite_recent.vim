if exists('g:loaded_unite_recent')
  finish
endif
let g:loaded_unite_recent = 1

if !exists('s:win_id')
  let s:win_id = 0
endif

" Create list of recent buffers for each window
augroup unite_recent
  autocmd!
  autocmd WinEnter * if !exists('w:unite_recent') | call s:new_window() | endif
  autocmd BufWinEnter,BufEnter * call s:append(expand('<abuf>'))
augroup END

function! s:new_window()
  let w:unite_recent = copy(getwinvar(winnr('#'), 'unite_recent', {'id': s:win_id}))
  let w:unite_recent['id'] = s:win_id
  let s:win_id += 1
  call s:append(winbufnr(winnr()))
endfunction

function! s:append(bufnr)
  if !exists('w:unite_recent')
    call s:new_window()
  endif
  let w:unite_recent[a:bufnr] = localtime()
endfunction

function! s:compare(a, b)
  " Current buffer goes to end of list
  if a:a['action__buffer_nr'] == winbufnr(winnr())
    return 1
  endif
  if a:b['action__buffer_nr'] == winbufnr(winnr())
    return -1
  endif
  let has_a = has_key(w:unite_recent, a:a['action__buffer_nr'])
  let has_b = has_key(w:unite_recent, a:b['action__buffer_nr'])

  " Prioritize buffers by when they were last seen in the current window
  if has_a && has_b
    return w:unite_recent[a:b['action__buffer_nr']]
        \ -w:unite_recent[a:a['action__buffer_nr']]
  elseif has_a
    return -1
  elseif has_b
    return 1
  else
    return a:a.source__time - a:b.source__time
  endif
endfunction

function! _PrintBufList()
  let buflist = s:get_buflist()
  for buf in buflist
    echomsg bufname(buf['action__buffer_nr'] + 0)
  endfor
endfunction

function! s:get_buflist()
  let buflist = unite#sources#buffer#get_unite_buffer_list()
  call sort(buflist, 's:compare')
  return buflist
endfunction

" Use Unite's MRU list for alternate buffer key
function! UniteAlternateBuffer(count)
  let buf = bufnr('%')
  if !exists(':Unite') || (a:count == 1 && buflisted(bufnr('#')) && bufnr('#') != bufnr('%'))
    try | execute "normal! \<C-^>" | catch | endtry
  else
    let buflist = s:get_buflist()
    if exists('buflist['.(a:count-1).']')
      execute "buffer ".buflist[(a:count-1)]['action__buffer_nr']
    elseif exists("buflist[-2]")
      execute "buffer ".buflist[-2]['action__buffer_nr']
    else
      execute "normal! \<C-^>"
    endif
  endif
  execute "normal! zv"
  if bufnr('%') == buf | echo "No alternate buffer" | endif
endfunction
nnoremap <silent> <C-^> :<C-u>call UniteAlternateBuffer(v:count1)<CR>

" Cycle through Unite's MRU list
function! s:UniteBufferCycle(resume)
  if a:resume && !exists('s:buflist')
    call feedkeys("\<C-^>") | return
  endif
  let s:UBCActive = 1
  if !a:resume
    let s:buflist = s:get_buflist()
    let s:bufnr = -2
    let s:startbuf = bufnr('%')
    let s:startaltbuf = bufnr('#')
    if len(s:buflist) <= 1
      let s:UBCActive = 0
      return
    endif
  endif
  let s:key = '['
  while s:key == '[' || s:key == ']'
    if s:bufnr == -2
      let s:key = ']'
      let s:bufnr = -1
    endif
    let s:bufnr = s:bufnr + (s:key == ']' ? 1 : -1)
    if s:bufnr >= -1 && s:bufnr < len(s:buflist) - 1
      execute "buffer ".s:buflist[s:bufnr]['action__buffer_nr']
      redraw
      let s = ''
      if s:bufnr >= 0
        let s .= 'Previous: "'.fnamemodify(bufname(
            \ s:buflist[s:bufnr-1]['action__buffer_nr']), ':t').'" '
      endif
      if s:bufnr < len(s:buflist) - 2
        let s .= 'Next: "'.fnamemodify(bufname(
            \ s:buflist[s:bufnr+1]['action__buffer_nr']), ':t').'"'
      endif
      echo s
    else
      let s:bufnr = s:bufnr - (s:key == ']' ? 1 : -1)
    endif
    let s:key = nr2char(getchar())
  endwhile
  let s:UBCActive = 0
  if index(['q', 'Q', "\<C-c>", "\<CR>", "\<Esc>"], s:key) < 0
    call feedkeys(s:key)
  endif
  if bufnr('%') != s:startbuf
    execute "buffer ".s:startbuf
  else
    execute "buffer ".s:startaltbuf
  endif
  buffer #
endfunction
nnoremap <silent> ]r :<C-u>call <SID>UniteBufferCycle(0)<CR>
nnoremap <silent> [r :<C-u>call <SID>UniteBufferCycle(1)<CR>
let s:UBCActive = 0
autocmd unite_recent BufEnter * if !s:UBCActive && exists('s:buflist') | unlet s:buflist | endif

" vim:set et ts=2 sts=2 sw=2:
