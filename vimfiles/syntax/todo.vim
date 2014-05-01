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
syn match todoSectionTitle '--.*--' contained
syn region todoLine start="^" end="$" fold transparent contains=ALL

hi def link todoCheckboxIncomplete PreProc
hi def link todoCheckboxComplete Title
hi def link todoCheckboxCancelled StringDelimiter
hi def link todoStringIncomplete PreProc
hi def link todoStringComplete Title
hi def link todoStringCancelled StringDelimiter
hi def link todoSectionTitle Type
hi def link todoComment Comment
