if exists("g:loaded_ipython_scratch") || &compatible || !(has('python') || has('python3'))
  finish
endif
let g:loaded_ipython_scratch = 1

let s:scratch_name = '--Python--'
let g:ipython_scratch_motion = get(g:, 'ipython_scratch_motion', 'yap')

function! s:UncommentLine(line)
  try
    if a:line !~ '^\s*#'
      return a:line
    elseif a:line =~ '\v^\s*##%(\s|$)'
      return substitute(a:line, '\v^\s*\zs##%(\s|$)', '', '')
    elseif a:line =~ '\v^\s*#\s+[!%]'
      return substitute(a:line, '\v^(\s*)# ([%!])', '\1\2', '')
    elseif a:line =~ '\v^\s*# (\h\w*,?\s*)+\s*\=\s*[!%]'
      return substitute(a:line, '\v^(\s*)# ((\h\w*,?\s*)+)\s*\=', '\1\2=', '')
    endif
  catch
  endtry
  return a:line
endfunction

function! UncommentMagics(input)
  return join(map(split(a:input, '\n'), 's:UncommentLine(v:val)'), "\n")
endfunction

function! s:BackupScratchBuffer() abort
  let scratch = bufnr(s:scratch_name)
  if scratch == -1 | return | endif
  execute "buffer ".scratch
  let dir = $HOME . '/.cache/IPython/buffer/'
  if !isdirectory(dir) | call mkdir(dir) | endif
  let fname = dir . strftime('%Y_%m_%d_%H00%Z.py')
  call writefile(getbufline(scratch, 1, line('$')), fname)
  execute 'wundo' undofile(fname)
  echomsg 'Wrote to ' . fname
endfunction

function! s:RestoreScratchBuffer(...) abort
  call s:IPyScratchBuffer()
  let sep = !exists('+shellslash') || &shellslash ? '/' : '\\'
  let dir = substitute($HOME . '/.cache/IPython/buffer/', '/', sep, 'g')
  let fname = a:0 ? a:1 :
      \ filter(split(glob(dir . '*.py'), "\n"),
      \       'filereadable(undofile(v:val))')[-v:count1]
  normal! gg"_dG
  put = readfile(fname)
  normal! gg"_dd
  silent execute 'rundo' undofile(fname)
  execute "normal! u\<C-r>"
endfunction

function! s:IPyRunScratchBuffer()
  let view = winsaveview()
  call SaveRegs()
  let left_save = getpos("'<")
  let right_save = getpos("'>")
  let vimode = visualmode()
  execute "normal! " . g:ipython_scratch_motion
  let g:ipy_input = UncommentMagics(@@)
  call RestoreRegs()
  execute "normal! " . vimode . "\<Esc>"
  call setpos("'<", left_save)
  call setpos("'>", right_save)
  call winrestview(view)
  call IPyRunIPyInput()
endfunction

" Add '## ' escape to magic lines automatically
function! s:CommentMagic() abort
  if getline('.') =~ '\v^\s*(# )?##|^\s*$'
    return
  elseif string(map(synstack(line('.'),
      \ strlen(substitute(getline('.'), '\v^.{-}[!%]\zs.*$', '', ''))),
      \ 'synIDattr(v:val, "name")')) !~? '\vmagic(bang|pct)|cythonMagic|shellMagic'
    return
  endif
  let pos = getpos('.')
  try
    call setline(line('.'), '## ' . getline('.'))
    let pos[2] += 3
  finally
    call setpos('.', pos)
  endtry
endfunction

function! s:IPyScratchBuffer()
  let scratch = bufnr(s:scratch_name)
  if scratch == -1
    enew
  else
    execute "buffer ".scratch
  endif
  if &filetype !=# 'python'
    setfiletype python
    IPythonConsole
  endif
  if line('$') == 1 && getline(1) ==# ''
    silent put! = ['# pylama: ignore=C9,E2,E3,E5,E7,W0,W2,W3',
        \          'from IPython import get_ipython',
        \          'ip = get_ipython()']
    keepjumps normal! G
  endif
  silent execute 'file' fnameescape(s:scratch_name)
  setfiletype python
  setlocal buftype=nowrite bufhidden=hide noswapfile
  setlocal omnifunc=CompleteIPython
  setlocal foldmethod=manual foldexpr=
  let b:ipython_user_ns = 1
  nnoremap <buffer> <silent> <F5>      :<C-u>call <SID>IPyRunScratchBuffer()<CR>
  inoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
  xnoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
  nnoremap <buffer> <silent> <CR>   vip:<C-u>call IPyEval(3)<CR>
  nnoremap <buffer> <silent> ,S        :<C-u>call <SID>BackupScratchBuffer()<CR>
  nnoremap <buffer> <silent> ,R        :<C-u>call <SID>RestoreScratchBuffer()<CR>
  map  <buffer> <C-s> <F5>
  map! <buffer> <C-s> <F5>
  augroup ipython_scratch_buffer
    autocmd!
    autocmd TextChangedI <buffer> call s:CommentMagic()
    autocmd VimLeavePre * silent call s:BackupScratchBuffer()
  augroup END
endfunction

augroup ipython_scratch_bufread
  autocmd!
  execute 'autocmd BufReadCmd ' . s:scratch_name . ' call s:RestoreScratchBuffer()'
augroup END

nnoremap <silent> ,ps :<C-u>call <SID>IPyScratchBuffer()<CR>

" vim:set et ts=2 sts=2 sw=2:
