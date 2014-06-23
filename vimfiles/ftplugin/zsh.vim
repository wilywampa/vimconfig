if exists("b:did_my_ftplugin")
    finish
endif

let b:did_my_ftplugin=1

if exists('$TMUX')
    nnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>ExecuteCommand(0, v:count)<CR>
    vnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>ExecuteCommand(1)<CR>

    func! s:ExecuteCommand(visual, ...)
        call VimuxOpenRunner()
        if a:visual
            let start = line("'<")
            let end = line("'>")
        else
            let start = line('.')
            let end = a:1 ? line('.') + a:1 - 1 : start
        endif
        call VimuxSendKeys("\<Esc>") | call VimuxSendKeys("S")
        for line in range(start, end)
            call VimuxSendText(substitute(getline(line),';$',';;',''))
            call VimuxSendKeys("\<Esc>") | call VimuxSendKeys("o")
        endfor
        call VimuxSendKeys("\<CR>")
    endfunc
endif
