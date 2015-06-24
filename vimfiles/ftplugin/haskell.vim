if exists("b:did_my_ftplugin")
  finish
endif
let b:did_ftplugin = 1
let b:did_my_ftplugin = 1

let s:import_pattern = '^\s*import\s'

func! s:compare(a, b)
  if a:a =~ s:import_pattern
    return -1
  elseif a:b =~ s:import_pattern
    return 1
  endif
  return 0
endfunc

func! s:RunMotionHaskell(type)
  if !exists("g:VimuxRunnerIndex")
    echohl WarningMsg
    echomsg "'g:VimuxRunnerIndex' does not exist"
    echohl None
    return
  endif
  let zoomed = _VimuxTmuxWindowZoomed()
  if zoomed | call system("tmux resize-pane -Z") | endif
  let input = vimtools#opfunc(a:type)
  call VimuxSendKeys("S\<C-e>\<C-u>")
  let lines = filter(split(input, '\n'), 'v:val =~ "\\S"')
  if len(lines) == 0 | return | endif
  call sort(lines, 's:compare')
  while !empty(lines) && lines[0] =~ s:import_pattern
    call VimuxSendText(lines[0])
    call VimuxSendKeys("\<CR>")
    let lines = lines[1:]
  endwhile
  if !empty(lines)
    if input =~ '\v^.*(<let>.*)@<!\zs([=<>/]@<!\=[=<>]@!)'
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
  endif
  silent! call repeat#invalidate()
  if zoomed | call system("tmux resize-pane -Z") | endif
endfunc

func! s:EvalSelection()
  call SaveRegs()
  normal! gvy
  call VimuxSendKeys("\<Esc>S")
  call VimuxSendText(@@)
  call VimuxSendKeys("\<CR>")
  call RestoreRegs()
endfunc

nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>RunMotionHaskell<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>RunMotionHaskell<Bar>exe 'norm! 'v:count1.'g@_'<CR>
xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>RunMotionHaskell('visual')<CR>
inoremap <silent> <buffer> <Leader><Leader>x  <Esc>:<C-u>set opfunc=<SID>RunMotionHaskell<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent> <buffer> <S-F5> :<C-u>call VimuxRunCommand(':load '.fnameescape(expand('%:p')))<CR>
xnoremap <silent> <buffer> <C-p> :<C-u>call <SID>EvalSelection()<CR>
nnoremap <silent> <buffer> K :<C-u>call Haddock()<CR>

let b:ghc_staticoptions = '-ignore-dot-ghci'

let b:exchange_indent = 1

compiler ghc
setlocal omnifunc=necoghc#omnifunc
setlocal iskeyword+='
setlocal comments=s1fl:{-,mb:-,ex:-},:-- commentstring=--%s
setlocal cpoptions+=M

silent! call CountJump#Motion#MakeBracketMotion('<buffer>', '', '',
    \ '^\h\k\+\s*::',
    \ '^\ze.*\n^\h\k\+\s*::', 0)

" vim:set et ts=2 sts=2 sw=2:
