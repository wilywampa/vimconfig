" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#SynNames(...) abort
  if a:0
    let [line, col] = [a:1, a:2]
  else
    let [line, col] = [line('.'), col('.')]
  endif
  return reverse(map(synstack(line, col), 'synIDattr(v:val,"name")'))
endfunction

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#HelpTopic()
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
endfunction

" From tpope's scriptease: https://github.com/tpope/vim-scriptease
function! vimtools#EchoSyntax(count)
  if a:count
    let name = get(vimtools#SynNames(), a:count-1, '')
    if name !=# ''
      return 'syntax list '.name
    endif
  else
    echo join(vimtools#SynNames(), ' ')
  endif
  return ''
endfunction

" Open in same window if current tab is empty, or else open in new window
function! vimtools#OpenHelp(topic)
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
endfunction

function! vimtools#OpenHelpVisual()
  call SaveRegs()
  return (g:inCmdwin ? "y:q\<CR>" : "y").":Help \<C-r>\"\<CR>:call RestoreRegs()\<CR>"
endfunction

function! vimtools#TabUsed()
  return strlen(expand('%')) || line('$')!=1 || getline(1)!='' || winnr('$')>1
endfunction

function! vimtools#SwitchToOrOpen(fname)
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
endfunction

function! vimtools#ResizeWindow(type)
  if winnr('$') == 1 | return | endif
  let eventignore_save = &eventignore
  set eventignore=all
  let startwin = winnr()
  try
    wincmd l
    let win_on_right = winnr() == startwin || &winfixwidth
    execute startwin."wincmd w"
    wincmd j
    let win_on_bottom = winnr() == startwin || &winfixheight
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
endfunction

" Move cursor using key until on non-concealed text
function! vimtools#conceal_move(key)
  execute "normal ".a:key
  let cnt = 0
  while synconcealed(line('.'), col('.'))[0] && cnt < 20
    let cnt = cnt + 1
    execute "normal ".a:key
  endwhile
endfunction

" Display file structure with dircolors
function! vimtools#Tree(...)
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
endfunction

" Make [[, ]], [], and ][ work when { is not in first column
function! vimtools#SectionJump(type, v)
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
endfunction
function! vimtools#SectionJumpMaps()
  if search('\m\C^\s*namespace', 'cnw') == 0 && search('\m\C^{', 'cnw') == 0
    for key in ['[[', '][', ']]', '[]']
      exe "noremap  <silent> <buffer> ".key." :<C-u>call vimtools#SectionJump('".key."',0)<CR>"
      exe "xnoremap <silent> <buffer> ".key." :<C-u>call vimtools#SectionJump('".key."',1)<CR>"
    endfor
  endif
endfunction

" Make pasted text have one blank line above and below
function! vimtools#MakeParagraph()
  call SaveRegs()
  let foldenable_save = &foldenable | set nofoldenable
  let l1 = nextnonblank(line("'["))
  let l2 = prevnonblank(line("']"))
  let lines = l2 - l1 + 1
  let l3 = nextnonblank(l2 + 1)

  if l3 > l2
    silent execute "keeppatterns ".l2.",".l3."g/^\\s*$/d"
    call append(l2, [""])
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
      end
    endif
  endif

  let &foldenable = foldenable_save
  call RestoreRegs()
endfunction

" Search (not) followed/preceded by
function! vimtools#FollowedBy(not) abort
  let s1 = input("Main: ")
  let s1 = substitute(len(s1) ? s1 : @/,'\m\c^\\v','','')
  let s1 = substitute(s1, '\m\\<\(.*\)\\>', '<\1>', '')
  let s2 = substitute(input((a:not ? 'Not f' : 'F').'ollowed by: '),'\m\c^\\v','','')
  let @/ = '\v\zs('.s1.')(.*'.s2.')@'.(a:not ? '!' : '=').'\ze.*$'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction

function! vimtools#PrecededBy(not) abort
  let s1 = input("Main: ")
  let s1 = substitute(len(s1) ? s1 : @/,'\m\c^\\v','','')
  let s1 = substitute(s1, '\m\\<\(.*\)\\>', '<\1>', '')
  let s2 = substitute(input((a:not ? 'Not p' : 'P').'receded by: '),'\m\c^\\v','','')
  let @/ = '\v^.*(('.s2.').*)@<'.(a:not ? '!' : '=').'\zs('.s1.')'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction

" Don't overwrite pattern with substitute command
function! vimtools#KeepPatterns(line1, line2, cmd)
  let pat = @/
  try
    if (a:cmd[0] == 'g' || a:cmd[0] == 'v') && a:line1 == a:line2
      execute a:cmd
    else
      execute a:line1.','.a:line2.a:cmd
    endif
    let g:lsub_pat = @/
    let b = '((\\)@<!\\)' " Unescaped backslash
    let l:subs_pat = '\v\C^s%[ubstitute]/([^/]|'.b.'@<=/)*'.b.'@<!/'
    if a:cmd =~ '\v\C^s%[ubstitute]/([^/]|'.b.'@<=/)[^/]*('.b.'@<!\/)?$'
      " Command has form %s/pat or %s/pat/
      let g:lsub_rep = ''
    else
      let g:lsub_rep=substitute(a:cmd,l:subs_pat.'\v\ze([^/]|'.b.'@<=/)*','','')
      let g:lsub_rep=substitute(g:lsub_rep,'\v([^/]|'.b.'@<=/)*\zs'.b.'@<!/.{-}$','','')
    endif
    if a:cmd =~ '\v'.b.'@<!/.*'.b.'@<!/.*'.b.'@<!/'
      let g:lsub_flags=substitute(a:cmd,'\v^.*\\@<!/\ze.{-}$','','')
    else
      let g:lsub_flags=''
    endif
  finally
    let @/ = pat
  endtry
endfunction

let s:range_pattern = '((\d+|\.|\$|''\a)(,(\d+|\.|\$|''\a))?)'
function! vimtools#KeepPatternsSubstitute()
  let cmdline = getcmdline()
  if getcmdtype() == ':'
    let cmd = cmdline[match(cmdline,'\a')]
    if     cmdline =~# '\v^[sgv]$'       | return "KeepPatterns ".cmd."/\\v"
    elseif cmdline =~# '\v^\%[sgv]$'     | return "%KeepPatterns ".cmd."/\\v"
    elseif cmdline =~# "\\m^'<,'>[sgv]$" | return "'<,'>KeepPatterns ".cmd."/\\%V\\v"
    elseif cmdline =~# '\v^.*[sgv]/%(\\\%V)?\\v$'
      let cmd = substitute(cmdline, '\v(^.*[sgv]/)%(\\\%V)?\\v', '\1/', '')
      let cmd = substitute(cmd, 'KeepPatterns \([sgv]//\)', '\1', '')
      return cmd
    elseif cmdline =~# '\v^'.s:range_pattern.'[sgv]$'
      return matchstr(cmdline, '\v^'.s:range_pattern)."KeepPatterns ".cmd."/\\v"
    endif
  endif
  let cmdstart = strpart(cmdline, 0, getcmdpos() - 1)
  let cmdend = strpart(cmdline, getcmdpos() - 1)
  call setcmdpos(getcmdpos() + 1)
  return cmdstart.'/'.cmdend
endfunction

" Function abbreviations
function! vimtools#FuncAbbrevs()
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
    endif
  endif
  let cmdend = strpart(getcmdline(), getcmdpos() - 1)
  if getcmdtype() =~ '[:>]'
    call setcmdpos(len(cmds) + 1)
  endif
  return cmds.cmdend
endfunction

function! vimtools#opfunc(type) abort
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
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
  endtry
endfunction

function! vimtools#SourceMotion(type)
  let input = vimtools#opfunc(a:type)
  let tmpfile = tempname()
  call writefile(split(input, '\n'), tmpfile)
  execute "source ".tmpfile
  call delete(tmpfile)
endfunction

" vim:set et ts=2 sts=2 sw=2:
