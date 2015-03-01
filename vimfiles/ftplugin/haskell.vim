if exists("b:did_my_ftplugin")
  finish
endif
let b:did_ftplugin = 1
let b:did_my_ftplugin = 1

func! s:RunMotionHaskell(type)
  let zoomed = _VimuxTmuxWindowZoomed()
  if zoomed | call system("tmux resize-pane -Z") | endif
  call VimuxOpenRunner()
  let input = vimtools#opfunc(a:type)
  call VimuxSendKeys("\<Esc>S")
  let lines = filter(split(input, '\n'), 'v:val =~ "\\S"')
  if len(lines) == 0 | return | endif
  if input =~ '\v\=@<!\=\=@!'
    let lines[0] = 'let '.lines[0]
    for lnum in range(1, len(lines) - 1)
      let lines[lnum] = '    '.lines[lnum]
    endfor
  endif
  if len(lines) > 1
    call VimuxSendKeys(":{\<CR>")
    for line in lines
      call VimuxSendText(line)
      call VimuxSendKeys("\<CR>")
    endfor
    call VimuxSendKeys(":}\<CR>\<CR>")
  else
    call VimuxSendText(lines[0])
    call VimuxSendKeys("\<CR>\<CR>")
  endif
  silent! call repeat#invalidate()
  if zoomed | call system("tmux resize-pane -Z") | endif
endfunc

nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>RunMotionHaskell<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>RunMotionHaskell<Bar>exe 'norm! 'v:count1.'g@_'<CR>
xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>RunMotionHaskell('visual')<CR>
inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>RunMotionHaskell<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent> <buffer> <S-F5> :<C-u>call VimuxRunCommand(':load '.fnameescape(expand('%:p')))<CR>

let b:ghc_staticoptions = '-ignore-dot-ghci'

compiler ghc
setlocal omnifunc=necoghc#omnifunc
setlocal iskeyword+='
setlocal comments=s1fl:{-,mb:-,ex:-},:-- commentstring=--%s

if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.haskell =
    \ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*\|^\s*import\s\+\(qualified\s\+\)\?q\@!\w*'

" vim:set et ts=2 sts=2 sw=2:
