" Vim ftplugin file
" Language: Python
" Author: Jacob Niehus

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

let g:ipython_store_history = get(g:, 'ipython_store_history', 1)
let g:ipython_write_all = get(g:, 'ipython_write_all', 0)

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
nnoremap <silent> <buffer> ,pf :<C-u>lua vim.diagnostic.open_float()<CR>
nnoremap <silent> <buffer> ,pl :<C-u>lua vim.diagnostic.setloclist()<CR>
nnoremap <silent> <buffer> ,pm :<C-u>call FixMagicSyntax()<CR>
nnoremap <silent> <buffer> ,pi :<C-u>call FixImports()<CR>
nnoremap <silent> <buffer> ,ii v0:<C-u>call pymode#motion#select('^\s*\(class\<bar>def\)\s', 0)<CR>:<C-u>call <SID>FixImportsInDef()<CR>
xnoremap <silent> <buffer> ,ii :<C-u>call <SID>FixImportsInDef()<CR>
nnoremap          <buffer> ,ip :<C-u>IPythonConsole!<CR>

" Move around functions
nnoremap <silent> <buffer> [[ m':call search('^\s*def ', "bW")<CR>
xnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "bW")<CR>
nnoremap <silent> <buffer> ]] m':call search('^\s*def ', "W")<CR>
xnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "W")<CR>

" Unite IPython history maps
nnoremap <silent> <buffer> ,h :<C-u>Unite history/ipython -max-multi-lines=100 -no-split -no-resize<CR>
nnoremap <silent> <buffer> ,H :<C-u>Unite history/ipython:import -max-multi-lines=100 -no-split -no-resize<CR>

" Maps for debugging
nnoremap <silent> <buffer> <Leader>bb         :<C-u>call VimuxRunCommand("break ".expand('%:p').":".line('.'))<CR>
nnoremap <silent> <buffer> <Leader><Leader>bb :<C-u>call VimuxRunCommand("break ".expand('%:p').":".line('.').', '.input('condition: '))<CR>
nnoremap <silent> <buffer> <M-e>              :<C-u>call VimuxRunCommand("clear ".expand('%:p').":".line('.'))<CR>
nnoremap <silent> <buffer> <Leader>bc         :<C-u>call VimuxRunCommand('clear')<bar>call VimuxRunCommand('y')<CR>

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

let s:errorformat  = '%+GTraceback%.%#,'
let s:errorformat .= '%E  File %f:%l%\C,'
let s:errorformat .= '%E  File %f:%l %m%\C,'
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

from vim_utils import PEP8, get_ipython_file, select_docstring

import pycodestyle
pycodestyle.DEFAULT_IGNORE = ''
EOF
function! s:IPythonConsole(bang) abort " {{{
  let ipython_file = s:pyeval('get_ipython_file()')
  if a:bang || !empty(ipython_file)
    execute 'IPython' fnameescape(ipython_file)
  endif
endfunction " }}}
command! -bang IPythonConsole call s:IPythonConsole(<bang>0)
endif

if !exists('*IPyRunPrompt') && (has('python') || has('python3'))
  function! IPyRunIPyInput(...)
    if !exists('b:did_ipython') && !get(g:, 'ipython_connected', 0)
      echo 'Not connected to IPython'
      return
    endif
    redraw
    " Dedent text in case first non-blank line is indented
    Python2or3 << endpython
import textwrap
import vim
ipy_input = vim.vars['ipy_input']
if not isinstance(ipy_input, str):
    ipy_input = str(ipy_input, vim.eval('&encoding') or 'utf-8')
ipy_input = textwrap.dedent(ipy_input).strip()
vim.vars['ipy_input'] = ipy_input
endpython
    if g:ipython_write_all || bufnr('%') == bufnr(s:scratch_name)
      call s:WriteScratch(g:ipy_input)
    endif
    Python2or3 << endpython
import ast
try:
    kwargs = ast.literal_eval(vim.eval('a:1'))
except (ValueError, vim.error):
    kwargs = {}
try:
    ast.parse(ipy_input)
except SyntaxError:
    try:
        first, second = ipy_input.split('\n%%')
    except ValueError:
        pass
    else:
        vim.vars['ipy_input'] = first.strip()
        run_ipy_input(**kwargs)
        vim.vars['ipy_input'] = '%%' + second
