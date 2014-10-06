if !has('python')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name'  : 'words',
    \ 'kind'  : 'keyword',
    \ 'mark'  : '[w]',
    \ 'hooks' : {},
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
    call <SID>UpdateWordList()
endfunction

function! s:source.gather_candidates(context)
    return pyeval('list(words)')
endfunction

function! neocomplete#sources#words#define()
    return s:source
endfunction

augroup words_complete
    autocmd!
    autocmd BufWinEnter,BufWrite * call <SID>UpdateWordList()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=4 sts=4 sw=4:
