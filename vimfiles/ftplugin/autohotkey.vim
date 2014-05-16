if exists("b:did_ftplugin")
    finish
endif

let b:did_ftplugin=1

let hasWin=has("win16") || has("win32") || has("win64")

if hasWin
    map <silent> <buffer> <F5> :update<CR>:exec 'silent !start /b "'.expand('%:p')'"'<CR>
else
    map <silent> <buffer> <F5> :update<CR>:call system('cygstart `cygpath -w "'.expand('%:p').'"`')<CR>
endif

setlocal smartindent
