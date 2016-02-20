" Import vital utilities
if !exists('s:V')
  let s:V = vital#of('vimtools')
  let s:Prelude = s:V.import('Prelude')
  let s:List = s:V.import('Data.List')
  let s:String = s:V.import('Data.String')
endif

function! vimtools#flatten(...) abort " {{{
  return call(s:List.flatten, a:000)
endfunction " }}}
function! vimtools#glob(...) abort " {{{
  return call(s:Prelude.glob, a:000)
endfunction " }}}

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#SynNames(...) abort " {{{
  if a:0
    let [line, col] = [a:1, a:2]
  else
    let [line, col] = [line('.'), col('.')]
  endif
  return reverse(map(synstack(line, col), 'synIDattr(v:val,"name")'))
endfunction " }}}

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#HelpTopic() " {{{
  if &syntax != 'vim'
    return expand('<cword>')
  endif
  let col = col('.') - 1
  while col && getline('.')[col] =~# '\k'
    let col -= 1
  endwhile
  let pre = col == 0 ? '' : getline('.')[0 : col]
  let col = col('.') - 1
  while col && getline('.')[col] =~# '\k'
    let col += 1
  endwhile
  let post = getline('.')[col : -1]
  let syn = get(vimtools#SynNames(), 0, '')
  let cword = expand('<cword>')
  if syn ==# 'vimFuncName'
    return cword.'()'
  elseif syn ==# 'vimOption'
    return "'".cword."'"
  elseif syn ==# 'vimUserAttrbKey'
    return ':command-'.cword
  elseif pre =~# '^\s*:\=$'
    return ':'.cword
  elseif pre =~# '\<v:$'
    return 'v:'.cword
  elseif cword ==# 'v' && post =~# ':\w\+'
    return 'v'.matchstr(post, ':\w\+')
  else
    return cword
  endif
endfunction " }}}

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#EchoSyntax(count) " {{{
  if a:count
    let name = get(vimtools#SynNames(), a:count-1, '')
    if name !=# ''
      return 'syntax list '.name
    endif
  else
    echo join(vimtools#SynNames(), ' ')
  endif
  return ''
endfunction " }}}

" Open in same window if current tab is empty, or else open in new window
function! vimtools#OpenHelp(topic) " {{{
  if vimtools#TabUsed()
    " Open vertically if there's enough room
    let l:split=0
    let l:helpWin=0
    for l:win in range(1,winnr('$'))
      if winwidth(l:win) < &columns
        let l:split=1
        if getwinvar(l:win,'&ft') == 'help'
          let l:helpWin=l:win
        endif
      endif
    endfor
    if l:helpWin
      " If help is already open in a window, use that window
      execute l:helpWin.'wincmd w'
      setlocal bt=help
      let cmd = 'help '
    elseif (&columns > 160) && !l:split
        \ && (str2float(&columns) / str2float(&lines)) > 2.5
      " Open help in vertical split depending on window geometry
      let cmd = 'vertical help '
    else
      let cmd = 'aboveleft help '
    endif
  else
    setlocal ft=help bt=help noma
    let cmd = 'help '
  endif
  try
    execute cmd.a:topic
  catch /^Vim\%((\a\+)\)\=:E149/
    echohl ErrorMsg | echo substitute(v:exception, '^[^:]*:', '', '') | echohl None
  endtry
endfunction " }}}

function! vimtools#OpenHelpVisual() " {{{
  call SaveRegs()
  return (g:inCmdwin ? "y:q\<CR>" : "y").":Help \<C-r>\"\<CR>:call RestoreRegs()\<CR>"
endfunction " }}}

function! vimtools#TabUsed() " {{{
  return strlen(expand('%')) || line('$')!=1 || getline(1)!='' || winnr('$')>1
endfunction " }}}

function! vimtools#SwitchToOrOpen(fname) " {{{
  let l:bufnr=bufnr(expand(a:fname).'$')
  if l:bufnr > 0 && buflisted(l:bufnr)
    for l:tab in range(1, tabpagenr('$'))
      let l:buflist = tabpagebuflist(l:tab)
      if index(l:buflist,l:bufnr) >= 0
        for l:win in range(1,tabpagewinnr(l:tab,'$'))
          if l:buflist[l:win-1] == l:bufnr
            exec 'tabn '.l:tab
            exec l:win.'wincmd w'
            return
          endif
        endfor
      endif
    endfor
  endif
  if vimtools#TabUsed()
    exec 'tabedit '.a:fname
  else
    exec 'edit '.a:fname
  endif
endfunction " }}}

function! vimtools#ResizeWindow(type) " {{{
  if winnr('$') == 1 | return | endif
  let eventignore_save = &eventignore
  set eventignore=all
  let startwin = winnr()
  try
    wincmd l
    let win_on_right = winnr() == startwin || &winfixwidth
    execute startwin."wincmd w"
    wincmd j
    let win_on_bottom = winnr() == startwin || (&winfixheight && &filetype != 'qf')
    execute startwin."wincmd w"
    wincmd k
    let win_on_top = winnr() == startwin
    execute startwin."wincmd w"
    if a:type == 'up' || a:type == 'down'
      if !(win_on_bottom && win_on_top)
        if (win_on_bottom && a:type == 'down') || (!win_on_bottom && a:type == 'up')
          execute "normal! ".v:count1."\<C-w>-"
        else
          execute "normal! ".v:count1."\<C-w>+"
        endif
      endif
    else
      if (win_on_right && a:type == 'right') || (!win_on_right && a:type == 'left')
        execute "normal! ".v:count1."\<C-w><"
      else
        execute "normal! ".v:count1."\<C-w>>"
      endif
    endif
  finally
    let &eventignore = eventignore_save
    execute startwin."wincmd w"
  endtry
endfunction " }}}

" Move cursor using key until on non-concealed text
function! vimtools#conceal_move(key) " {{{
  execute "normal ".a:key
  let cnt = 0
  while synconcealed(line('.'), col('.'))[0] && cnt < 20
    let cnt = cnt + 1
    execute "normal ".a:key
  endwhile
endfunction " }}}

" Display file structure with dircolors
function! vimtools#Tree(...) " {{{
  let dir = a:0 ? a:1 : getcwd()
  let treenr = bufnr('--tree--')
  if treenr == -1
    execute "enew" | silent execute "file --tree--"
    setlocal winfixwidth readonly nobuflisted
    setlocal buftype=nofile bufhidden=hide noswapfile
  else
    execute "buffer ".treenr | silent execute "normal! ggdG"
  endif
  if dir != getcwd() | execute "lcd ".dir | endif
  execute "silent read!cd ".dir."; tree -CQf"
  setlocal nomodified
  redir => ansiCheck | silent! highlight ansiRed | redir END
  if ansiCheck !~ 'term' | execute "AnsiEsc" | endif
  execute "normal! gg"
  syn match ansiConceal conceal '"'
  syn match ansiConceal conceal "\(\"\..*\/\)"
  nnoremap <silent> <buffer> j j0f"l
  nnoremap <silent> <buffer> k k0f"l
  nnoremap <buffer> <CR> gf
  nnoremap <silent> <buffer> ZZ :wincmd c<CR>
endfunction " }}}

" Make [[, ]], [], and ][ work when { is not in first column
function! vimtools#SectionJump(type, v) " {{{
  let l:count = v:count1
  let startpos = getpos('.')
  if a:v | exe "keepjumps norm! gv" | endif
  while l:count
    if a:type == '[['
      keepjumps call search('{','b',1)
      keepjumps normal! w99[{
    elseif a:type == ']['
      keepjumps call search('}','',line('$'))
      keepjumps normal! b99]}
    elseif a:type == ']]'
      keepjumps normal j0[[%
      keepjumps call search('{','',line('$'))
    elseif a:type == '[]'
      keepjumps normal k$][%
      keepjumps call search('}','b',1)
    endif
    let l:count -= 1
  endwhile
  call setpos("''", startpos)
  normal! `'`'
endfunction " }}}

function! vimtools#SectionJumpMaps() " {{{
  if search('\m\C^\s*namespace', 'cnw') == 0 && search('\m\C^{', 'cnw') == 0
    for key in ['[[', '][', ']]', '[]']
      exe "noremap  <silent> <buffer> ".key." :<C-u>call vimtools#SectionJump('".key."',0)<CR>"
      exe "xnoremap <silent> <buffer> ".key." :<C-u>call vimtools#SectionJump('".key."',1)<CR>"
    endfor
  endif
endfunction " }}}

" Make pasted text have one blank line above and below
function! vimtools#MakeParagraph() " {{{
  call SaveRegs()
  let foldenable_save = &foldenable | set nofoldenable
  let l1 = nextnonblank(line("'["))
  let l2 = prevnonblank(line("']"))
  let lines = l2 - l1 + 1
  let l3 = nextnonblank(l2 + 1)
  if l3 == 0
    let l3 = line('$')
  endif

  if l3 > l2
    silent execute "keeppatterns ".l2.",".l3."g/^\\s*$/d"
    if l2 != line('$')
      call append(l2, [""])
    endif
  else
    silent execute "keeppatterns ".line("']").",".line('$')."g/^\\s*$/d"
  endif

  let l4 = prevnonblank(l1 - 1)
  if l4 > 0
    silent execute "keeppatterns ".l4.",".l1."g/^\\s*$/d"
    call append(l4, [""])
    call cursor(l4 + 2, 0)
  else
    silent execute "keeppatterns 1,".l1."g/^\\s*$/d"
    call cursor(1, 0)
  endif

  if &filetype == 'python'
    if getline('.') =~# '\v^\s*(<(def|class)>|\@[[:alnum:]_]+)' && line('.') > 1
      call append(line('.') - 1, [""])
      if line('.') + lines < line('$')
        call append(line('.') + lines, [""])
      endif
    endif
  endif

  let &foldenable = foldenable_save
  call RestoreRegs()
endfunction " }}}

" Search (not) followed/preceded by
function! vimtools#FollowedBy(not) abort " {{{
  let s1 = input("Main: ", '', 'customlist,vimtools#CmdlineComplete')
  let s1 = substitute(len(s1) ? s1 : @/,'\m\c^\\v','','')
  let s1 = substitute(s1, '\m\\<\(.*\)\\>', '<\1>', '')
  let s2 = substitute(input((a:not ? 'Not f' : 'F').'ollowed by: ', '',
      \ 'customlist,vimtools#CmdlineComplete'),'\m\c^\\v','','')
  let @/ = '\v\zs('.s1.')(.*'.s2.')@'.(a:not ? '!' : '=').'\ze.*$'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction " }}}

function! vimtools#PrecededBy(not) abort " {{{
  let s1 = input("Main: ", '', 'customlist,vimtools#CmdlineComplete')
  let s1 = substitute(len(s1) ? s1 : @/,'\m\c^\\v','','')
  let s1 = substitute(s1, '\m\\<\(.*\)\\>', '<\1>', '')
  let s2 = substitute(input((a:not ? 'Not p' : 'P').'receded by: ', '',
      \ 'customlist,vimtools#CmdlineComplete'),'\m\c^\\v','','')
  let @/ = '\v^.*(('.s2.').*)@<'.(a:not ? '!' : '=').'\zs('.s1.')'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction " }}}

" Don't overwrite pattern with substitute command
function! vimtools#KeepPatterns(line1, line2, cmd) " {{{
  let cmd = a:cmd
  let split = split(a:cmd, '\v\\@<!/')
  if split[0] =~# '\v^S%[ubvert]$' && len(split) == 3 && a:cmd[-1:] != '/'
    let cmd = a:cmd . '/'
  endif
  let pat = @/
  try
    let s:last_pat = vimtools#GetViminfoSubsPat()
    if (cmd[0] == 'g' || cmd[0] == 'v') && a:line1 == a:line2
      execute cmd
    else
      execute a:line1.','.a:line2.cmd
    endif
    let g:lsub_pat = @/
    let b = '((\\)@<!\\)' " Unescaped backslash
    let l:subs_pat = '\v\C^s%[ubstitute]/([^/]|'.b.'@<=/)*'.b.'@<!/'
    if cmd =~ '\v\C^s%[ubstitute]/([^/]|'.b.'@<=/)[^/]*('.b.'@<!\/)?$'
      " Command has form %s/pat or %s/pat/
      let g:lsub_rep = ''
    else
      let g:lsub_rep=substitute(cmd,l:subs_pat.'\v\ze([^/]|'.b.'@<=/)*','','')
      let g:lsub_rep=substitute(g:lsub_rep,'\v([^/]|'.b.'@<=/)*\zs'.b.'@<!/.{-}$','','')
    endif
    if cmd =~ '\v'.b.'@<!/.*'.b.'@<!/.*'.b.'@<!/'
      let g:lsub_flags=substitute(cmd,'\v^.*\\@<!/\ze.{-}$','','')
    else
      let g:lsub_flags=''
    endif
  finally
    let @/ = pat
  endtry
endfunction " }}}

function! vimtools#RepeatSubs(flags) " {{{
  let pat = vimtools#GetViminfoSubsPat()
  if !exists('s:last_pat') || pat != s:last_pat
    execute "normal! ".(a:flags ? 'g' : '')."&"
  else
    execute "keeppatterns s/".g:lsub_pat."/".g:lsub_rep.
        \ (a:flags ? "/".g:lsub_flags : "")
  endif
endfunction " }}}

function! vimtools#GetViminfoSubsPat() " {{{
  let fname = tempname()
  execute "wviminfo ".fnameescape(fname)
  try
    let lines = readfile(fname, 25)
    for line in lines
      if exists('nextline')
        return line[stridx(line, '&')+1:]
      endif
      if line == '# Last Substitute Search Pattern:'
        let nextline = 1
      endif
    endfor
  finally
    call delete(fname)
  endtry
endfunction " }}}

function! s:PatternCmdComplete() abort " {{{
  set wildcharm=<Tab>
  silent! cunmap <Tab>
  silent! nunmap :
  if getcmdline() !~# '\vKeepPatterns|^(\%|''\<,''\>)?[gsv]//?'
    return getcmdline()
  endif
  let line = getcmdline()
  let magic = matchstr(line, '\v(^[^/]*[Ssgv]/)\zs%(\\\%V)?\\[vV]')
  let start = matchstr(line, '\v^.*\\@<!/.*\\@<!/')
  if empty(start)
    let start = printf('=%s/%s', substitute(line, '/.*$', '', ''), magic)
  else
    let start = printf('=%s', start)
  endif
  cnoremap <buffer> <expr> / getcmdline()[-1] == '\' ? '/' :
      \ '<CR><C-\>evimtools#KeepPatternsSubstitute()<CR><Left><C-]><Right>'
  try
    let input = input(start, line[strchars(start) - 1:],
        \ 'customlist,vimtools#CmdlineComplete')
  finally
    silent! cunmap <buffer> /
  endtry
  call setcmdpos(len(start.input))
  return start[1:].input
endfunction " }}}

let s:range_pattern = '((\d+|\.|\$|''\a)(,(\d+|\.|\$|''\a))?)'
function! vimtools#KeepPatternsSubstitute() " {{{
  let cmdline = getcmdline()
  cnoremap <Tab> <C-\>e<SID>PatternCmdComplete()<CR><Tab>
  nnoremap : :<C-u>doautocmd command_tab_map CursorMoved<CR>:
  augroup command_tab_map
    autocmd!
    autocmd CursorMoved * execute 'silent! cunmap <Tab>' |
        \                 execute 'silent! nunmap :' |
        \                 autocmd! command_tab_map
  augroup END
  if getcmdtype() == ':'
    let cmd = cmdline[match(cmdline,'\a')]
    let m = cmd =~# '^S' ? '' : '\v'
    if     cmdline =~# '\v^[Ssgv]$'       | return "KeepPatterns ".cmd.'/'.m
    elseif cmdline =~# '\v^\%[Ssgv]$'     | return "%KeepPatterns ".cmd.'/'.m
    elseif cmdline =~# "\\m^'<,'>[Ssgv]$"
      return "'<,'>KeepPatterns ".cmd.'/'.(cmd =~# '^S' ? '' : '\%V\v')
    elseif cmdline =~# '\v^.*[Ssgv]/%(\\\%V)?\\v$'
      let cmd = substitute(cmdline, '\v(^.*[Ssgv]/)%(\\\%V)?\\v', '\1/', '')
      let cmd = substitute(cmd, 'KeepPatterns \([Ssgv]//\)', '\1', '')
      return cmd
    elseif cmdline =~# '\v^'.s:range_pattern.'[Ssgv]$'
      return matchstr(cmdline, '\v^'.s:range_pattern)."KeepPatterns ".cmd.'/'.m
    endif
  endif
  let cmdstart = strpart(cmdline, 0, getcmdpos() - 1)
  let cmdend = strpart(cmdline, getcmdpos() - 1)
  call setcmdpos(getcmdpos() + 1)
  return cmdstart.'/'.cmdend
endfunction " }}}

" Function abbreviations
function! vimtools#FuncAbbrevs() " {{{
  let cmds = strpart(getcmdline(), 0, getcmdpos() - 1)
  if getcmdtype() =~ '[:=>]'
    let cmd = getcmdline()
    if     cmds=~'\v<nr2%[cha]$'     |let cmds=substitute(cmds,'\v<nr2%[cha]$','nr2char(','')
    elseif cmds=~'\v<ch2%[nr]$'      |let cmds=substitute(cmds,'\v<ch2%[n]$','char2nr(','')
    elseif cmds=~'\v<getl%[in]$'     |let cmds=substitute(cmds,'\v<getl%[in]$','getline(','')
    elseif cmds=~'\v<sys%[te]$'      |let cmds=substitute(cmds,'\v<sys%[te]$','system(','')
    elseif cmds=~'\v<pr%[in]$'       |let cmds=substitute(cmds,'\v<pr%[in]$','printf(','')
    elseif cmds=~'\v<ex%[pand]$'     |let cmds=substitute(cmds,'\v<ex%[pand]$','expand(','')
    elseif cmds=~'\v<s%[ubstitute]$' |let cmds=substitute(cmds,'\v<s%[ubstitute]$','substitute(','')
    else                             |let cmds.='('
    endif
  else
    let cmds.='('
  endif
  let cmdend = strpart(getcmdline(), getcmdpos() - 1)
  if getcmdtype() != '='
    call setcmdpos(len(cmds) + 1)
  endif
  return cmds.cmdend
endfunction " }}}

function! vimtools#opfunc(type) abort " {{{
  let g:first_op = 0
  let g:repeat_op = &opfunc
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
  let left_save = getpos("'<")
  let right_save = getpos("'>")
  let vimode_save = visualmode()
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    if a:type =~ '^\d\+$'
      silent exe 'normal! ^v'.a:type.'$hy'
    elseif a:type =~# '^.$'
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type ==# 'line'
      silent exe "normal! '[V']y"
    elseif a:type ==# 'block'
      silent exe "normal! `[\<C-V>`]y"
    elseif a:type ==# 'visual'
      silent exe "normal! gvy"
    else
      silent exe "normal! `[v`]y"
    endif
    redraw
    return @@
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
    exe "normal! " . vimode_save . "\<Esc>"
    call setpos("'<", left_save)
    call setpos("'>", right_save)
  endtry
endfunction " }}}

function! vimtools#SourceMotion(type) " {{{
  let input = vimtools#opfunc(a:type)
  let tmpfile = tempname()
  let lines = split(input, '\n')
  if exists('*scriptease#scriptid')
    let sid = scriptease#scriptid('%')
    if sid
      let pat = '\v(<s:|\<SID\>)\h(\w*#)*\w*\ze\('
      for line in filter(copy(lines), 'v:val =~ pat')
        let name = matchstr(line, pat)[2:]
        call map(lines,
            \ "substitute(v:val, '\\V\\C\\(s:\\|<SID>\\)'.name,
            \             '<SNR>'.sid.'_'.name, 'g')")
      endfor
    endif
  endif
  call writefile(lines, tmpfile)
  execute "source ".tmpfile
  call delete(tmpfile)
endfunction " }}}

" Turn off diffs automatically
function! vimtools#DiffRestore() abort " {{{
  " From tpope/vim-fugitive
  let restore = 'setlocal nodiff noscrollbind'
      \ . ' scrollopt=' . &l:scrollopt
      \ . (&l:wrap ? ' wrap' : ' nowrap')
      \ . ' foldlevel=999'
      \ . ' foldmethod=' . &l:foldmethod
      \ . ' foldcolumn=' . &l:foldcolumn
      \ . ' foldlevel=' . &l:foldlevel
      \ . (&l:foldenable ? ' foldenable' : ' nofoldenable')
  if has('cursorbind')
    let restore .= (&l:cursorbind ? ' ' : ' no') . 'cursorbind'
  endif
  return restore
endfunction " }}}

function! vimtools#DiffThis() " {{{
  if !&diff && &buftype ==# ''
    let w:vimtools_diff_restore = vimtools#DiffRestore()
    let b:vimtools_diff_restore = w:vimtools_diff_restore
    diffthis
    augroup vimtools_diff
      autocmd!
      autocmd BufWinLeave * if getwinvar(bufwinnr(+expand('<abuf>')), '&diff') &&
          \ !empty(getwinvar(bufwinnr(+expand('<abuf>')), 'vimtools_diff_restore')) &&
          \ vimtools#DiffCount() == 2 | call Windo('call vimtools#DiffOff()') |
          \ call vimtools#DiffOff(+expand('<abuf>')) | endif
      autocmd BufWinEnter * if getwinvar(bufwinnr(+expand('<abuf>')), '&diff') &&
          \ !empty(getwinvar(bufwinnr(+expand('<abuf>')), 'vimtools_diff_restore')) &&
          \ vimtools#DiffCount() == 1 | call vimtools#DiffOff() | endif
    augroup END
  endif
endfunction " }}}

function! vimtools#DiffOff(...) " {{{
  if a:0
    augroup vimtools_diff_buffer
      autocmd!
      execute 'autocmd vimtools_diff_buffer BufEnter,BufWinEnter '.
          \ '<buffer='.a:1.'> call vimtools#DiffOff() |'
          \ 'autocmd! vimtools_diff_buffer'
    augroup END
  endif
  if exists('w:vimtools_diff_restore')
    execute w:vimtools_diff_restore
    unlet w:vimtools_diff_restore
  elseif exists('b:vimtools_diff_restore')
    execute b:vimtools_diff_restore
    unlet b:vimtools_diff_restore
  elseif &diff
    diffoff
  endif
  augroup vimtools_diff
    autocmd!
  augroup END
endfunction " }}}

function! vimtools#DiffCount() " {{{
  return len(filter(range(1, winnr('$')),
      \ '!empty(getwinvar(v:val, "vimtools_diff_restore"))'))
endfunction " }}}

function! vimtools#ToggleDiff() " {{{
  if &diff || exists('w:vimtools_diff_restore')
    call Windo('call vimtools#DiffOff()') | echo 'DiffOff'
  else
    call Windo('call vimtools#DiffThis()') | echo 'DiffThis'
  endif
endfunction " }}}

function! vimtools#CmdlineComplete(arglead, cmdline, cursorpos) " {{{
  let results = []
  if &filetype ==# 'python' && exists('*IPythonCmdComplete')
    try
      let results = IPythonCmdComplete(a:arglead, a:cmdline, a:cursorpos)
    catch
    endtry
  endif
  let pattern = '\v\c^(\\[cmv<])*\<?|\\?\>$'
  let hist = map(range(1, min([+&history, 500])),
      \ '[substitute(histget("search", -v:val), pattern, "", "g"),
      \   histget("input", -v:val)]')
  return s:List.uniq(results + filter(s:List.flatten(hist),
      \ "v:val =~ '\\S' && stridx(tolower(v:val), tolower(a:arglead)) == 0"))
endfunction " }}}

" Start completion with a temporary completefunc
let s:completefuncs = get(s:, 'completefuncs', {}) " {{{
function! vimtools#CompleteStart(func) abort
  let s:completefuncs[bufnr('%')] = &l:completefunc
  let &l:completefunc = a:func
  augroup vimtools_complete_start
    autocmd! * <buffer>
    autocmd InsertEnter,InsertLeave <buffer>
        \ call setbufvar(+expand('<abuf>'), '&completefunc',
        \                s:completefuncs[expand('<abuf>')]) |
        \ autocmd! vimtools_complete_start * <buffer>
  augroup END
  return "\<C-x>\<C-u>\<C-p>"
endfunction " }}}

" vim:set et ts=2 sts=2 sw=2 fdm=marker:
