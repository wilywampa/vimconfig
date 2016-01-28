" Vim ftplugin file
" Language: Python
" Author: Jacob Niehus

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

" Detect Cython syntax
if index(['pxd', 'pxi', 'pyx', 'pyxbld'], expand('%:e')) != -1
  augroup cython_syntax
    autocmd!
    autocmd BufEnter <buffer> set syntax=cython | autocmd! cython_syntax
  augroup END
endif

func! s:RunPython()
  if !has('gui_running') && !empty($TMUX)
    if !exists("g:VimuxRunnerIndex")
      echohl WarningMsg
      echomsg "'g:VimuxRunnerIndex' does not exist"
      echohl None
    else
      call VimuxRunCommand('python '.expand('%:p'))
    endif
  else
    !python %
  endif
endfunc

setlocal define=^\s*\\(def\\\\|class\\)

" Highlight docstrings as comments
highlight! def link pythonDocstring Comment

" Highlight embedded sh statements as identifiers
highlight! def link shStatement Identifier

noremap  <silent> <buffer> <F5> :up<CR>:<C-u>call <SID>RunPython()<CR>
imap     <silent> <buffer> <F5> <Esc><F5>
nnoremap <silent> <buffer> K :<C-u>execute "!pydoc " . expand("<cword>")<CR>
nnoremap <silent> <buffer> <S-F5> :up<CR>:!python %<CR>
imap     <silent> <buffer> <S-F5> <Esc><S-F5>
nnoremap <silent> <buffer> ,pl :<C-u>PymodeLint<CR>
nnoremap <silent> <buffer> ,pm :<C-u>call FixMagicSyntax()<CR>
nnoremap <silent> <buffer> ,pi :<C-u>call FixImports()<CR>
nnoremap <silent> <buffer> ,ii :<C-u>call <SID>FixImportsInDef(0)<CR>
xnoremap <silent> <buffer> ,ii :<C-u>call <SID>FixImportsInDef(1)<CR>
nnoremap          <buffer> ,ip :<C-u>IPythonConsole<CR>

" Move around functions
nnoremap <silent> <buffer> [[ m':call search('^\s*def ', "bW")<CR>
xnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "bW")<CR>
nnoremap <silent> <buffer> ]] m':call search('^\s*def ', "W")<CR>
xnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "W")<CR>

" Unite IPython history maps
nnoremap <silent> <buffer> ,h :<C-u>Unite history/ipython -max-multi-lines=100 -no-split -no-resize<CR>
nnoremap <silent> <buffer> ,H :<C-u>Unite history/ipython:import -max-multi-lines=100 -no-split -no-resize<CR>

" Maps for debugging
nnoremap <silent> <buffer> <M-b> :<C-u>call VimuxRunCommand("break ".expand('%:p').":".line('.'))<CR>
nnoremap <silent> <buffer> <M-B> :<C-u>call VimuxRunCommand("break ".expand('%:p').":".line('.').', '.input('condition: '))<CR>
nnoremap <silent> <buffer> <M-e> :<C-u>call VimuxRunCommand("clear ".expand('%:p').":".line('.'))<CR>
nnoremap <silent> <buffer> <Leader>bc :<C-u>call VimuxRunCommand('clear')<bar>call VimuxRunCommand('y')<CR>

function! s:ipdb_commands()
  let lines = []
  let c = input('ipdb> commands ')
  call add(lines, 'commands ' . c)
  silent call VimuxRunCommand(lines[0])
  let input = ''
  while lines[-1] !=# 'end'
    redraw
    echo 'ipdb> commands ' . c
    for line in lines[1:]
      echo '(com) ' . line
    endfor
    call add(lines, input('(com) '))
    silent call VimuxRunCommand(lines[-1])
  endwhile
endfunction
nnoremap <silent> <buffer> g<M-b> :<C-u>call <SID>ipdb_commands()<CR>

