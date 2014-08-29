" Vim syntax file
" Language: Todo List
" Author: Jacob Niehus

if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "todo"

syn match todoStringIncomplete '.*$' contained
syn match todoStringComplete '.*$' contained
syn match todoStringCancelled '.*$' contained
syn match todoCheckboxIncomplete '(O)' nextgroup=todoStringIncomplete
syn match todoCheckboxComplete '([\\✓])' nextgroup=todoStringComplete
syn match todoCheckboxCancelled '(X)' nextgroup=todoStringCancelled
syn match todoIndent '\s*' nextgroup=todoCheckboxIncomplete,todoCheckboxComplete,todoCheckboxCancelled
syn match todoComment '[#@].*$' contained
syn match todoSectionTitle '--\s.*\s--' contained
syn region todoLine start="^" end="$" fold transparent contains=ALL

augroup todoSyntax
    autocmd!
    autocmd ColorScheme * call <SID>SetHighlights()
augroup END

func! s:SetHighlights()
    hi def todoStringIncomplete ctermfg=167 guifg=#cf6a4c
    hi def todoStringComplete ctermfg=34 guifg=#00cc33
    hi def todoStringCancelled ctermfg=22 guifg=#006633
    hi def link todoCheckboxIncomplete todoStringIncomplete
    hi def link todoCheckboxComplete todoStringComplete
    hi def link todoCheckboxCancelled todoStringCancelled
    hi def link todoSectionTitle Type
    hi def link todoComment Comment
endfunc
call <SID>SetHighlights()
