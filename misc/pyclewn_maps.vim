nnoremap <M-b> :execute "C break ".expand('%:p').":".line('.')<CR>
nnoremap <M-d> :C down<CR>
nnoremap <M-e> :execute "C clear ".expand('%:p').":".line('.')<CR>
nnoremap <M-n> :C next<CR>
nnoremap <C-n> :C next<CR>
nnoremap <M-p> :execute "C print ".expand('<cword>')<CR>
nnoremap <M-u> :C up<CR>
nnoremap <M-x> :execute "C print *".expand('<cword>')<CR>
nnoremap <M-z> :C sigint<CR>
nnoremap <M-A> :C info args<CR>
nnoremap <M-B> :C info breakpoints<CR>
nnoremap <M-c> :C continue<CR>
nnoremap <M-F> :C finish<CR>
nnoremap <M-L> :C info locals<CR>
nnoremap <M-Q> :C quit<CR>
nnoremap <M-R> :C run<CR>
nnoremap <M-s> :C step<CR>
nnoremap <M-W> :C where<CR>
nnoremap <M-X> :execute "C foldvar ."line('.')<CR>
vnoremap <expr> <C-p> &filetype == 'python' ?
    \ "y:C print \<C-r>\"\<CR>" : "y:Cdisplay \<C-r>\"\<CR>"
vnoremap <M-p> y:Cdisplay<Space>*<C-r>"<CR>
cnoreabbrev <expr> Cp ((getcmdtype()==':'&&getcmdpos()<=3)?'Cprint':'Cp')
nnoremap <M-w> :res 10<CR>:set wfh<CR>
