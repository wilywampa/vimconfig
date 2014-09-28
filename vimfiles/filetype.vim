if exists("did_load_filetypes")
    finish
endif

augroup filetypedetect
    autocmd! BufRead,BufNewFile *.ino           setf cpp
    autocmd! BufRead,BufNewFile *.pde           setf processing
    autocmd! BufRead,BufNewFile *.sml           setf xml
    autocmd! BufRead,BufNewFile *.todo          setf todo
    autocmd! BufRead,BufNewFile *.applescript   setf applescript
    autocmd! BufRead,BufNewFile *.scpt          setf applescript
    autocmd! BufRead,BufNewFile *.conf          setf conf
    autocmd! BufRead,BufNewFile [0-9]\\\{1,\}.*
       \ if getline(1) == 'To: vim_dev@googlegroups.com' | setf diff | endif

    autocmd! BufRead *.svn-base,svn-* if &diff && argc() == 2 |
        \     execute 'doautocmd filetypedetect BufRead '.argv(1) |
        \ endif
    autocmd! BufNewFile *.svn-base,svn-* if &diff && argc() == 2 |
        \     execute 'doautocmd filetypedetect BufNewFile '.argv(1) |
        \ endif
augroup END
