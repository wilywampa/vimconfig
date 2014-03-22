" FILE:   timing.vim - stopwatch timing of vim commands
" Author: Yakov Lerner 
" Last Change: 2006-04-28

" SYNOPSIS:
"   Measure time it takes vim to execute commands:
"
"     TIM 2000 let x=0 "How much time is takes to 'x=0' 20000 times ?
"
"   If first argument after TIM is a number, it is treated
"   as repetiion count. If first argument is not a number,
"   the command is executed once.
"   Multiple commands, separated by bars(|) can be used under TIM command:
"     TIM 100 e xxx | bd  "How much time it takes to open and close the buffer
"
" INSTALLATION:
"   Copy file timing.vim into your .vim/plugin directory.
"   Or simply source timing.vim: :so timing.vim

if exists("g:timing_command") | finish | endif
let g:timing_command = 1


command! -nargs=* TIME :call TIMING(<q-args>)

function! TIMING(count_and_cmd) range
    let k = 0

    " if argument begins with digit, assume it's counter
    if a:count_and_cmd[0] =~ '[0-9]' 
	    let repeat = 0+substitute(a:count_and_cmd,'^\([0-9]*\).*$','\1', '')
	    let cmd = substitute(a:count_and_cmd,'^[0-9]* *','', '')
	else
	    let repeat = 1
	    let cmd=a:count_and_cmd
    endif

    let start=reltime()
    while k < repeat
	    exe cmd
	    let k=k+1
    endw
    let time=reltimestr(reltime(start))
    echo "Execution took " . time . " sec. (count=".repeat.")"
endfu

