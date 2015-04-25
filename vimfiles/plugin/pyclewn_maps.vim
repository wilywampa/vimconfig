if exists('pyclewn_maps_loaded')
    finish
endif

let pyclewn_maps_loaded = 1

function! s:set_print(flag)
    let s:print = a:flag
endfunction

function! s:escape(string)
    return escape(a:string, '"|%#')
endfunction

function! s:PyclewnMaps()
    let s:is_pdb = !exists(':Cprint')

    if !exists('*s:ConditionalBreakpoint')
        function! s:ConditionalBreakpoint()
            let input = input("if ")
            if len(input) > 0
                let file = fnameescape(expand('%:p'))
                let line = line('.')
                if s:is_pdb
                    execute "C break ".file.":".line.", (".input.")"
                else
                    execute "C break ".file.":".line." if (".input.")"
                endif
            endif
        endfunction
    endif

    if !exists('*s:PdbRunMotion')
        function! s:PdbRunMotion(type)
            let input = vimtools#opfunc(a:type)
            for line in split(input, '\n')
                if line =~ '\S'
                    execute 'C '.((s:print || !s:is_pdb) ? 'print ' : '').
                        \ escape(matchstr(line, '\S.*$'), '"|')
                endif
            endfor
            silent! call repeat#invalidate()
        endfunction
    endif

    nnoremap <M-b> :execute "C break ".expand('%:p').":".line('.')<CR>
    nnoremap g<M-b> :<C-u>call <SID>ConditionalBreakpoint()<CR>
    nnoremap <buffer> <M-d> :C down<CR>
    nnoremap <M-e> :execute "C clear ".expand('%:p').":".line('.')<CR>
    nnoremap <buffer> <C-n> :C next<CR>
    nnoremap <buffer> <C-n> :C next<CR>
    nnoremap <buffer> <M-p> :execute "C print ".expand('<cword>')<CR>
    nnoremap <buffer> g<M-p> :execute "C call ".expand('<cword>').".print()"<CR>
    nnoremap <buffer> <M-P> :execute "C display ".expand('<cword>')<CR>
    nnoremap <M-u> :C up<CR>
    nnoremap <buffer> <M-x> :execute "C print *".expand('<cword>')<CR>
    nnoremap <M-z> :C sigint<CR>
    nnoremap <M-A> :C info args<CR>
    nnoremap <M-B> :C info breakpoints<CR>:Ccwindow<CR>
    nnoremap <M-c> :C continue<CR>
    nnoremap <M-F> :C finish<CR>
    nnoremap <M-L> :C info locals<CR>
    nnoremap <M-Q> :C quit<CR>
    nnoremap <M-R> :C run<CR>
    nnoremap <M-s> :C step<CR>
    nnoremap <M-W> :C where<CR>
    nnoremap <M-X> :execute "C foldvar ."line('.')<CR>
    vnoremap <buffer> <silent> <C-p> :<C-u>call SaveRegs()<CR>gvy:C print <C-r>=<SID>escape(@@)<CR><CR>:call RestoreRegs()<CR>
    vnoremap <buffer> <silent> <M-p> :<C-u>call SaveRegs()<CR>gvy:C print *<C-r>=<SID>escape(@@)<CR><CR>:call RestoreRegs()<CR>
    vnoremap <buffer> <silent> <M-P> :<C-u>call SaveRegs()<CR>gvy:C display <C-r>=<SID>escape(@@)<CR><CR>:call RestoreRegs()<CR>
    nnoremap <buffer> <silent> <M-w> :<C-u>wincmd t<bar>:resize 12<bar>:set winfixheight<bar>
        \ <C-r>=winnr('#') > 0 ? winnr('#').'wincmd w' : ''<CR><bar><C-r>=winnr().'wincmd w'<CR><CR>
    cnoreabbrev <expr> Cp ((getcmdtype()==':'&&getcmdpos()<=3)?'C print':'Cp')
    cnoreabbrev <expr> Cd ((getcmdtype()==':'&&getcmdpos()<=3)?'Cdisplay':'Cd')
    nnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>set_print(0)<bar>set opfunc=<SID>PdbRunMotion<CR>g@
    nnoremap <silent> <buffer> <Leader>xx :<C-u>call <SID>set_print(0)<bar>set opfunc=<SID>PdbRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    inoremap <silent> <buffer> <Leader>x  <Esc>:<C-u>call <SID>set_print(0)<bar>set opfunc=<SID>PdbRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    xnoremap <silent> <buffer> <Leader>x :<C-u>call <SID>set_print(0)<bar>call <SID>PdbRunMotion('visual')<CR>
    nnoremap <silent> <buffer> ,p :<C-u>call <SID>set_print(1)<bar>set opfunc=<SID>PdbRunMotion<CR>g@
    nnoremap <silent> <buffer> ,pp :<C-u>call <SID>set_print(1)<bar>set opfunc=<SID>PdbRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    inoremap <silent> <buffer> ,p  <Esc>:<C-u>call <SID>set_print(1)<bar>set opfunc=<SID>PdbRunMotion<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    xnoremap <silent> <buffer> ,p :<C-u>call <SID>set_print(1)<bar>call <SID>PdbRunMotion('visual')<CR>

    cnoreabbrev <expr> Cc ((getcmdtype()==':'&&getcmdpos()<=3)?'Ccontinue':'Cc')
    cnoreabbrev <expr> Cd ((getcmdtype()==':'&&getcmdpos()<=3)?'Cdisplay':'Cd')
    cnoreabbrev <expr> Cf ((getcmdtype()==':'&&getcmdpos()<=3)?'Cfile':'Cf')
    cnoreabbrev <expr> Ck ((getcmdtype()==':'&&getcmdpos()<=3)?'Ckill':'Ck')
    cnoreabbrev <expr> Cn ((getcmdtype()==':'&&getcmdpos()<=3)?'Cnext':'Cn')
    cnoreabbrev <expr> Cp ((getcmdtype()==':'&&getcmdpos()<=3)?'Cprint':'Cp')
    cnoreabbrev <expr> Cr ((getcmdtype()==':'&&getcmdpos()<=3)?'Crun':'Cr')
    cnoreabbrev <expr> Cs ((getcmdtype()==':'&&getcmdpos()<=3)?'Cstep':'Cs')

    augroup pyclewn
        autocmd!
        if exists('g:pyclewn_map_global') && g:pyclewn_map_global
            autocmd BufEnter,WinEnter * call s:PyclewnMaps()
        endif
    augroup END
endfunction

nnoremap <silent> <Leader>pc :<C-u>call <SID>PyclewnMaps()<CR>
nnoremap <silent> <Leader><Leader>pc :<C-u>let g:pyclewn_map_global = 1<bar>call <SID>PyclewnMaps()<CR>
nnoremap <silent> <M-b> :<C-u>call <SID>PyclewnMaps()<CR>:execute "C break ".expand('%:p').":".line('.')<CR>

augroup pyclewn
    autocmd!
    autocmd VimEnter * if exists(':C') == 2 |
        \     let g:pyclewn_map_global = 1  |
        \     call s:PyclewnMaps()          |
        \ endif
augroup END
