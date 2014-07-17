if exists("did_load_filetypes")
    finish
endif

augroup filetypedetect
    autocmd! BufRead,BufNewFile *.ino           setf arduino
    autocmd! BufRead,BufNewFile */arduino/*.cpp setf arduino
    autocmd! BufRead,BufNewFile */arduino/*.h   setf arduino
    autocmd! BufRead,BufNewFile *.pde           setf processing
    autocmd! BufRead,BufNewFile *.todo          setf todo
    autocmd! BufRead,BufNewFile *.applescript   setf applescript
    autocmd! BufRead,BufNewFile *.scpt          setf applescript
    autocmd! BufRead,BufNewFile *.conf          setf conf
    autocmd! BufRead,BufNewFile [0-9]\\\{1,\}.*
       \ if getline(1) == 'To: vim_dev@googlegroups.com' | setf diff | endif
augroup END
