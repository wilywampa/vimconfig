" Vim ftplugin file
" Language: Python
" Author: Jacob Niehus

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

func! s:RunPython()
  if !has('gui_running') && !empty($TMUX)
    call VimuxRunCommand('python '.expand('%:p'))
  else
    !python %
  endif
endfunc

setlocal define=^\s*\\(def\\\\|class\\)

noremap  <silent> <buffer> <F5> :up<CR>:<C-u>call <SID>RunPython()<CR>
imap     <silent> <buffer> <F5> <Esc><F5>
nnoremap <silent> <buffer> K :<C-u>execute "!pydoc " . expand("<cword>")<CR>
nnoremap <silent> <buffer> <S-F5> :up<CR>:exe "SyntasticCheck" \| exe "Errors"<CR>
imap     <silent> <buffer> <S-F5> <Esc><S-F5>
nnoremap <silent> <buffer> ,pl :<C-u>PymodeLint<CR>
nnoremap          <buffer> ,ip :<C-u>IPython<CR>

" Move around functions
nnoremap <silent> <buffer> [[ m':call search('^\s*def ', "bW")<CR>
vnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "bW")<CR>
nnoremap <silent> <buffer> ]] m':call search('^\s*def ', "W")<CR>
vnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "W")<CR>

" Enable omni completion
setlocal omnifunc=pythoncomplete#Complete

" Use pymode's fold expression
augroup py_ftplugin
  autocmd!
  autocmd SessionLoadPost <buffer> setlocal foldmethod=expr
      \ foldexpr=pymode#folding#expr(v:lnum) foldtext=pymode#folding#text()
augroup END

if !exists('*<SID>IPyRunPrompt')
  function! s:IPyRunIPyInput()
    try
      silent python print IPython
    catch
      python km_from_string()
    endtry
    python km_from_string()
    redraw
    python run_ipy_input()
    unlet g:ipy_input
  endfunction

  function! s:IPyRunPrompt()
    let g:ipy_input = input('IPy: ')
    let g:last_ipy_input = g:ipy_input
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyRepeatCommand()
    if exists('g:last_ipy_input')
      let g:ipy_input = g:last_ipy_input
      call <SID>IPyRunIPyInput()
    endif
  endfunction

  function! s:IPyClearWorkspace()
    let g:ipy_input = 'from plottools import cl; cl()'."\n".'%reset -s -f'
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyCloseFigures()
    let g:ipy_input = 'from plottools import cl; cl()'
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyPing()
    let g:ipy_input = 'print "pong"'
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyPrintVar()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = 'print '.@"
    call RestoreRegs()
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyVarInfo()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = 'from plottools import varinfo; varinfo('.@".')'
    call RestoreRegs()
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyRunMotion(type)
    let g:ipy_input = s:opfunc(a:type)
    if matchstr(g:ipy_input, '[[:print:]]\ze[^[:print:]]*$') == '?'
      call setpos('.', getpos("']"))
      python run_this_line(False)
    else
      call <SID>IPyRunIPyInput()
    endif
  endfunction

  function! s:IPyRunScratchBuffer()
    let view = winsaveview()
    call SaveRegs()
    normal! gg0vG$y
    let g:ipy_input = @@
    call RestoreRegs()
    call winrestview(view)
    call <SID>IPyRunIPyInput()
  endfunction

  function! s:IPyScratchBuffer()
    let scratch = bufnr('--Python--')
    if scratch == -1
      enew
      set filetype=python
      IPython
      setlocal buftype=nofile bufhidden=hide noswapfile
      file --Python--
    else
      execute "buffer ".scratch
    endif
    nnoremap <buffer> <silent> <F5>      :<C-u>call <SID>IPyRunScratchBuffer()<CR>
    inoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
    xnoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
    map  <buffer> <C-s> <F5>
    map! <buffer> <C-s> <F5>
  endfunction
endif

nnoremap <silent> <buffer> <Leader>: :<C-u>call <SID>IPyRunPrompt()<CR>
nnoremap <silent> <buffer> @\  :<C-u>call <SID>IPyRepeatCommand()<CR>
nnoremap <silent> <buffer> @\| :<C-u>call <SID>IPyRepeatCommand()<CR>
nnoremap <silent> <buffer> g\  :<C-u>call <SID>IPyRunPrompt()<CR><C-f>
nnoremap <silent> <buffer> g\| :<C-u>call <SID>IPyRunPrompt()<CR><C-f>
nnoremap <silent> <buffer> <Leader>cw :<C-u>call <SID>IPyClearWorkspace()<CR>
nnoremap <silent> <buffer> <Leader>cl :<C-u>call <SID>IPyCloseFigures()<CR>
nnoremap <silent> <buffer> <Leader>cf :<C-u>call <SID>IPyCloseFigures()<CR>
nnoremap <silent>          ,pp :<C-u>call <SID>IPyPing()<CR>
xnoremap <silent> <buffer> <C-p> :<C-u>call <SID>IPyPrintVar()<CR>
xnoremap <silent> <buffer> <M-s> :<C-u>call <SID>IPyVarInfo()<CR>
nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>IPyRunMotion<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent>          ,ps :<C-u>call <SID>IPyScratchBuffer()<CR>

augroup python_ftplugin
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'python' |
      \     let &filetype = 'python' |
      \     let &l:omnifunc = getbufvar(bufnr('#'), '&l:omnifunc') |
      \ endif
augroup END

function! s:opfunc(type) abort
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    if a:type =~ '^\d\+$'
      silent exe 'normal! ^v'.a:type.'$hy'
    elseif a:type =~# '^.$'
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type ==# 'line'
      silent exe "normal! '[V']y"
    elseif a:type ==# 'block'
      silent exe "normal! `[\<C-V>`]y"
    else
      silent exe "normal! `[v`]y"
    endif
    redraw
    return @@
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
  endtry
endfunction

" vim:set et ts=2 sts=2 sw=2:
