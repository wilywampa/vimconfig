if exists("b:did_my_ftplugin")
  finish
endif

if !exists('g:c_execute_prefix')
  let g:c_execute_prefix = ''
endif

let b:did_my_ftplugin=1

if executable('astyle')
  if has("python") || has('python3')
    setlocal formatexpr=FormatArtisticStyle()
  else
    setlocal formatprg=astyle
  endif
endif

if has('python3') && get(g:, 'pymode_python', '') !=# 'python'
  command! -nargs=1 Python2or3 python3 <args>
else
  command! -nargs=1 Python2or3 python <args>
endif

if has("python") || has('python3')
  function! FormatArtisticStyle() abort " {{{
    if !empty(v:char)
      return 1
    else
            Python2or3 << EOF
import subprocess
import sys
import vim
from subprocess import PIPE

PY3 = sys.version_info[0] == 3
string_type = str if PY3 else basestring

lnum, count = vim.vvars['lnum'] - 1, vim.vvars['count']
lines = '\n'.join(vim.current.buffer[lnum:lnum+count])
args = vim.vars.get('astyle_args', '')
args = args.split() if isinstance(args, string_type) else list(args)

p = subprocess.Popen(['astyle'] + args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
new_lines, err = p.communicate(lines.encode('utf-8') if PY3 else lines)

if PY3:
    new_lines = str(new_lines, 'utf-8')
    err = str(err, 'utf-8')

if err:
    vim.command('echomsg "%s"' % str(err.strip()))
elif new_lines != lines:
    vim.current.buffer[lnum:lnum+count] = new_lines.splitlines()
EOF
    endif
  endfunction " }}}
endif

if exists('$TMUX')
  nnoremap <silent> <buffer> <Leader>x :<C-u>let g:first_op=1<bar>set opfunc=<SID>ExecuteMotion<CR>g@
  nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>ExecuteMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
  xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>ExecuteMotion('visual')<CR>
  xnoremap <silent> <buffer> <C-p> :<C-u>call <SID>EvalSelection()<CR>
  if maparg('<S-F5>', 'n') == ''
    nnoremap <silent> <buffer> <S-F5> :<C-u>call <SID>IncludeFile()<CR>
  endif

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
        call VimuxSendText(g:c_execute_prefix . line)
        call VimuxSendKeys("C-m")
      endfor
      call VimuxSendText(g:c_execute_prefix . lines[-1])
    endif
    call VimuxSendKeys("C-m")
    silent! call repeat#invalidate()
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:IncludeFile()
    if !exists("g:VimuxRunnerIndex")
      echohl WarningMsg
      echomsg "'g:VimuxRunnerIndex' does not exist"
      echohl None
      return
    endif
    let zoomed = _VimuxTmuxWindowZoomed()
    if zoomed | call system("tmux resize-pane -Z") | endif
    call VimuxSendKeys("C-e C-u")
    call VimuxSendText('#include "'.expand('%:p').'"')
    call VimuxSendKeys("C-m")
    if zoomed | call system("tmux resize-pane -Z") | endif
  endfunc

  func! s:EvalSelection()
    call SaveRegs()
    normal! gvy
    call VimuxRunCommand(g:c_execute_prefix . @@)
    call RestoreRegs()
  endfunc
endif

" vim:set et ts=2 sts=2 sw=2:
