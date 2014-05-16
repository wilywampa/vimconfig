" Vim ftplugin file
" Language: Todo List
" Author: Jacob Niehus

if (exists("b:did_ftplugin"))
    finish
endif

let b:did_ftplugin = 1

func! s:DoIt(type,...)
    if a:0
        let [lnum1, lnum2] = [a:type, a:1]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    for l:lnum in range(lnum1, lnum2)
        let l:line1 = getline(l:lnum)
        let l:line2 = substitute(l:line1,'\(^\s*\)\@<=(.)','('.s:c.')','')
        if l:line1 != l:line2
            call setline(l:lnum,l:line2)
        endif
    endfor
endfunc

func! s:SetC(c)
    let s:c = a:c
endfunc

nnoremap <silent> <buffer> \// :<C-u>call <SID>SetC('✓')<Bar>set opfunc=<SID>DoIt<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent> <buffer> \/  :<C-u>call <SID>SetC('✓')<Bar>set opfunc=<SID>DoIt<CR>g@
xnoremap <silent> <buffer> \/  :<C-u>call <SID>SetC('✓')<Bar>call <SID>DoIt(line("'<"),line("'>"))<CR>

nnoremap <silent> <buffer> \oo :<C-u>call <SID>SetC('O')<Bar>set opfunc=<SID>DoIt<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent> <buffer> \o  :<C-u>call <SID>SetC('O')<Bar>set opfunc=<SID>DoIt<CR>g@
xnoremap <silent> <buffer> \o  :<C-u>call <SID>SetC('O')<Bar>call <SID>DoIt(line("'<"),line("'>"))<CR>

nnoremap <silent> <buffer> \xx :<C-u>call <SID>SetC('X')<Bar>set opfunc=<SID>DoIt<Bar>exe 'norm! 'v:count1.'g@_'<CR>
nnoremap <silent> <buffer> \x  :<C-u>call <SID>SetC('X')<Bar>set opfunc=<SID>DoIt<CR>g@
xnoremap <silent> <buffer> \x  :<C-u>call <SID>SetC('X')<Bar>call <SID>DoIt(line("'<"),line("'>"))<CR>

nnoremap <buffer> ,o o(O)<Space>
nnoremap <buffer> ,O O(O)<Space>

setlocal wrap linebreak
setlocal commentstring=#%s
