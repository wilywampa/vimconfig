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
      exe l:helpWin.'wincmd w'
      setl bt=help
      exe 'help '.a:topic
    elseif (&columns > 160) && !l:split
        \ && (str2float(&columns) / str2float(&lines)) > 2.5
      " Open help in vertical split depending on window geometry
      exe 'vert help '.a:topic
    else
      exe 'aboveleft help '.a:topic
    endif
  else
    setl ft=help bt=help noma
    exe 'help '.a:topic
  endif
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
    execute "enew" | execute "file --tree--" | execute "set buftype=nowrite"
    autocmd VimLeavePre,VimLeave,QuitPre * if bufnr('--tree--')
        \ |   execute "bwipe! ".bufnr('--tree--')
        \ | endif
  else
    execute "buffer ".treenr | execute "AnsiEsc" | execute "normal! ggdG"
  endif
  if dir != getcwd() | execute "lcd ".dir | endif
  execute "silent read!cd ".dir."; tree -CQf"
  setlocal nomodified
  execute "AnsiEsc" | execute "normal! gg"
  syn match ansiConceal conceal '"'
  syn match ansiConceal conceal "\(\"\..*\/\)"
  nnoremap <silent> <buffer> j j0:call search('[[:alnum:]]')<CR>call vimtools#conceal_move('w')<CR>
  nnoremap <silent> <buffer> k k0:call search('[[:alnum:]]')<CR>call vimtools#conceal_move('w')<CR>
  nnoremap <buffer> <CR> gf
  nnoremap <silent> <buffer> ZZ :wincmd c<CR>
endfunction

" Make [[, ]], [], and ][ work when { is not in first column
function! vimtools#SectionJump(type, v)
  let l:count = v:count1
  let startpos = getpos('.')
  keepjumps if a:v | exe "norm! gv" | endif
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
  let l1 = nextnonblank(line("'["))
  let l2 = prevnonblank(line("']"))
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
  call RestoreRegs()
endfunction

" Search (not) followed/preceded by
function! vimtools#FollowedBy(not) abort
  let s1 = substitute(input('Main: '),'\m\c^\\v','','')
  let s2 = substitute(input((a:not ? 'Not f' : 'F').'ollowed by: '),'\m\c^\\v','','')
  let @/ = '\v\zs('.s1.')(.*'.s2.')@'.(a:not ? '!' : '=').'\ze.*$'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction
function! vimtools#PrecededBy(not) abort
  let s1 = substitute(input('Main: '),'\m\c^\\v','','')
  let s2 = substitute(input((a:not ? 'Not p' : 'P').'receded by: '),'\m\c^\\v','','')
  let @/ = '\v^.*(('.s2.').*)@<'.(a:not ? '!' : '=').'\zs('.s1.')'
  call histadd('/', @/) | normal! nzv
  set nohlsearch | set hlsearch | redraw!
  echo '/'.@/
endfunction

" Don't overwrite pattern with substitute command
function! vimtools#KeepPatterns(cmd)
  let pat = @/
  try
    execute a:cmd
    let g:lsub_pat = @/
    let l:subs_pat = '\v\C^[^/]*s%[ubstitute]/([^/]|\\@<=/)*\\@<!/'
    let g:lsub_rep=substitute(a:cmd,l:subs_pat.'\v\ze([^/]|\\@<=/)*','','')
    let g:lsub_rep=substitute(g:lsub_rep,'\v([^/]|\\@<=/)*\zs\\@<!/.{-}$','','')
    if a:cmd =~ '\v\\@<!/.*\\@<!/.*\\@<!/'
      let g:lsub_flags=substitute(a:cmd,'\v^.*\\@<!/\ze.{-}$','','')
    else
      let g:lsub_flags=''
    endif
  finally
    let @/ = pat
  endtry
endfunction
function! vimtools#KeepPatternsSubstitute()
  let cmdline = getcmdline()
  if getcmdtype() == ':'
    let cmd = cmdline[match(cmdline,'\a')]
    if cmdline =~ '\v^[sgv]$' | return "KeepPatterns ".cmd."/"
    elseif cmdline =~ '\v^\%[sgv]$' | return "KeepPatterns %".cmd."/"
    elseif cmdline =~ "\\m^'<,'>[sgv]$" | return "KeepPatterns '<,'>".cmd."/"
    endif
  endif
  let cmdstart = strpart(cmdline, 0, getcmdpos() - 1)
  let cmdend = strpart(cmdline, getcmdpos() - 1)
  call setcmdpos(getcmdpos() + 1)
  return cmdstart.'/'.cmdend
endfunction

" Function abbreviations
function! vimtools#FuncAbbrevs()
  let cmdstart = strpart(getcmdline(), 0, getcmdpos() - 1)
  if getcmdtype() =~ '[:=]'
    let cmd = getcmdline()
    if cmdstart =~ '\<nr2$' | return substitute(cmd, 'nr2', '&char(', '')
    elseif cmdstart =~ '\<ch2$' | return substitute(cmd, 'ch2', 'char2nr(', '')
    elseif cmdstart =~ '\<getl$' | return substitute(cmd, 'getl', '&ine(', '')
    elseif cmdstart =~ '\<sys$' | return substitute(cmd, 'sys', '&tem(', '')
    elseif cmdstart =~ '\<pr$' | return substitute(cmd, 'pr', '&intf(', '')
    endif
  endif
  let cmdend = strpart(getcmdline(), getcmdpos() - 1)
  call setcmdpos(getcmdpos() + 1)
  return cmdstart.'('.cmdend
endfunction

" vim:set et ts=2 sts=2 sw=2:
