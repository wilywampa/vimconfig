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
    endfunc
    func! s:UpdateDictionaryMATLAB()
        exec 'sil !RunMATLAB "'.g:matlab_path.'\gendict.m"'
        exec 'sil !RunMATLAB "'.g:matlab_path.'\clearfun.m"'
    endfunc
else
    func! s:RunMATLAB()
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText("clearfun; cd ".expand('%:p:h')."; "
            \.expand('%:t:r')."; gendict; clearfun")
        call VimuxSendKeys("\<CR>")
    endfunc
    func! s:RunLineMATLAB()
        call VimuxOpenRunner()
        call VimuxSendKeys("\<C-c>")
        call VimuxSendText(substitute(getline('.'),';$',';;',''))
        call VimuxSendKeys("\<CR>")
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
    nmap <silent> <buffer> <Leader>x :<C-u>call <SID>RunLineMATLAB()<CR>
    nmap <silent> <buffer> K :<C-u>call <SID>GetHelpMATLAB()<CR>
    nnor <silent> <buffer> <Leader>: :VimuxPromptCommand<CR><C-f>:set ft=matlab<CR>
endif

nmap <silent> <buffer> <F5> :update<CR>:call <SID>RunMATLAB()<CR>
imap <silent> <buffer> <F5> <Esc><F5>
nmap <silent> <buffer> <S-F5> :update<CR>:call <SID>UpdateDictionaryMATLAB()<CR>
imap <silent> <buffer> <S-F5> <Esc><S-F5>

set omnifunc=matlabcomplete#complete
