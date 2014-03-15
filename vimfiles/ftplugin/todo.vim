" Vim ftplugin file
" Language: Todo List
" Author: Jacob Niehus

if (exists("b:did_ftplugin"))
  finish
endif

let b:did_ftplugin = 1

nnoremap <silent> <buffer> \o :s/(.)/(O)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>
nnoremap <silent> <buffer> \x :s/(.)/(X)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>
nnoremap <silent> <buffer> \/ :s/(.)/(✓)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>
xnoremap <silent> <buffer> \o :s/(.)/(O)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>
xnoremap <silent> <buffer> \x :s/(.)/(X)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>
xnoremap <silent> <buffer> \/ :s/(.)/(✓)<CR>:call histdel("search",-1)<CR>:let @/=histget("search",-1)<CR>:nohl<CR>

setlocal wrap linebreak
