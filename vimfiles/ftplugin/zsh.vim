if exists("b:did_my_ftplugin")
  finish
endif

let b:did_my_ftplugin=1

if exists('$TMUX')
  nnoremap <silent> <buffer> <Leader>x :<C-u>let g:first_op=1<bar>set opfunc=<SID>ExecuteMotion<CR>g@
  nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>ExecuteMotion('visual')<CR>
  xnoremap <silent> <buffer> <C-p> :<C-u>call <SID>EvalSelection()<CR>

  func! s:ExecuteMotion(type)
    if !exists("g:VimuxRunnerIndex")
      echohl WarningMsg
      echomsg "'g:VimuxRunnerIndex' does not exist"
      echohl None
      return
    endif
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    let input = vimtools#opfunc(a:type)
    call VimuxSendKeys("S q C-u")
    let lines = split(input, "\n")
    for line in lines[0:-2]
      call VimuxSendText(line)
      call VimuxSendKeys("C-j")
    endfor
    call VimuxSendText(lines[-1])
    call VimuxSendKeys("\<CR>")
    silent! call repeat#invalidate()
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:EvalSelection()
    call SaveRegs()
    normal! gvy
    if @@[0] == '$' || @@[0] == '"' || @@[0] == "'"
      call VimuxRunCommand('echo ' . @@)
    elseif @@ =~ '"'
      call VimuxRunCommand("echo '" . substitute(@@, "'", "''", '') . "'")
    elseif @@[0] == '[' && @@[len(@@)-1] == ']'
      call VimuxRunCommand(@@ . ' TEST')
    else
      call VimuxRunCommand('echo "${' . @@ . '}"')
    endif
    call RestoreRegs()
  endfunc
endif

" vim:set et ts=2 sts=2 sw=2:
