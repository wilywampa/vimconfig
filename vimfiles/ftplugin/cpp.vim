if exists("b:did_my_ftplugin")
  finish
endif

let b:did_my_ftplugin=1

if exists('$TMUX')
  nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>ExecuteMotion<CR>g@
  nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  vnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>ExecuteMotion('visual')<CR>
  if maparg('<S-F5>', 'n') == ''
    nnoremap <silent> <buffer> <S-F5> :<C-u>call <SID>IncludeFile()<CR>
  endif

  func! s:ExecuteMotion(type)
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxOpenRunner()
    let input = vimtools#opfunc(a:type)
    call VimuxSendKeys("C-e C-u")
    let lines = split(input, "\n")

    " Run as #include temporary file if input contains bracket statements
    " spanning multiple lines
    if len(filter(map(copy(lines), 'split(v:val, "\\zs")'),
        \ 'count(v:val, "{") % 2 == 1 || count(v:val, "}") % 2 == 1')) > 0
      let fname = tempname()
      call writefile(lines, fname)
      call VimuxSendText('#include "'.fname.'"')
    else
      for line in lines[0:-2]
        call VimuxSendText(line)
        call VimuxSendKeys("C-m")
      endfor
      call VimuxSendText(lines[-1])
    endif
    call VimuxSendKeys("C-m")
    silent! call repeat#invalidate()
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:IncludeFile()
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxOpenRunner()
    call VimuxSendKeys("C-e C-u")
    call VimuxSendText('#include "'.expand('%:p').'"')
    call VimuxSendKeys("C-m")
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc
endif

" vim:set et ts=2 sts=2 sw=2:
