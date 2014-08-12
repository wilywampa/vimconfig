if exists("b:did_matlab_run")
    finish
endif

let b:did_matlab_run=1

if !exists('g:matlab_dict')
  if has("mac") || has("win16") || has("win32") || has("win64")
    let g:matlab_dict = expand('~/Documents/MATLAB/dict.m')
  elseif system('echo $OSTYPE') =~ 'cygwin'
    let g:matlab_dict =
        \ system('cygpath -u "$USERPROFILE/Documents/MATLAB/dict.m" | tr -d \\n')
  else
    let g:matlab_dict = expand('~/MATLAB/dict.m')
  endif
endif

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
        exec 'sil !start "'.g:runmatlab_exe.'" "'.g:matlab_path.'\gendict.m"'
        exec 'sil !start "'.g:runmatlab_exe.'" "'.g:matlab_path.'\clearfun.m"'
    endfunc

elseif system('echo $OSTYPE') =~ 'cygwin'

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
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText("clearfun; cd ".expand('%:p:h')."; "
            \.expand('%:t:r')."; gendict; clearfun")
        call VimuxSendKeys("\<CR>")
    endfunc

    func! s:RunLinesMATLAB(visual, ...)
        call VimuxOpenRunner()
        if a:visual
            let start = line("'<")
            let end = line("'>")
        else
            let start = line('.')
            let end = a:1 ? line('.') + a:1 - 1 : start
        endif
        call VimuxSendKeys("\<C-c>")
        for line in range(start, end)
            call VimuxSendText(getline(line))
            call VimuxSendKeys("\<CR>")
        endfor
    endfunc

    func! s:UpdateDictionaryMATLAB()
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText("gendict")
        call VimuxSendKeys("\<CR>")
    endfunc

    func! s:GetHelpMATLAB()
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText('help '.expand('<cword>'))
        call VimuxSendKeys("\<CR>")
        VimuxZoomRunner
    endfunc

    func! s:PrintVarMATLAB()
        call SaveRegs()
        normal! gvy
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText(@")
        call VimuxSendKeys("\<CR>")
        call RestoreRegs()
    endfunc

    nmap <silent> <buffer> <Leader>x :<C-u>call <SID>RunLinesMATLAB(0, v:count)<CR>
    vmap <silent> <buffer> <Leader>x :<C-u>call <SID>RunLinesMATLAB(1)<CR>
    nmap <silent> <buffer> K :<C-u>call <SID>GetHelpMATLAB()<CR>
    vmap <silent> <buffer> <C-p> :<C-u>call <SID>PrintVarMATLAB()<CR>
endif

if !exists('*<SID>ShowDictionary')
    func s:ShowDictionary()
        execute "silent keepalt botright vertical split ".g:matlab_dict
        vertical resize 50
        setlocal winfixwidth readonly nomodifiable
        nnoremap <buffer> q :bd<CR>
        wincmd p
    endfunc
endif

if !exists('*<SID>ToggleDictionary')
    func! s:ToggleDictionary()
        let win = bufwinnr(g:matlab_dict)
        if win != -1
            execute win."wincmd w"
            bdelete
            wincmd p
        else
            call <SID>ShowDictionary()
        endif
    endfunc
endif

nmap <silent> <buffer> <Leader>m :call <SID>ToggleDictionary()<CR>
nmap <silent> <buffer> <F5> :update<CR>:call <SID>RunMATLAB()<CR>
imap <silent> <buffer> <F5> <Esc><F5>
nmap <silent> <buffer> <S-F5> :call <SID>UpdateDictionaryMATLAB()<CR>
imap <silent> <buffer> <S-F5> <Esc><S-F5>

augroup MATLAB
  autocmd!
  autocmd CmdwinEnter @
      \ if getbufvar(bufnr('#'), '&filetype') == 'matlab' |
      \     let &filetype = 'matlab' |
      \ endif
augroup END

set omnifunc=matlabcomplete#complete
