if !has('python')
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

python << EOF
import re
import vim
words = set([])

def add_words(buffer):
    global words
    words = words.union(set(re.findall('\w{4,}', ' '.join(buffer[:]))))
EOF

function! s:UpdateWordList()
python << EOF
words = set([])
bufnrs = []
for w in vim.windows:
    if w.buffer.number not in bufnrs:
        add_words(w.buffer)
        bufnrs.append(w.buffer.number)
altbuf = int(vim.eval('bufnr("#")'))
if altbuf > 0 and altbuf not in bufnrs:
    add_words(vim.buffers[altbuf])
EOF
endfunction

function! s:source.hooks.on_init(context)
    call s:UpdateWordList()
endfunction

function! s:source.gather_candidates(context)
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
        autocmd CompleteDone,InsertEnter,InsertLeave *
            \ let &l:completefunc = s:completefunc |
            \ autocmd! words_completefunc
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
    autocmd BufWinEnter,BufWrite,CmdwinEnter,WinEnter * call s:UpdateWordList()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=4 sts=4 sw=4:
