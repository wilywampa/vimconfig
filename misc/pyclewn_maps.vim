nnoremap <M-b> :execute "C break ".expand('%:p').":".line('.')<CR>
nnoremap <buffer> <M-d> :C down<CR>
nnoremap <M-e> :execute "C clear ".expand('%:p').":".line('.')<CR>
nnoremap <buffer> <M-n> :C next<CR>
nnoremap <buffer> <C-n> :C next<CR>
nnoremap <buffer> <M-p> :execute "C print ".expand('<cword>')<CR>
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
nnoremap <buffer> <M-w> :resize 15<CR>:set winfixheight<CR>
cnoreabbrev <expr> Cp ((getcmdtype()==':'&&getcmdpos()<=3)?'Cprint':'Cp')