run_ipy_input(**kwargs)
endpython
    unlet g:ipy_input
  endfunction

  function! IPyRunSilent(text)
    let g:ipy_input = a:text
    return IPyRunIPyInput('{"store_history": False}')
  endfunction

  function! s:input(prompt)
    let force_save = get(g:, 'force_ipython_complete', 0)
    try
      let g:force_ipython_complete = 1
      return input(a:prompt, '', 'customlist,vimtools#CmdlineComplete')
    finally
      let g:force_ipython_complete = force_save
    endtry
  endfunction

  function! IPyRunPrompt(store_history)
    let g:ipy_input = s:input('IPy: ')
    if len(g:ipy_input)
      let g:last_ipy_input = [g:ipy_input, a:store_history]
      call s:IPyRepeatCommand()
    else
      unlet g:ipy_input
    endif
  endfunction

  function! s:IPyRepeatCommand()
    if exists('g:last_ipy_input')
      let [g:ipy_input, store_history] = g:last_ipy_input
      if store_history
        call IPyRunIPyInput()
      else
        call IPyRunSilent(g:ipy_input)
      endif
    endif
  endfunction

  function! s:IPyPrintVar()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = UncommentMagics(@")
    call RestoreRegs()
    call IPyRunSilent(g:ipy_input)
  endfunction

  function! s:IPyVarInfo(...)
    if a:0 > 0
      let input = expand('<cword>')
    else
      call SaveRegs()
      normal! gvy
      let input = substitute(@", '^\s*\|\s*\n\?\s*$', '', 'g')
      call RestoreRegs()
    endif
    let g:ipy_input = 'from plottools import varinfo; varinfo('.input.')'
    call IPyRunSilent(g:ipy_input)
  endfunction

  function! s:IPyGetHelp(level)
    call SaveRegs()
    normal! gvy
    let g:ipy_input = substitute(matchstr(@", '^\s*#*\s*\zs.*\ze'),
        \ "\n*$", '', '') . a:level
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
    if &omnifunc !=# 'CompleteIPython'
      return s:IPyPPmotion(a:type)
    endif
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
      let g:ipy_input = UncommentMagics(g:ipy_input)
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
        let pyerr = substitute(pyerr,
            \ '\v\cFile "/.*/ipykernel_\d+/\d+.py", '.
            \ 'line \zs\d+', '\=submatch(0) + nextnonblank("''[") - 1', 'g')
        let pyerr = substitute(pyerr,
            \ '\v\cFile "\zs/.*/ipykernel_\d+/\d+.py\ze", ',
            \ expand('%:p'), 'g')
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
          " Go to last error in a listed buffer (prefer current buffer)
          let [n, list] = [1, getqflist()]
          for entry in list
            let [entry.ccnr, n] = [n, n + 1]
          endfor
          if &filetype ==# 'qf' | wincmd p | endif
          call filter(list, "v:val.bufnr >= 0 && buflisted(v:val.bufnr)")
          if bufnr('%') > 0 && !empty(filter(copy(list), "v:val.bufnr == bufnr('%')"))
            execute "cc" filter(list, "v:val.bufnr == bufnr('%')")[-1].ccnr
          elseif !empty(list)
            execute "cc" list[-1].ccnr
          elseif !empty(getqflist())
            cfirst
          endif
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

  function! IPyEval(mode)
    " mode 0 = copy to clipboard
    " mode 1 = replace visual selection
    " mode 2 = expression register-like
    " mode 3 = paste below visual selection
    " mode 4 = expression register cmap
    call SaveRegs()
    try
      if index([2, 4], a:mode) == -1
        normal! gvy
        let g:ipy_input = @@
      else
        let g:ipy_input = s:input('>>> ')
      endif
      if g:ipython_write_all || bufnr('%') == bufnr(s:scratch_name)
        call s:WriteScratch(g:ipy_input)
      endif
      if a:mode == 0
        Python2or3 eval_ipy_input()
      else
        silent! unlet g:ipy_result
        Python2or3 eval_ipy_input('g:ipy_result')
        if !exists('g:ipy_result') || empty(g:ipy_result)
          return ''
        endif
        if a:mode == 4
          let g:ipy_result = substitute(g:ipy_result, '\n\|^\s*\|\s*$', '', 'g')
          return "\<C-r>=g:ipy_result\<CR>"
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
        call setreg('"', g:ipy_result)
        normal! gv""p
      elseif a:mode == 3
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

  function! s:WriteScratch(text) abort
    let sep = !exists('+shellslash') || &shellslash ? '/' : '\\'
    let dir = substitute($HOME . '/.cache/IPython/', '/', sep, 'g')
    if !isdirectory(dir) | call mkdir(dir) | endif
    call writefile(split(a:text. "\n\n", '\n'), dir .
        \ strftime('scratch_%Y_%m_%d.py'), 'a')
  endfunction
endif

function! s:unique_map(mode, map) abort
  execute           a:mode . 'noremap <silent> <buffer>' a:map
  execute 'silent!' a:mode . 'noremap <silent> <unique>' a:map
endfunction

call s:unique_map('n', '<Leader>: :<C-u>call IPyRunPrompt(1)<CR>')
call s:unique_map('n', '<Leader><Leader>: :<C-u>call IPyRunPrompt(0)<CR>')
call s:unique_map('n', '@\  :<C-u>call <SID>IPyRepeatCommand()<CR>')
call s:unique_map('n', '@\| :<C-u>call <SID>IPyRepeatCommand()<CR>')
call s:unique_map('n', 'g\  :<C-u>call IPyRunPrompt(1)<CR><C-f>')
call s:unique_map('n', 'g\| :<C-u>call IPyRunPrompt(1)<CR><C-f>')
call s:unique_map('n', '<Leader>e :<C-u>call <SID>IPyQuickFix()<CR>')
call s:unique_map('n', '<Leader>e :<C-u>call <SID>IPyQuickFix()<CR>')
cnoremap <silent> <buffer> <expr> <C-^> getcmdtype() == '@' ? '<C-e>()<CR>' : QuitSearch()
xnoremap <silent> <buffer> <C-p>     :<C-u>call <SID>IPyPrintVar()<CR>
xnoremap <silent> <buffer> <M-s>     :<C-u>call <SID>IPyVarInfo()<CR>
nnoremap <silent> <buffer> <M-P>     :<C-u>call <SID>IPyVarInfo(1)<CR>
xnoremap <silent> <buffer> K         :<C-u>call <SID>IPyGetHelp('?')<CR>
xnoremap <silent> <buffer> <Leader>K :<C-u>call <SID>IPyGetHelp('??')<CR>
xnoremap <silent> <buffer> <M-y>     :<C-u>call IPyEval(0)<CR>
xnoremap <silent> <buffer> <M-e>     :<C-u>call IPyEval(1)<CR>
inoremap <silent> <expr>   <C-r>? IPyEval(2)
cnoremap <silent> <expr>   <C-r>? IPyEval(4)
nnoremap <silent> <buffer> <Leader>X :<C-u>let g:first_op=1<bar>set opfunc=<SID>IPyPPmotion<CR>g@
nnoremap <silent> <buffer> <Leader>x :<C-u>let g:first_op=1<bar>set opfunc=<SID>IPyRunMotion<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>IPyRunMotion('visual')<CR>
nnoremap <silent>          <Leader>pl :<C-u>sign unplace *<CR>:autocmd! pymode CursorMoved<CR>:lclose<CR>
nnoremap <silent> <buffer> <Leader>po :<C-u>call <SID>ToggleOmnifunc()<CR>
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

if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

if !exists('s:omni_patterns')
  let s:omni_patterns = {}
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
      \ let s:omni_patterns = get(g:, 'python_force_omni', 0) ?
      \     g:neocomplete#force_omni_input_patterns :
      \     g:neocomplete#sources#omni#input_patterns |
      \ if !has('nvim') && &omnifunc == 'CompleteIPython' |
      \   let s:omni_patterns.python =
      \     '\%([^[(). \t]\.\|^\s*from\s.\+import \%(\w\+,\s\+\)*\|^\s*from \|^\s*import \)\w*\|\[["'']\w*' |
      \ elseif !has('nvim') |
      \   let s:omni_patterns.python =
      \     '\%([^[(). \t]\.\|^\s*@\|^\s*from\s.\+import \%(\w\+,\s\+\)*\|^\s*from \|^\s*import \)\w*' |
      \ endif
  autocmd InsertEnter *.pxd,*.pxi,*.pyx,*.pyxbld
      \ if &omnifunc ==# 'jedi#completions' |
      \   setlocal omnifunc= |
      \ endif |
      \ let s:omni_patterns.python = ''
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
    let g:pymode_lint_select = ['E0602', 'W0404']
    let l:count = 0
    while 1
      PymodePython code_check()
      Python2or3 << EOF
messages = set([(m['lnum'], m['text'], m['number']) for m in
                vim.eval('copy(g:PymodeLocList.current().loclist())')])
missing = sorted([m.split("'")[1] for _, m, n in messages if n == 'E0602'])
redefined = sorted([m.split("'")[1] for _, m, n in messages if n == 'W0404'])
unused = sorted([m.split("'")[1] for _, m, n in messages if n == 'W0611'])
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
      let messages = copy(loclist.loclist())
      let module_cache = s:module_cache
      let pyfile = get(g:, 'python_autoimport_debug_file',
          \ s:python_script_dir . '/autoimport.py')
      Python2or3 << EOF
import runpy
runpy.run_path(vim.eval('pyfile'))
EOF
    endwhile
  finally
    let g:pymode_lint_checkers = s:checkers
    let g:pymode_lint_select = s:select
  endtry
  call pymode#lint#check()
endfunction

function! s:FixImportsInDef() abort
  let [save, save_type] = [getreg('"', 1), getregtype('"')]
  try
    let view = winsaveview()
    try
      normal! gv""y
    finally
      call winrestview(view)
    endtry
    silent execute 'split' tempname()
    let def = split(@@, '\n')[0] =~ '^\s*\%(class\|def\) '
    silent put = @@
    setfiletype python
    call FixImports()
    normal! zR
    if def && getline(1) =~ 'import '
      normal! ggdap%p`[>`]
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
      if len(loclist) == 1 && loclist[0].type ==# 'E'
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
