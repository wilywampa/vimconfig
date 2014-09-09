" Delete buffer while keeping window layout (don't close buffer's windows).
" Version 2008-11-18 from http://vim.wikia.com/wiki/VimTip165
if v:version < 700 || exists('loaded_bclose') || &cp
  finish
endif
let loaded_bclose = 1
if !exists('bclose_multiple')
  let bclose_multiple = 1
endif

" Display an error message.
function! s:Warn(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
endfunction

" Command ':Bclose' executes ':bd' to delete buffer in current window.
" The window will show the alternate buffer (Ctrl-^) if it exists,
" or the previous buffer (:bp), or a blank buffer if no previous.
" Command ':Bclose!' is the same, but executes ':bd!' (discard changes).
" An optional argument can specify which buffer to close (name or number).
function! s:Bclose(bang, buffer)
  if empty(a:buffer)
    let btarget = bufnr('%')
  elseif a:buffer =~ '^\d\+$'
    let btarget = bufnr(str2nr(a:buffer))
  else
    let btarget = bufnr(a:buffer)
  endif
  if btarget < 0
    call s:Warn('No matching buffer for '.a:buffer)
    return
  endif
  if empty(a:bang) && getbufvar(btarget, '&modified')
    call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
    return
  endif
  " Numbers of windows that view target buffer which we will delete.
  let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
  if !g:bclose_multiple && len(wnums) > 1
    call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
    return
  endif
  let wcurrent = winnr()
  for w in wnums
    execute w.'wincmd w'
    let prevbuf = bufnr('#')
    if prevbuf > 0 && buflisted(prevbuf)
        \ && getbufvar(bufnr('#'), '&buftype') != 'quickfix'
      buffer #
    else
      silent! bprevious
    endif
    if btarget == bufnr('%')
      " Numbers of listed buffers which are not the target to be deleted.
      let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
      " Listed, not target, and not displayed.
      let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
      " Take the first buffer, if any (could be more intelligent).
      let bjump = (bhidden + blisted + [-1])[0]
      if bjump > 0
        execute 'buffer '.bjump
      else
        execute 'enew'.a:bang
      endif
    endif
  endfor
  if buflisted(btarget)
    if !exists('s:closed_buf_list') | let s:closed_buf_list = [] | endif
    let fname = fnamemodify(bufname(btarget), ':p')
    let index = index(s:closed_buf_list, fname)
    if index >= 0
      silent! call remove(s:closed_buf_list, index)
    endif
    silent! call add(s:closed_buf_list, fname)
    execute 'bdelete'.a:bang.' '.btarget
  endif
  execute wcurrent.'wincmd w'
endfunction
command! -bang -complete=buffer -nargs=? Bclose call s:Bclose('<bang>', '<args>')
nnoremap <silent> <Leader>bd :Bclose<CR>:silent! call repeat#set("\<Leader>bd")<CR>

function! s:Bopen()
  if !exists('s:closed_buf_list') || len(s:closed_buf_list) == 0
    echo 'No closed buffers'
    return
  endif
  for index in range(0, len(s:closed_buf_list) - 1)
    echo len(s:closed_buf_list) - index.' - '.s:closed_buf_list[index]
  endfor
  let choice = len(s:closed_buf_list) - input('Choose file number: ')
  if choice =~ '[0-9]' && matchstr(choice, '\v[0-9]+') < len(s:closed_buf_list)
    if choice =~ '\v^[0-9]+$'
      execute "edit ".s:closed_buf_list[choice]
    elseif choice =~ '\v^[0-9]+s$'
      execute "split ".s:closed_buf_list[choice]
    elseif choice =~ '\v^[0-9]+v$'
      execute "vsplit ".s:closed_buf_list[choice]
    elseif choice =~ '\v^[0-9]+t$'
      execute "tab split ".s:closed_buf_list[choice]
    endif
  endif
endfunction
command! -bang -complete=buffer -nargs=? Bopen call s:Bopen()
nnoremap <silent> <Leader>bo :Bopen<CR>
