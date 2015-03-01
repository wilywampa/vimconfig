if exists("b:did_matlab_run")
    finish
endif

let b:did_matlab_run=1

if !exists('g:matlab_path')
  if has("mac")
    let g:matlab_path = expand('~/Documents/MATLAB')
  else
    let g:matlab_path = expand('~/MATLAB')
  endif
endif

if has("win16") || has("win32") || has("win64")

  func! s:RunMATLAB()
    let l:fname=expand('%:p:h').'\RunMATLAB.m'
    let l:cmds=['clear functions']
    let l:cmds=l:cmds+['run '.expand('%:p:t')]
    let l:cmds=l:cmds+['gendict;']
    let l:cmds=l:cmds+['delete '.l:fname]
    let l:cmds=l:cmds+['clear functions']
    call writefile(l:cmds,l:fname)
    exec 'silent !start "'.g:runmatlab_exe.'" "'.l:fname.'"'
  endfunc

  func s:UpdateDictionaryMATLAB()
    exec 'silent !start "'.g:runmatlab_exe.'" "'.g:matlab_path.'\gendict.m"'
    exec 'silent !start "'.g:runmatlab_exe.'" "'.g:matlab_path.'\clearfun.m"'
  endfunc

elseif has('win32unix') || has('win64unix')

  func! s:RunMATLAB()
    let l:fname=expand('%:p:h').'/RunMATLAB.m'
    let l:cmds=['clear functions']
    let l:cmds=l:cmds+[substitute('run '.expand('%:p:t'),'\(^.*\)\.m','\1','')]
    let l:cmds=l:cmds+['gendict;']
    let l:cmds=l:cmds+['clear functions']
    call writefile(l:cmds,l:fname)
    exec 'silent !RunMATLAB `cygpath -w '.l:fname.'`'
    redraw!
  endfunc

  func! s:UpdateDictionaryMATLAB()
    exec 'sil !RunMATLAB "'.g:matlab_path.'\gendict.m"'
    exec 'sil !RunMATLAB "'.g:matlab_path.'\clearfun.m"'
    redraw!
  endfunc

else

  func! s:RunMATLAB()
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText("clearfun; cd ".expand('%:p:h')."; try; "
        \.expand('%:t:r')."; catch ME1; errorfile; end")
    call VimuxSendKeys("\<CR>")
    call VimuxSendText("clear errfid erridx ME1; gendict; clearfun")
    call VimuxSendKeys("\<CR>")
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:RunMotionMATLAB(type)
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxOpenRunner()
    let input = vimtools#opfunc(a:type)
    call VimuxSendKeys("\<C-e>\<C-u>")
    for line in split(input, '\r')
      call VimuxSendText(line)
      call VimuxSendKeys("\<CR>")
    endfor
    silent! call repeat#invalidate()
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:UpdateDictionaryMATLAB()
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText("gendict")
    call VimuxSendKeys("\<CR>")
  endfunc

  func! s:GetHelpMATLAB()
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText('help '.expand('<cword>'))
    call VimuxSendKeys("\<CR>")
    VimuxZoomRunner
  endfunc

  func! s:PrintVarMATLAB()
    call SaveRegs()
    normal! gvy
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText(@")
    call VimuxSendKeys("\<CR>")
    call RestoreRegs()
  endfunc

  func! s:PrintVarInfoMATLAB()
    call SaveRegs()
    normal! gvy
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText("varinfo('".substitute(@","'","''","g")."')")
    call VimuxSendKeys("\<CR>")
    call RestoreRegs()
  endfunc

  func! s:CloseFiguresMATLAB()
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText("close all;")
    call VimuxSendKeys("\<CR>")
  endfunc

  func! s:ClearWorkspaceMATLAB()
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    call VimuxSendText("fclose all; close all; clear all;")
    call VimuxSendKeys("\<CR>")
  endfunc

  func! s:GetErrorMATLAB()
    let errorfile = expand('%:h').'/.matlaberror'
    setlocal errorformat+=Error:\ File:\ %f\ Line:\ %l\ Column:\ %c\ -\ %m
    if filereadable(errorfile)
      cgetexpr readfile(errorfile)
      copen
      for winnr in range(1, winnr('$'))
        if getwinvar(winnr, '&buftype') ==# 'quickfix'
          call setwinvar(winnr, 'quickfix_title', 'MATLAB')
        endif
      endfor
      cfirst
      call system('rm '.errorfile)
    else
      echo 'No error file found'
    endif
  endfunc

  function! s:RunScratchBufferMATLAB()
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxOpenRunner()
    call VimuxSendKeys("\<C-e>\<C-u>")
    for line in range(1, line('$'))
      call VimuxSendText(getline(line))
      call VimuxSendKeys("\<CR>")
    endfor
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunction

  if !exists('*s:ScratchBufferMATLAB')
    function! s:ScratchBufferMATLAB()
      let scratch = bufnr('--MATLAB--')
      if scratch == -1
        enew
        silent file --MATLAB--
      else
        execute "buffer ".scratch
      endif
      set filetype=matlab
      setlocal buftype=nofile bufhidden=hide noswapfile
      nnoremap <buffer> <silent> <F5>      :<C-u>call <SID>RunScratchBufferMATLAB()<CR>
      inoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>RunScratchBufferMATLAB()<CR>
      xnoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>RunScratchBufferMATLAB()<CR>
      map  <buffer> <C-s> <F5>
      map! <buffer> <C-s> <F5>
    endfunction
  endif

  nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>RunMotionMATLAB<CR>g@
  nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>RunMotionMATLAB<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>RunMotionMATLAB<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  vnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>RunMotionMATLAB('visual')<CR>
  nnoremap <silent> <buffer> K :<C-u>call <SID>GetHelpMATLAB()<CR>
  vnoremap <silent> <buffer> <C-p> :<C-u>call <SID>PrintVarMATLAB()<CR>
  vnoremap <silent> <buffer> <M-s> :<C-u>call <SID>PrintVarInfoMATLAB()<CR>
  nnoremap <silent> <buffer> <Leader>e :<C-u>call <SID>GetErrorMATLAB()<CR>
  nnoremap <silent> <buffer> <Leader>cf :<C-u>call <SID>CloseFiguresMATLAB()<CR>
  nnoremap <silent> <buffer> <Leader>cl :<C-u>call <SID>CloseFiguresMATLAB()<CR>
  nnoremap <silent> <buffer> <Leader>cw :<C-u>call <SID>ClearWorkspaceMATLAB()<CR>
  nnoremap <silent>                 ,ms :<C-u>call <SID>ScratchBufferMATLAB()<CR>
endif

nnoremap <silent> <buffer> <F5> :update<CR>:call <SID>RunMATLAB()<CR>
imap     <silent> <buffer> <F5> <Esc><F5>
nnoremap <silent> <buffer> <S-F5> :call <SID>UpdateDictionaryMATLAB()<CR>
imap     <silent> <buffer> <S-F5> <Esc><S-F5>
nnoremap <Plug>(matlab_update_dictionary) :call <SID>UpdateDictionaryMATLAB()<CR>

augroup MATLAB
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'matlab' |
      \     let &filetype = 'matlab' |
      \ endif
augroup END

set omnifunc=matlabcomplete#complete

" vim:set et ts=2 sts=2 sw=2:
