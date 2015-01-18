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
xnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "bW")<CR>
nnoremap <silent> <buffer> ]] m':call search('^\s*def ', "W")<CR>
xnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('^\s*def ', "W")<CR>

" Enable omni completion
setlocal omnifunc=pythoncomplete#Complete

" Use pymode's fold expression
augroup py_ftplugin
  autocmd!
  autocmd SessionLoadPost <buffer> setlocal foldmethod=expr
      \ foldexpr=pymode#folding#expr(v:lnum) foldtext=pymode#folding#text()
augroup END

inoreabbrev <buffer> @ lambda

let s:errorformat  = '%+GTraceback%.%#,'
let s:errorformat .= '%E  File "%f"\, line %l\,%m%\C,'
let s:errorformat .= '%E  File "%f"\, line %l%\C,'
let s:errorformat .= '%C%p^,'
let s:errorformat .= '%+C    %.%#,'
let s:errorformat .= '%+C  %.%#,'
let s:errorformat .= '%Z%\S%\&%m,'
let s:errorformat .= '%-G%.%#'

if !exists('*s:IPyRunPrompt')
  function! s:IPyRunIPyInput()
    if exists('b:did_ipython')
      redraw
      " Remove leading and trailing blank lines
      let g:ipy_input = join(split(g:ipy_input, "\n"), "\n")
      python run_ipy_input()
      unlet g:ipy_input
    else
      echo 'Not connected to IPython'
    endif
  endfunction

  function! s:IPyRunPrompt()
    let g:ipy_input = input('IPy: ')
    if len(g:ipy_input)
      let g:last_ipy_input = g:ipy_input
      call s:IPyRunIPyInput()
    else
      unlet g:ipy_input
    endif
  endfunction

  function! s:IPyRepeatCommand()
    if exists('g:last_ipy_input')
      let g:ipy_input = g:last_ipy_input
      call s:IPyRunIPyInput()
    endif
  endfunction

  function! s:IPyClearWorkspace()
    let g:ipy_input = 'plt.close("all")'."\n".'%reset -s -f'
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyCloseWindows()
    let g:ipy_input = 'from PyQt4 import QtCore; QtCore.QCoreApplication.instance().closeAllWindows()'
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyCloseFigures()
    let g:ipy_input = 'plt.close("all")'
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyPing()
    let g:ipy_input = 'print "pong"'
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyPrintVar()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = 'from pprint import pprint; pprint('.@".')'
    call RestoreRegs()
    call s:IPyRunIPyInput()
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
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyGetHelp()
    call SaveRegs()
    normal! gvy
    let g:ipy_input = 'help('.@".')'
    call RestoreRegs()
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyRunMotion(type)
    let input = vimtools#opfunc(a:type)
    if exists('b:did_ipython')
      let g:ipy_input = vimtools#opfunc(a:type)
      if matchstr(g:ipy_input, '[[:print:]]\ze[^[:print:]]*$') == '?'
        call setpos('.', getpos("']"))
        python run_this_line(False)
      else
        call s:IPyRunIPyInput()
      endif
    else
      let zoomed = _VimuxTmuxWindowZoomed()
      if zoomed | call system("tmux resize-pane -Z") | endif
      call VimuxOpenRunner()
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

  function! s:IPyRunScratchBuffer()
    let view = winsaveview()
    call SaveRegs()
    normal! gg0vG$y
    let g:ipy_input = @@
    call RestoreRegs()
    call winrestview(view)
    call s:IPyRunIPyInput()
  endfunction

  function! s:IPyScratchBuffer()
    let scratch = bufnr('--Python--')
    if scratch == -1
      enew
      IPython
      silent file --Python--
    else
      execute "buffer ".scratch
    endif
    set filetype=python
    setlocal buftype=nofile bufhidden=hide noswapfile
    setlocal omnifunc=CompleteIPython
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
cnoremap <silent> <buffer> <expr> <C-^> getcmdtype() == '@' ? '<C-e>()<CR>' : QuitSearch()
nnoremap <silent> <buffer> <Leader>cw :<C-u>call <SID>IPyClearWorkspace()<CR>
nnoremap <silent> <buffer> <Leader>cl :<C-u>call <SID>IPyCloseFigures()<CR>
nnoremap <silent> <buffer> <Leader>cf :<C-u>call <SID>IPyCloseFigures()<CR>
nnoremap <silent> <buffer> <Leader><Leader>cl :<C-u>call <SID>IPyCloseWindows()<CR>
nnoremap <silent>          ,pp :<C-u>call <SID>IPyPing()<CR>
xnoremap <silent> <buffer> <C-p> :<C-u>call <SID>IPyPrintVar()<CR>
xnoremap <silent> <buffer> <M-s> :<C-u>call <SID>IPyVarInfo()<CR>
nnoremap <silent> <buffer> <M-P> :<C-u>call <SID>IPyVarInfo(1)<CR>
xnoremap <silent> <buffer> K     :<C-u>call <SID>IPyGetHelp()<CR>
nnoremap <silent> <buffer> <Leader>x :<C-u>set opfunc=<SID>IPyRunMotion<CR>g@
nnoremap <silent> <buffer> <Leader>xx :<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>set opfunc=<SID>IPyRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>IPyRunMotion('visual')<CR>
nnoremap <silent>          ,ps :<C-u>call <SID>IPyScratchBuffer()<CR>
nnoremap <silent> <buffer> <Leader>e :<C-u>call <SID>IPyQuickFix()<CR>
nnoremap <silent>          <Leader>pl :<C-u>sign unplace *<CR>:autocmd! pymode CursorMoved<CR>
nnoremap <buffer> <expr>   <Leader>po <SID>ToggleOmnifunc()
nnoremap <buffer>          <Leader>pf :<C-u>set foldmethod=expr
    \ foldexpr=pymode#folding#expr(v:lnum) <Bar> silent! FastFoldUpdate<CR>

" Operator map to select a docstring
if has('python')
python << EOF
import cStringIO
import tokenize
import vim


def get_docstrings(source):
    io_obj = cStringIO.StringIO(source)
    prev_toktype = tokenize.INDENT
    only_comments = True
    docstrings = []
    for tok in tokenize.generate_tokens(io_obj.readline):
        token_type = tok[0]
        start_line = tok[2][0]
        end_line = tok[3][0]
        if token_type == tokenize.STRING:
            if prev_toktype == tokenize.INDENT or only_comments:
                docstrings.append((start_line, end_line))

        if token_type not in [tokenize.COMMENT,
                              tokenize.NL,
                              tokenize.INDENT,
                              tokenize.STRING]:
            only_comments = False

        prev_toktype = token_type

    return docstrings


def find_docstring(line, next=True):
    docstrings = get_docstrings('\n'.join([b for b in vim.current.buffer]))
    for d in docstrings:
        if line in range(d[0], d[1] + 1):
            return d

    if next:
        for d in docstrings:
            if d[0] > line:
                return d
    else:
        docstrings.reverse()
        for d in docstrings:
            if d[1] < line:
                return d

    try:
        return docstrings[-1]
    except IndexError:
        return None, None
EOF
  function! s:SelectDocString(forward)
    try
python << EOF
start, end = find_docstring(int(vim.eval('line(".")')),
                            next=True if int(vim.eval('a:forward')) else False)
if start is not None:
    vim.command('call cursor(%d, 0)' % start)
    vim.command('normal! V')
    vim.command('call cursor(%d, 0)' % end)
EOF
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

" Use dictionary completion automatically
if exists('g:ipython_dictionary_completion')
  inoremap <buffer> <expr> '
      \ &omnifunc == 'CompleteIPython' && getline('.')[col('.')-2] == '[' ?
      \ "'".'<C-x><C-o><C-p>' : "'"
  inoremap <buffer> <expr> "
      \ &omnifunc == 'CompleteIPython' && getline('.')[col('.')-2] == '[' ?
      \ '"<C-x><C-o><C-p>' : '"'
endif

augroup python_ftplugin
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'python' |
      \     let &filetype = 'python' |
      \     let &l:omnifunc = getbufvar(bufnr('#'), '&l:omnifunc') |
      \     execute "nnoremap <buffer> S ^C" |
      \ endif
  autocmd InsertEnter *.py,--Python--
      \ if &omnifunc == 'CompleteIPython' |
      \     let g:neocomplete#force_omni_input_patterns.python = '\%([^(). \t]\.\|^\s*@\)\w*\|\[["'']\w*' |
      \ else |
      \     let g:neocomplete#force_omni_input_patterns.python = '\%([^(). \t]\.\|^\s*@\)\w*' |
      \ endif
augroup END

if has('python') && !exists('*PEP8()')
  let s:script_dir = escape(expand('<sfile>:p:h' ), '\')
  let s:python_script_dir = s:script_dir . '/python'
  if !exists('g:pep8_force_wrap')
    let g:pep8_force_wrap = 0
  endif
  if !exists('g:pep8_indent_only')
    let g:pep8_indent_only = 0
  endif
python << EOF
import vim
import sys
import re

SCRIPT_DIR = vim.eval('s:python_script_dir')
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import autopep8
import docformatter


class Options(object):
    aggressive = 2
    diff = False
    experimental = True
    ignore = None
    in_place = False
    indent_size = autopep8.DEFAULT_INDENT_SIZE
    line_range = None
    max_line_length = 79
    pep8_passes = 100
    recursive = False
    select = None
    verbose = 0

doc_start = re.compile('^\s*[ur]?("""|' + (3 * "'") + ').*')
doc_end = re.compile('.*("""|' + (3 * "'") + ')' + '\s*$')

EOF
function! PEP8()
python << EOF
start = vim.vvars['lnum'] - 1
end = vim.vvars['lnum'] + vim.vvars['count'] - 1

first_non_blank = int(vim.eval('nextnonblank(v:lnum)')) - 1
last_non_blank = int(vim.eval('prevnonblank(v:lnum + v:count - 1)')) - 1

doc_string = False
if (first_non_blank >= 0
        and doc_start.match(vim.current.buffer[first_non_blank])
        and doc_end.match(vim.current.buffer[last_non_blank])):
    doc_string = True
else:
    # Don't remove trailing blank lines except at end of file
    while (end < len(vim.current.buffer)
           and re.match('^\s*$', vim.current.buffer[end - 1])):
        end += 1

lines = vim.current.buffer[start:end]
lines = [unicode(line, 'utf-8') for line in lines]

if doc_string:
    new_lines = docformatter.format_code(
        u'\n'.join(lines),
        force_wrap=True if vim.vars['pep8_force_wrap'] else False,
        post_description_blank=False,
        pre_summary_newline=True)
else:
    options = Options()
    if vim.vars['pep8_indent_only']:
        options.select = ['E1', 'W1']
    new_lines = autopep8.fix_lines(lines, options)

new_lines = new_lines.encode(vim.eval('&encoding') or 'utf-8')
new_lines = new_lines.split('\n')[: None if doc_string else -1]

if new_lines != lines:
    vim.current.buffer[start:end] = new_lines

EOF
endfunction
endif
if has('python')
  setlocal formatexpr=PEP8()
endif

" vim:set et ts=2 sts=2 sw=2:
