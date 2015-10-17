if !has('python')
    function! neocomplete#sources#words#define()
        return {}
    endfunction
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name'       : 'words',
    \ 'kind'       : 'keyword',
    \ 'mark'       : '[w]',
    \ 'hooks'      : {},
    \ 'converters' : [],
    \ }

let s:checked = 0

python << EOF
import re
import vim
words = set()

def add_words(buffer):
    words.update(set(re.findall('\w{4,}', ' '.join(buffer[:]))))
EOF

function! s:UpdateWordList()
    let s:checked = 1
python << EOF
words.clear()
bufnrs = set()
for w in vim.windows:
    if w.buffer.number not in bufnrs:
        add_words(w.buffer)
        bufnrs.add(w.buffer.number)
altbuf = int(vim.eval('bufnr("#")'))
if altbuf > 0 and altbuf not in bufnrs:
    add_words(vim.buffers[altbuf])
EOF
endfunction

function! s:source.hooks.on_init(context)
    call s:UpdateWordList()
endfunction

function! s:source.gather_candidates(context)
    if !s:checked
        call s:UpdateWordList()
    endif
    return pyeval('list(words)')
endfunction

function! neocomplete#sources#words#define()
    return s:source
endfunction

function! neocomplete#sources#words#start()
    let s:completefunc = &l:completefunc
    setlocal completefunc=neocomplete#sources#words#complete
    augroup words_completefunc
        autocmd!
        autocmd InsertEnter,InsertLeave *
            \ let &l:completefunc = s:completefunc |
            \ autocmd! words_completefunc
        autocmd InsertCharPre * if v:char !~ '\w' |
            \ let &l:completefunc = s:completefunc |
            \ execute 'autocmd! words_completefunc'  | endif
    augroup END
    return "\<C-x>\<C-u>"
endfunction

function! neocomplete#sources#words#complete(findstart, base)
    if a:findstart
        let line = getline('.')
        let start = col('.')
        while start > 0
            let start -= 1
            if line[start-1] =~ '\w'
                continue
            else
                break
            endif
        endwhile
        return start
    else
        let results = []
        call s:UpdateWordList()
        python << EOF
base = vim.eval('a:base')
for word in words:
    if word.startswith(base):
        vim.command('call add(results, {"word": pyeval("word"),'
                                       '"menu": "[w]"})')
EOF
        return results
    endif
endfunction

augroup words_complete
    autocmd!
    autocmd InsertEnter * let s:checked = 0
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=4 sts=4 sw=4:
