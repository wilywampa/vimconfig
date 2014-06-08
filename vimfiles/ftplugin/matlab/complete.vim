if exists('b:did_matlab_complete')
    finish
endif
let b:did_matlab_complete=1

func! CompleteMATLAB(findstart, base)
    let l:iskeyword=&iskeyword
    set iskeyword+=.
    if a:findstart
        let l:line=getline('.')
        let l:start=col('.')-1
        while l:start > 0 && l:line[l:start-1] =~ '\w\|\.\|''\|('
            let l:start -= 1
        endwhile
        exec 'set iskeyword='.l:iskeyword
        return l:start
    else
        let l:results=[]
        let l:dictionaries=split(&dict,',')
        if l:dictionaries != [] && filereadable(l:dictionaries[0])
            let l:words=readfile(l:dictionaries[0])
            for l:word in l:words
                if l:word =~ '^'.a:base && l:word =~ '\.\((''\)\?'
                    call add(l:results, l:word)
                endif
            endfor
        endif
        exec 'set iskeyword='.l:iskeyword
        return l:results
    endif
endfunc
set omnifunc=CompleteMATLAB
