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
nnoremap <silent> <buffer> ,pl :<C-u>PymodeLintAuto<CR>
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
  function! s:IPyCheckInit()
    try
      silent python print IPython
    catch
      python km_from_string()
    endtry
    python km_from_string()
  endfunction

  function! s:IPyRunPrompt()
    call <SID>IPyCheckInit()
    let g:ipy_input = input('IPy: ')
    redraw
    python run_ipy_input()
    let g:last_ipy_input = g:ipy_input
    unlet g:ipy_input
  endfunction

  function! s:IPyRepeatCommand()
    call <SID>IPyCheckInit()
    if exists('g:last_ipy_input')
      let g:ipy_input = g:last_ipy_input
      redraw
      python run_ipy_input()
    endif
  endfunction

  function! s:IPyClearWorkspace()
    call <SID>IPyCheckInit()
    let g:ipy_input = 'from plottools import cl; cl()'."\n".'%reset -s -f'
    redraw
    python run_ipy_input()
    unlet g:ipy_input
  endfunction

  function! s:IPyCloseFigures()
    call <SID>IPyCheckInit()
    let g:ipy_input = 'from plottools import cl; cl()'
    redraw
    python run_ipy_input()
    unlet g:ipy_input
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

augroup python_ftplugin
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'python' |
      \     let &filetype = 'python' |
      \     let &l:omnifunc = getbufvar(bufnr('#'), '&l:omnifunc') |
      \ endif
augroup END

" vim:set et ts=2 sts=2 sw=2:
