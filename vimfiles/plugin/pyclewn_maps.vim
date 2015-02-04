if exists('pyclewn_maps_loaded')
    finish
endif

let pyclewn_maps_loaded = 1

function! s:set_print(flag)
    let s:print = a:flag
endfunction

function! s:PyclewnMaps()
    let s:is_pdb = !exists(':Cprint')

    if !exists('*s:ConditionalBreakpoint')
        function! s:ConditionalBreakpoint()
            let input = input("if ")
            if len(input > 0)
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
                    execute 'C '.(s:print ? 'print ' : '').
                        \ substitute(matchstr(line, '\S.*$'), '"', '\\"', 'g')
                endif
            endfor
            silent! call repeat#invalidate()
        endfunction
    endif

    nnoremap <M-b> :execute "C break ".expand('%:p').":".line('.')<CR>
    nnoremap g<M-b> :<C-u>call <SID>ConditionalBreakpoint()<CR>
    nnoremap <buffer> <M-d> :C down<CR>
    nnoremap <M-e> :execute "C clear ".expand('%:p').":".line('.')<CR>
    nnoremap <buffer> <M-n> :C next<CR>
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
    vnoremap <buffer> <silent> <C-p> :<C-u>call SaveRegs()<CR>gvy:C print <C-r>"<CR>:call RestoreRegs()<CR>
    vnoremap <buffer> <silent> <M-p> :<C-u>call SaveRegs()<CR>gvy:C print *<C-r>"<CR>:call RestoreRegs()<CR>
    vnoremap <buffer> <silent> <M-P> :<C-u>call SaveRegs()<CR>gvy:C display <C-r>"<CR>:call RestoreRegs()<CR>
    nnoremap <buffer> <M-w> :wincmd t<CR>:resize 15<CR>:set winfixheight wrap linebreak<CR>
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

    if exists('g:pyclewn_map_global') && g:pyclewn_map_global
        augroup pyclewn
            autocmd!
            autocmd BufEnter,WinEnter * call s:PyclewnMaps()
        augroup END
    endif
endfunction

nnoremap <Leader>pc :<C-u>call <SID>PyclewnMaps()<CR>
nnoremap <Leader><Leader>pc :<C-u>let g:pyclewn_map_global = 1<bar>call <SID>PyclewnMaps()<CR>
nnoremap <M-b> :<C-u>call <SID>PyclewnMaps()<CR>:execute "C break ".expand('%:p').":".line('.')<CR>
