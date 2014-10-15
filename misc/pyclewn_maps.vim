nnoremap <buffer> <M-b> :execute "C break ".expand('%:p').":".line('.')<CR>
nnoremap <buffer> <M-d> :C down<CR>
nnoremap <buffer> <M-e> :execute "C clear ".expand('%:p').":".line('.')<CR>
nnoremap <buffer> <M-n> :C next<CR>
nnoremap <buffer> <C-n> :C next<CR>
nnoremap <buffer> <M-p> :execute "C print ".expand('<cword>')<CR>
nnoremap <buffer> <M-u> :C up<CR>
nnoremap <buffer> <M-x> :execute "C print *".expand('<cword>')<CR>
nnoremap <buffer> <M-z> :C sigint<CR>
nnoremap <buffer> <M-A> :C info args<CR>
nnoremap <buffer> <M-B> :C info breakpoints<CR>:Ccwindow<CR>
nnoremap <buffer> <M-c> :C continue<CR>
nnoremap <buffer> <M-F> :C finish<CR>
nnoremap <buffer> <M-L> :C info locals<CR>
nnoremap <buffer> <M-Q> :C quit<CR>
nnoremap <buffer> <M-R> :C run<CR>
nnoremap <buffer> <M-s> :C step<CR>
nnoremap <buffer> <M-W> :C where<CR>
nnoremap <buffer> <M-X> :execute "C foldvar ."line('.')<CR>
vnoremap <buffer> <silent> <C-p> :<C-u>call SaveRegs()<CR>gvy:C print <C-r>"<CR>:call RestoreRegs()<CR>
vnoremap <buffer> <silent> <M-p> :<C-u>call SaveRegs()<CR>gvy:C print *<C-r>"<CR>:call RestoreRegs()<CR>
nnoremap <buffer> <M-w> :resize 15<CR>:set winfixheight<CR>
cnoreabbrev <expr> Cp ((getcmdtype()==':'&&getcmdpos()<=3)?'Cprint':'Cp')
