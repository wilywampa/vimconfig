let s:MODELINE_RE = '\v^\s*#\s+%(pylama:)\s*(%(\w*\=\_[^: \t\r]+:?)+)'

function! pylama_ignores#get(buffer) abort " {{{
    if !exists('g:ale_extra_pylama_ignores')
        let g:ale_extra_pylama_ignores = []
    endif
    try
        let l:ignore = copy(ale#Var(a:buffer, 'extra_pylama_ignores'))
    catch
        let l:ignore = []
    endtry
    let l:modelines = filter(getbufline(a:buffer, 1, '$'),
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

function! pylama_ignores#is_ignored(ignore, item) abort " {{{
    if empty(a:ignore)
        return v:false
    endif
    for l:i in a:ignore
        if stridx(a:item.code, l:i) == 0
            return v:true
        endif
    endfor
    return v:false
endfunction " }}}

function! pylama_ignores#handle(handler, buffer, lines) abort " {{{
    let l:output = call(a:handler, [a:buffer, a:lines])
    let l:ignore = pylama_ignores#get(a:buffer)
    return filter(l:output, {idx, val ->
        \ !pylama_ignores#is_ignored(l:ignore, val)})
endfunction " }}}