" Enable omni completion
setlocal omnifunc=pythoncomplete#Complete

" Use pymode's fold expression
augroup py_ftplugin
  autocmd!
  autocmd SessionLoadPost <buffer> setlocal foldmethod=expr
      \ foldexpr=pymode#folding#expr(v:lnum) foldtext=pymode#folding#text()
augroup END

inoremap <expr> <buffer> @
    \ getline('.')[:col('.')-1] =~ '^\s*$' ? '@' :
    \ (getline('.')[:col('.')-1] =~# 'lambda\s*$' ? repeat('<BS>', 7) . '@' : 'lambda ')

let s:errorformat  = '%+GTraceback%.%#,'
let s:errorformat .= '%E  File "%f"\, line %l\,%m%\C,'
let s:errorformat .= '%E  File "%f"\, line %l%\C,'
let s:errorformat .= '%C%p^,'
let s:errorformat .= '%+C    %.%#,'
let s:errorformat .= '%+C  %.%#,'
let s:errorformat .= '%Z%\S%\&%m,'
let s:errorformat .= '%-G%.%#'

let s:scratch_name = '--Python--'

if has('python3') && get(g:, 'pymode_python', '') !=# 'python'
  command! -nargs=1 Python2or3 python3 <args>
  function! s:pyeval(arg) abort " {{{
    return py3eval(a:arg)
  endfunction " }}}
  let s:pyfile = 'py3file'
else
  command! -nargs=1 Python2or3 python <args>
  function! s:pyeval(arg) abort " {{{
    return pyeval(a:arg)
  endfunction " }}}
  let s:pyfile = 'pyfile'
endif
let s:script_dir = escape(expand('<sfile>:p:h' ), '\')
let s:python_script_dir = s:script_dir . '/python'

if has('python') || has('python3')
Python2or3 << EOF
import vim
import sys

SCRIPT_DIR = vim.eval('s:python_script_dir')
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from vim_utils import Options, PEP8, get_ipython_file, select_docstring
EOF
command! IPythonConsole execute 'IPython ' . s:pyeval('get_ipython_file()')
endif

if !exists('*s:IPyRunPrompt') && (has('python') || has('python3'))
  function! IPyRunIPyInput(...)
    if exists('b:did_ipython') || get(g:, 'ipython_connected', 0)
      redraw
      " Dedent text in case first non-blank line is indented
Python2or3 << EOF
import textwrap
import vim
ipy_input = vim.vars['ipy_input']
if not isinstance(ipy_input, str):
    ipy_input = str(ipy_input, vim.eval('&encoding') or 'utf-8')
vim.vars['ipy_input'] = textwrap.dedent(ipy_input).strip()
EOF
      let silent = a:0 ? 1 : 0
      Python2or3 run_ipy_input(int(vim.eval('silent')))
      unlet g:ipy_input
    else
      echo 'Not connected to IPython'
    endif
  endfunction

  function! s:IPyRunPrompt()
    let g:ipy_input = input('IPy: ', '', 'customlist,vimtools#CmdlineComplete')
    if len(g:ipy_input)
      let g:last_ipy_input = g:ipy_input
      call IPyRunIPyInput()
    else
      unlet g:ipy_input
    endif
  endfunction

  function! s:IPyRepeatCommand()
    if exists('g:last_ipy_input')
      let g:ipy_input = g:last_ipy_input
      call IPyRunIPyInput()
    endif
  endfunction

  function! s:IPyClearWorkspace()
    let g:ipy_input = 'plt.close("all")'."\n".'%reset -s -f'
    let g:ipy_input .= "\n".'from PyQt4 import QtCore; QtCore.QCoreApplication.instance().closeAllWindows()'
    call IPyRunIPyInput()
  endfunction

  function! s:IPyCloseWindows()
    let g:ipy_input = 'from PyQt4 import QtCore; QtCore.QCoreApplication.instance().closeAllWindows()'
    call IPyRunIPyInput()
  endfunction

  function! s:IPyCloseFigures()
    let g:ipy_input = 'plt.close("all")'
    call IPyRunIPyInput()
  endfunction

  function! s:IPyPrintVar()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = @"
    call RestoreRegs()
    call IPyRunIPyInput()
  endfunction

  function! s:IPyVarInfo(...)
    if a:0 > 0
      let input = expand('<cword>')
    else
      call SaveRegs()
      normal! gvy
      let input = @"
      call RestoreRegs()
    endif
    let g:ipy_input = 'from plottools import varinfo; varinfo('.input.')'
    let history = get(g:, 'ipython_store_history', 1)
    let g:ipython_store_history = 0
    call IPyRunIPyInput()
    let g:ipython_store_history = history
  endfunction

  function! s:IPyGetHelp(level)
    call SaveRegs()
    normal! gvy
    let g:ipy_input = substitute(@" . a:level, '^\s*##\?\s*', '', '')
    call RestoreRegs()
    call IPyRunIPyInput()
  endfunction

  function! s:IPyPPmotion(type)
    let g:first_op = 0
    let g:repeat_op = &opfunc
    let input = vimtools#opfunc(a:type)
    call VimuxRunCommand('pp ' . input)
    silent! call repeat#invalidate()
  endfunction

  function! s:IPyRunMotion(type)
    let g:first_op = 0
    let g:repeat_op = &opfunc
    let input = vimtools#opfunc(a:type)
    if exists('b:did_ipython')
      let g:ipy_input = input
      if &buftype == ''
        let g:ipy_input = substitute(g:ipy_input,
            \ '\v["'']@<!__file__["'']@!',
            \ "r'".escape(expand('%:p'), "'")."'", 'g')
      endif
      let g:ipy_input = s:UncommentMagics(g:ipy_input)
      call IPyRunIPyInput()
    else
      let zoomed = _VimuxTmuxWindowZoomed()
      if zoomed | call system("tmux resize-pane -Z") | endif
      call VimuxSendKeys("q C-u")
      for line in split(input, '\n')
        if line =~ '\S'
          if line =~ '^\s*@'
            call VimuxSendKeys("\<CR>")
          endif
          call VimuxSendText(line)
          call VimuxSendKeys("\<CR>")
          " Whole function definition on single line
          if line =~ '^\s*def.*:\s*\S'
            call VimuxSendKeys("\<CR>")
          endif
        endif
      endfor
      call VimuxSendKeys("\<CR>")
      if zoomed | call system("tmux resize-pane -Z") | endif
    endif
    silent! call repeat#invalidate()
  endfunction

  function! s:IPyQuickFix()
    let errorfile = expand('~/.pyerr')
    if filereadable(errorfile)
      let l:errorformat = &errorformat
      try
        let pyerr = join(filter(readfile(errorfile), 'v:val !~ "^\s*$"'), "\n")
        if pyerr =~ 'ipython-input'
          let pyerr = substitute(pyerr, '\v\cFile "\<ipython-input\S*\>", '.
              \ 'line \zs\d+', '\=submatch(0) + line("''[") - 1', 'g')
          let pyerr = substitute(pyerr, '\v\cFile "\zs\<ipython-input\S*\>\ze",',
              \ expand('%:p'), 'g')
        endif
        let &errorformat = s:errorformat
        cgetexpr(pyerr)
        if stridx(pyerr, s:scratch_name) != -1
          let qflist = getqflist()
          for item in qflist
            if stridx(bufname(item.bufnr), s:scratch_name) != -1
              if item.bufnr != bufnr(s:scratch_name)
                if item.bufnr > 0
                  execute "bwipe ".item.bufnr
                endif
                let item.bufnr = bufnr(s:scratch_name)
              endif
              break
            endif
          endfor
          call setqflist(qflist)
        endif
        copen
        for winnr in range(1, winnr('$'))
          if getwinvar(winnr, '&buftype') ==# 'quickfix'
            call setwinvar(winnr, 'quickfix_title', 'Python')
          endif
        endfor
        try
          " Go to last error in a listed buffer
          let listed = reverse(map(getqflist(),
              \ "v:val['bufnr'] > 0 && buflisted(v:val['bufnr'])"))
          if &filetype ==# 'qf' | wincmd p | endif
          execute "cc ".(len(listed) - index(listed, 1))
        catch
          cfirst
        endtry
      finally
        let &errorformat = l:errorformat
      endtry
    else
      echo 'No error file found'
    endif
  endfunction

  function! s:IPyEval(mode)
    " mode 0 = copy to clipboard
    " mode 1 = replace visual selection
    " mode 2 = expression register-like
    " mode 3 = paste below visual selection
    call SaveRegs()
    try
      if a:mode != 2
        normal! gvy
        let g:ipy_input = @@
      else
        let g:ipy_input = input('>>> ', '', 'customlist,vimtools#CmdlineComplete')
      endif
      if a:mode == 0
        Python2or3 eval_ipy_input()
      else
        silent! unlet g:ipy_result
        Python2or3 eval_ipy_input('g:ipy_result')
        if !exists('g:ipy_result') || empty(g:ipy_result)
          return ''
        endif
        let mark = a:mode != 2 ? '.' : "'<"
        let after = strchars(getline(mark)[col(mark)-1:])
        let before = strchars(getline(mark)[:col(mark)-1]) - (after ? 1 : 0)
        let lines = split(g:ipy_result, '\n')
        let first = lines[0]
        call map(lines, '"' . repeat(' ', before) . '" . v:val')
        let lines[0] = first
        let g:ipy_result = join(lines, "\n")
      endif
      if a:mode == 2
        if g:ipy_result =~ "\<NL>"
          set paste
          set pastetoggle=<F10>
          return "\<C-r>=g:ipy_result\<CR>\<F10>" . (g:ipy_result =~ "\<NL>$" ? "\<BS>" : "")
        endif
        return "\<C-r>=g:ipy_result\<CR>"
      elseif a:mode == 1
        call setreg(v:register, g:ipy_result)
        normal! gvp
      elseif a:mode == 3
        call s:WriteScratch(g:ipy_input)
        normal! `>
        put = g:ipy_result
      endif
    finally
      if a:mode != 0
        call RestoreRegs()
      else
        echohl Question | echo 'Yanked:' | echohl Normal
        echo @@
      endif
    endtry
  endfunction

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

  function! s:UncommentMagics(input)
    return join(map(split(a:input, '\n'), 's:UncommentLine(v:val)'), "\n")
  endfunction

  function! s:WriteScratch(text) abort " {{{
    let dir = $HOME . '/.cache/IPython'
    if !isdirectory(dir) | call mkdir(dir) | endif
    call writefile(split(a:text . "\n", '\n'), dir .
        \ strftime('/scratch_%Y_%m_%d.py'), 'a')
  endfunction " }}}

  function! s:IPyRunScratchBuffer()
    let view = winsaveview()
    call SaveRegs()
    let left_save = getpos("'<")
    let right_save = getpos("'>")
    let vimode = visualmode()
    execute "normal! " . get(g:, 'ipython_scratch_motion', 'yap')
    call s:WriteScratch(@@)
    let g:ipy_input = s:UncommentMagics(@@)
    call RestoreRegs()
    execute "normal! " . vimode . "\<Esc>"
    call setpos("'<", left_save)
    call setpos("'>", right_save)
    call winrestview(view)
    call IPyRunIPyInput()
  endfunction

  function! s:IPyScratchBuffer()
    let scratch = bufnr(s:scratch_name)
    if scratch == -1
      enew
      IPythonConsole
    else
      execute "buffer ".scratch
    endif
    if line('$') == 1 && getline(1) ==# ''
      silent put! = ['# pylama: ignore=C9,E2,E3,E5,E7,W0,W2,W3',
          \          'from IPython import get_ipython',
          \          'ip = get_ipython()']
      keepjumps normal! G
    endif
    silent execute 'file' fnameescape(s:scratch_name)
    setfiletype python
    setlocal buftype=nofile bufhidden=hide noswapfile
    setlocal omnifunc=CompleteIPython
    setlocal foldmethod=manual foldexpr=
    let b:ipython_user_ns = 1
    nnoremap <buffer> <silent> <F5>      :<C-u>call <SID>IPyRunScratchBuffer()<CR>
    inoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
    xnoremap <buffer> <silent> <F5> <Esc>:<C-u>call <SID>IPyRunScratchBuffer()<CR>
    nnoremap <buffer> <silent> <CR>   vip:<C-u>call <SID>IPyEval(3)<CR>
    map  <buffer> <C-s> <F5>
    map! <buffer> <C-s> <F5>
    augroup python_ftplugin_scratch
      autocmd!
      autocmd TextChangedI <buffer> call s:CommentMagic()
    augroup END
  endfunction
endif

nnoremap <silent> <buffer> <Leader>: :<C-u>call <SID>IPyRunPrompt()<CR>
nnoremap <silent> <buffer> <Leader><Leader>: :<C-u>call VimuxCompletionPrompt()<CR>
nnoremap <silent> <buffer> @\  :<C-u>call <SID>IPyRepeatCommand()<CR>
nnoremap <silent> <buffer> @\| :<C-u>call <SID>IPyRepeatCommand()<CR>
nnoremap <silent> <buffer> g\  :<C-u>call <SID>IPyRunPrompt()<CR><C-f>
nnoremap <silent> <buffer> g\| :<C-u>call <SID>IPyRunPrompt()<CR><C-f>
cnoremap <silent> <buffer> <expr> <C-^> getcmdtype() == '@' ? '<C-e>()<CR>' : QuitSearch()
nnoremap <silent> <buffer> <Leader>cw :<C-u>call <SID>IPyClearWorkspace()<CR>
nnoremap <silent> <buffer> <Leader>cl :<C-u>call <SID>IPyCloseWindows()<CR>
nnoremap <silent> <buffer> <Leader>cf :<C-u>call <SID>IPyCloseFigures()<CR>
nnoremap <silent> <buffer> <Leader><Leader>cl :<C-u>call <SID>IPyCloseWindows()<CR>
xnoremap <silent> <buffer> <C-p>     :<C-u>call <SID>IPyPrintVar()<CR>
xnoremap <silent> <buffer> <M-s>     :<C-u>call <SID>IPyVarInfo()<CR>
nnoremap <silent> <buffer> <M-P>     :<C-u>call <SID>IPyVarInfo(1)<CR>
xnoremap <silent> <buffer> K         :<C-u>call <SID>IPyGetHelp('?')<CR>
xnoremap <silent> <buffer> <Leader>K :<C-u>call <SID>IPyGetHelp('??')<CR>
xnoremap <silent> <buffer> <M-y>     :<C-u>call <SID>IPyEval(0)<CR>
xnoremap <silent> <buffer> <M-e>     :<C-u>call <SID>IPyEval(1)<CR>
inoremap <silent> <expr>   <C-r>? <SID>IPyEval(2)
nnoremap <silent> <buffer> <Leader>X :<C-u>let g:first_op=1<bar>set opfunc=<SID>IPyPPmotion<CR>g@
nnoremap <silent> <buffer> <Leader>x :<C-u>let g:first_op=1<bar>set opfunc=<SID>IPyRunMotion<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>IPyRunMotion('visual')<CR>
nnoremap <silent>          ,ps :<C-u>call <SID>IPyScratchBuffer()<CR>
nnoremap <silent> <buffer> <Leader>e :<C-u>call <SID>IPyQuickFix()<CR>
nnoremap <silent>          <Leader>pl :<C-u>sign unplace *<CR>:autocmd! pymode CursorMoved<CR>:lclose<CR>
nnoremap <buffer> <expr>   <Leader>po <SID>ToggleOmnifunc()
nnoremap <buffer>          <Leader>pf :<C-u>set foldmethod=expr
    \ foldexpr=pymode#folding#expr(v:lnum) <Bar> silent! FastFoldUpdate<CR>

" Operator map to select a docstring
if has('python') || has('python3')
  function! s:SelectDocString(forward)
    try
      Python2or3 select_docstring()
    finally
      echo
    endtry
  endfunction
else
  function! s:SelectDocString(forward)
    let search = getreg('/')
    try
      let @/ = '\v^\s*[uU]?[rR]?("""\_.{-}"""|''''''\_.{-}'''''')\s*$'
      execute "normal! m'g".(a:forward ? 'n' : 'N')."\<Esc>"
      if getpos("'<")[1] == getpos("'>")[1] && getline('.') !~ '\v""".*"""|''''''.*......'
        normal! gvN
      else
        normal! gv
      endif
    finally
      call setreg('/', search)
      echo
    endtry
  endfunction
endif
onoremap <buffer> aD :<C-u>call <SID>SelectDocString(0)<CR>
xnoremap <buffer> aD :<C-u>call <SID>SelectDocString(0)<CR>
onoremap <buffer> ad :<C-u>call <SID>SelectDocString(1)<CR>
xnoremap <buffer> ad :<C-u>call <SID>SelectDocString(1)<CR>

function! s:ToggleOmnifunc()
  if &l:omnifunc == 'CompleteIPython'
    setlocal omnifunc=jedi#completions
    autocmd python_ftplugin BufEnter *
        \ if &filetype == 'python' |
        \   setlocal omnifunc=jedi#completions |
        \ endif
    echo 'jedi#completions'
  else
    setlocal omnifunc=CompleteIPython
    autocmd python_ftplugin BufEnter *
        \ if &filetype == 'python' |
        \   setlocal omnifunc=CompleteIPython |
        \ endif
    echo 'CompleteIPython'
  endif
endfunction

" Use whitespace-delimited completion with <C-x><C-g>
inoremap <buffer> <expr> <C-x><C-g> vimtools#CompleteStart('GreedyCompleteIPython')

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
    call setline(line('.'), substitute(getline('.'), '\v(^\s*)(.*$)', '\1## \2', ''))
    let pos[2] += 3
  finally
    call setpos('.', pos)
  endtry
endfunction

if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif

augroup python_ftplugin
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'python' |
      \   let &filetype = 'python' |
      \   let &l:omnifunc = getbufvar(bufnr('#'), '&l:omnifunc') |
      \   execute "nnoremap <buffer> S ^C" |
      \ endif
  autocmd InsertEnter *.py,--Python--
      \ if &omnifunc == 'CompleteIPython' |
      \   let g:neocomplete#sources#omni#input_patterns.python =
      \     '\%([^(). \t]\.\|^\s*from\s.\+import \%(\w\+,\s\+\)*\|^\s*from \|^\s*import \)\w*\|\[["'']\w*' |
      \ else |
      \   let g:neocomplete#sources#omni#input_patterns.python =
      \     '\%([^(). \t]\.\|^\s*@\|^\s*from\s.\+import \%(\w\+,\s\+\)*\|^\s*from \|^\s*import \)\w*' |
      \ endif
  autocmd InsertEnter *.pxd,*.pxi,*.pyx,*.pyxbld
      \ if &omnifunc ==# 'jedi#completions' |
      \   setlocal omnifunc= |
      \ endif |
      \ let g:neocomplete#sources#omni#input_patterns.python = ''
augroup END

if (has('python') || has('python3')) && !exists('*PEP8()')
  if !exists('g:pep8_force_wrap')
    let g:pep8_force_wrap = 0
  endif
  if !exists('g:pep8_indent_only')
    let g:pep8_indent_only = 0
  endif

  function! PEP8()
    Python2or3 PEP8()
  endfunction
endif
if has('python') || has('python3')
  setlocal formatexpr=PEP8()
endif

if (has('python') || has('python3')) && !exists('*FixImports()')
if !exists('s:module_cache')
  let s:module_cache = {}
endif
function! FixImports()
  let missing = []
  let redefined = []
  let s:checkers = g:pymode_lint_checkers
  let s:select = g:pymode_lint_select
  try
    let g:pymode_lint_checkers = ['pyflakes']
    let g:pymode_lint_select = 'E0602,W0404'
    let l:count = 0
    while 1
      PymodePython code_check()
      Python2or3 << EOF
messages = [(m['lnum'], m['text']) for m in
            vim.eval('copy(g:PymodeLocList.current()._loclist)')]
missing = sorted([m.split("'")[1] for _, m in messages if 'E0602' in m])
redefined = sorted([m.split("'")[1] for _, m in messages if 'W0404' in m])
unused = sorted([m.split("'")[1] for _, m in messages if 'W0611' in m])
EOF
      if l:count > 10 || (l:count > 0 &&
          \ s:pyeval('redefined') == redefined &&
          \ s:pyeval('missing') == missing &&
          \ s:pyeval('unused') == unused)
        break
      endif
      let l:count += 1
      let missing = s:pyeval('missing')
      let redefined = s:pyeval('redefined')
      let unused = s:pyeval('unused')
      let loclist = g:PymodeLocList.current()
      let messages = copy(loclist._loclist)
      let module_cache = s:module_cache
      if exists('g:python_autoimport_debug_file')
        execute s:pyfile . ' ' . fnameescape(g:python_autoimport_debug_file)
      else
        execute s:pyfile . ' ' . fnameescape(s:python_script_dir . '/autoimport.py')
      endif
    endwhile
  finally
    let g:pymode_lint_checkers = s:checkers
    let g:pymode_lint_select = s:select
  endtry
  call pymode#lint#check()
endfunction

function! s:FixImportsInDef(visual) abort
  let [save, save_type] = [getreg('"', 1), getregtype('"')]
  try
    let view = winsaveview()
    try
      if !a:visual
        call pymode#motion#select('^\s*\(class\|def\)\s', 0)
      endif
      normal! gv""y
    finally
      call winrestview(view)
    endtry
    silent execute 'split' tempname()
    silent put = @@
    setfiletype python
    call FixImports()
    if getline(1) =~ 'import '
      normal! zRggyipdap%"0p`[>`]
    endif
    setlocal formatexpr=PEP8()
    normal! gggqG
    set buftype=nofile
    call pymode#lint#check()
  finally
    call setreg('"', save, save_type)
  endtry
endfunction

function! FixMagicSyntax() abort
  let view = winsaveview()
  let fixed = 0
  try
    while 1
      let f = fixed
      call g:PymodeLocList.current().clear()
      PymodePython code_check()
      let loclist = g:PymodeLocList.current()._loclist
      if len(loclist) == 1 && loclist[0].text =~ 'invalid syntax'
        let [lnum, col] = [loclist[0].lnum, loclist[0].col]
        if stridx(join(map(synstack(lnum, col),
            \ 'tolower(synIDattr(v:val, "name"))')), 'magic') != -1
          call setline(lnum, substitute(getline(lnum),
              \ '\v(^\s*)(.*$)', '\1## \2', ''))
          let fixed += 1
        endif
        let line = getline(lnum)
      endif
      if f == fixed
        break
      endif
    endwhile
  finally
    call winrestview(view)
    echomsg printf('Fixed %d magic lines', fixed)
  endtry
endfunction
endif

" vim:set et ts=2 sts=2 sw=2:
