" Vim syntax file
" Language: Todo List
" Author: Jacob Niehus

if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "todo"

syn match todoStringIncomplete '.*$' contained
syn match todoStringComplete '.*$' contained
syn match todoCheckboxIncomplete '(O)' nextgroup=todoStringIncomplete
syn match todoCheckboxComplete '([X\\✓])' nextgroup=todoStringComplete
syn match todoIndent '\s*' nextgroup=todoCheckboxIncomplete,todoCheckboxComplete
syn match todoComment '[#@].*$' contained
syn match todoSectionTitle '--.*--' contained
syn region todoLine start="^" end="$" fold transparent contains=ALL

hi def link todoCheckboxComplete Identifier
hi def link todoCheckboxIncomplete PreProc
hi def link todoStringIncomplete Special
hi def link todoStringComplete Identifier
hi def link todoSectionTitle Statement
hi def link todoComment Comment
