" Set up ignoring of pycodestyle warnings/errors
if exists('g:loaded_after_ftplugin_python')
    finish
endif

let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('*ale_linters#python#pycodestyle#GetCommand')
    silent! runtime! ale_linters/python/pycodestyle.vim
endif
if !exists('*ale_linters#python#pycodestyle#GetCommand')
    let g:loaded_after_ftplugin_python = 1
    finish
endif

let s:MODELINE_RE = '\v^\s*#\s+%(pylama:)\s*(%(\w*\=\_[^: \t\r]+:?)+)'

function! GetPylamaIgnores(buffer) abort " {{{
    try
        let l:ignore = ale#Var(a:buffer, 'extra_pycodestyle_ignores')
    catch
        let l:ignore = []
    endtry
    let l:modelines = filter(getbufline(a:buffer, 1, 25),
        \ {idx, val -> val =~? s:MODELINE_RE})
    if !empty(l:modelines)
        let l:match = substitute(l:modelines[0], s:MODELINE_RE, '\1', '')
        let l:groups = map(split(l:match, ':'),
            \ {idx, group -> split(group, '=')})
        for [l:name, l:value] in l:groups
            if l:name is? 'ignore'
                call extend(l:ignore, filter(split(l:value, ','),
                    \ {idx, val -> index(l:ignore, val) == -1}))
            endif
        endfor
    endif
    return l:ignore
endfunction " }}}

function! s:is_ignored(ignore, item) abort " {{{
    if empty(a:ignore)
        return 0
    endif
    for l:i in a:ignore
        if stridx(a:item.code, l:i) == 0
            return 1
        endif
    endfor
    return 0
endfunction " }}}

function! s:handle(buffer, lines) abort " {{{
    let l:output = ale_linters#python#pycodestyle#Handle(a:buffer, a:lines)
    let l:ignore = GetPylamaIgnores(a:buffer)
    return filter(l:output, {idx, val -> !s:is_ignored(l:ignore, val)})
endfunction " }}}

call ale#linter#Define('python', {
    \   'name': 'pycodestyle',
    \   'executable_callback': 'ale_linters#python#pycodestyle#GetExecutable',
    \   'command_callback': 'ale_linters#python#pycodestyle#GetCommand',
    \   'callback': function('s:handle'),
    \})

let g:loaded_after_ftplugin_python = 1

let &cpoptions = s:save_cpo
unlet s:save_cpo
