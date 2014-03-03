" Copyright 2014 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('CommentToolsLoaded')
    finish
endif

let CommentToolsLoaded=1

if !exists('g:findInComments')
    let g:findInComments=1
endif

" Replace C-style comments with asterisks (excepts newlines and spaces)
func! s:StripComments()
    " Save window, cursor, etc. positions
    let winSave=winsaveview()

    if v:version >= 703
        keepj silent! %s/\m\(\/\*\)\(\_.\{-}\)\(\*\/\)\|$t^/\=submatch(1)
            \ .substitute(submatch(2),'[^ \n]','*','g')
            \ .submatch(3)/g
    else
        keepj silent! %s/\m\(\/\*\)\(\_.\{-}\)\(\*\/\)\|$t^/\=submatch(1).
            \ substitute(substitute(substitute(submatch(2),' ',
            \ nr2char(1),'g'),'\p','*','g'),nr2char(1),' ','g')
            \ .submatch(3)/g
    endif

    keepj silent! %s/\m\(\/\/\)\(.*\)$\|$t^/\=submatch(1)
        \ .substitute(submatch(2),'[^ \n]','*','g')/g

    call histdel('/','\V$t^')

    " Restore window, cursor, etc. positions
    call winrestview(winSave)
endfunc

" Use StripComments functions to search in non-commented text only
func! s:FindNotInComment(direction)
    if v:version >= 703
        let undo_file = tempname()
        execute "wundo" undo_file
    endif

    " Save last search and last change for later use
    let search=@/
    let change=changenr()

    call s:StripComments()
    let @/=search

    " Jump to next or previous match depending on search direction and n/N
    let v:errmsg=""
    if (a:direction && g:sfsave) || (!a:direction && !g:sfsave)
        silent! normal! /
    else
        silent! normal! ?
    endif
    let errmsg=v:errmsg

    " Undo changes caused by StripComments
    let winSave=winsaveview()
    if change!=changenr()
        keepj normal! u
    endif
    call winrestview(winSave)

    if v:version >= 703 && filereadable(undo_file)
        silent execute "rundo" undo_file
        unlet undo_file
    endif

    if errmsg != ""
        echohl ErrorMsg
        redraw
        echo errmsg
        echohl None
    endif
endfunc

func! s:UnmapCR()
    silent! cunmap <CR>
    silent! cunmap <Esc>
    silent! cunmap <C-c>
endfunc

func! s:MapCR()
    cnoremap <silent> <CR> <CR>``:call <SID>FindNotInComment(1)<CR>:call <SID>MapN()<CR>:call <SID>UnmapCR()<CR>
    cnoremap <silent> <Esc> <Esc>:call <SID>UnmapCR()<CR>
    cnoremap <silent> <C-c> <C-c>:call <SID>UnmapCR()<CR>
endfunc

func! s:MapN()
    nnoremap <silent> n :call <SID>FindNotInComment(1)<CR>
    nnoremap <silent> N :call <SID>FindNotInComment(0)<CR>
endfunc

func! s:ToggleFindInComments()
    if g:findInComments
        let g:sfsave=v:searchforward
        call s:MapN()
        nnoremap <silent> / m`:call <SID>MapCR()<CR>:let g:sfsave=1<CR>/
        nnoremap <silent> ? m`:call <SID>MapCR()<CR>:let g:sfsave=0<CR>?
        nnoremap <silent> * m`:let @/='\<'.expand('<cword>').'\>'<CR>:let g:sfsave=1<CR>:call
            \<SID>FindNotInComment(1)<CR>:set hlsearch<CR>
        nnoremap <silent> # m`:let @/='\<'.expand('<cword>').'\>'<CR>:let g:sfsave=0<CR>:call
            \<SID>FindNotInComment(1)<CR>:set hlsearch<CR>
        let g:findInComments=0
        redraw
        echo "Searching text not in C-style comments"
    else
        silent! unmap n
        silent! unmap N
        silent! unmap /
        silent! unmap ?
        silent! unmap *
        silent! unmap #
        call s:UnmapCR()

        " Handle case where previous search was backwards
        if g:sfsave==0
            nnoremap <silent> n ?:unmap n<CR>:unmap N<CR>
            nnoremap <silent> N ?NN:unmap n<CR>:unmap N<CR>
        endif
        let g:findInComments=1
        redraw
        echo "Searching everywhere"
    endif
endfunc

" Tabular pipeline for aligning = with first non-blank of lines up until ;
autocmd VimEnter * AddTabularPipeline! align_with_equals
    \ /^[^=]*\zs=\([^;]*$\)\@=
    \\|^\s*\zs=\@<!\S[^=]*;.*$
    \\|^\s*\zs\([{}]\)\@!\(\/\/\)\@!\S[^;]*\(\*\/\)\@<!$/
    \ map(a:lines,"substitute(v:val,'^\\s*\\(.*=\\)\\@!','','g')")
    \ | tabular#TabularizeStrings(a:lines,
    \ '^\s*\zs\S\(.*=\)\@!.*$\|^[^=]*\zs=\([^;]*$\)\@=.*$','l1')

" Handle +=, -=, etc.
autocmd VimEnter * AddTabularPipeline! align_with_equals_after1char
    \ /^[^=]*\zs=\([^;]*$\)\@=
    \\|^\s*\zs=\@<!\S[^=]*;.*$
    \\|^\s*\zs\([{}]\)\@!\(\/\/\)\@!\S[^;]*\(\*\/\)\@<!$/
    \ map(a:lines,"substitute(v:val,'^\\s*\\(.*=\\)\\@!',' ','g')")
    \ | tabular#TabularizeStrings(a:lines,
    \ '^\s*\zs \S\(.*=\)\@!.*$\|^[^=]*\zs[+*/%&|^-]=[^;=]*$','l1')

" Handle <<= and >>=
autocmd VimEnter * AddTabularPipeline! align_with_equals_after2char
    \ /^[^=]*\zs=\([^;]*$\)\@=
    \\|^\s*\zs=\@<!\S[^=]*;.*$
    \\|^\s*\zs\([{}]\)\@!\(\/\/\)\@!\S[^;]*\(\*\/\)\@<!$/
    \ map(a:lines,"substitute(v:val,'^\\s*\\(.*=\\)\\@!','  ','g')")
    \ | tabular#TabularizeStrings(a:lines,
    \ '^\s*\zs  \S\(.*=\)\@!.*$\|^[^=]*\zs\(<<\|>>\)=[^;=]*$','l1')

" Function to find and align lines of a C assignment
func! s:AlignUnterminatedAssignment()
    if !hlexists('cComment') | return 0 | endif
    let pat='^.*[=!<>]\@<!\zs=\ze=\@![^;]*$\|^.*\zs\(<<\|>>\)=\ze[^;]*$'
    let top=search(pat,'W')
    if !top | return 0 | endif
    while (synIDattr(synID(line("."), col("."), 1), "name")) =~? 'comment'
        let top=search(pat,'W')
    endwhile
    let bottom=search(';','W')
    while (synIDattr(synID(line("."), col("."), 1), "name")) =~? 'comment'
        let bottom=search(';','W')
    endwhile
    if match(getline(top),'\(<<\|>>\)=') != -1
        exec top.','.bottom.'Tabularize align_with_equals_after2char'
    elseif match(getline(top),'[+*/%&|^-]=') != -1
        exec top.','.bottom.'Tabularize align_with_equals_after1char'
    else
        exec top.','.bottom.'Tabularize align_with_equals'
    endif
    call cursor(top, 1)
    call cursor(bottom, 1)
    return 1
endfunc

" Function to fully format a C/C++ source file
func! s:FormatC()
    if !hlexists('cComment') | return | endif

    " Save view to restore afterwards
    let winSave=winsaveview()

    " Replace tabs with spaces or vice versa
    retab

    " Remove trailing whitespace
    keepj silent! %s/\s\+$\|$t^//g | call histdel('/','\V$t^')

    " Go through all lines and indent correctly
    call cursor(1,1)
    while line('.') < line('$')
        norm! j^
        if getline('.') != ""
            if (getline('.') !~ '^\s*\/\*') || (getline('.') =~ '^\s*\/\*.*\*\/')
                " Regular line of code or single-line comment
                norm! ==
            else
                " First line of block comment
                let top=line('.')
                let indent=cindent(top)-match(getline('.'),'\S')
                call search('^.*\*\/','W')
                let bottom=line('.')

                " Indent all lines of block comment by same amount
                while indent
                    if indent > 0
                        exec 'keepj silent! '.top.','.bottom.'s/^.*$\|$t^/ &'
                        let indent -= 1
                    else
                        let space=1
                        for n in range(top,bottom)
                            if match(getline(n),'\S') == 0
                                let space=0
                            endif
                        endfor
                        if space
                            exec 'keepj silent! '.top.','.bottom.'s/^\( \)\(.*\)$\|$t^/\2'
                            let indent += 1
                        else
                            let indent=0
                        endif
                    endif
                endwhile
            endif
        endif
    endwhile

    " Find and indent unterminated assignments
    call cursor(1,1)
    while s:AlignUnterminatedAssignment() | endwhile

    " Clean up search history
    call histdel('/','\V$t^')

    " Restore view
    call winrestview(winSave)
endfunc

com! StripComments call <SID>StripComments()
com! ToggleFindInComments call <SID>ToggleFindInComments()
com! AlignUnterminatedAssignment call <SID>AlignUnterminatedAssignment()
com! FormatC call <SID>FormatC()

nnoremap ,c :ToggleFindInComments<CR>

