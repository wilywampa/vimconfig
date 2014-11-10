" Improved paragraph motion
" Last Change: 2012-02-27
" Maintainer: Luke Ng <kalokng@gmail.com>
" Version: 1.0
" Description:
" A simple utility improve the "{" and "}" motion in normal / visual mode.
" In vim, a blank line only containing white space is NOT a paragraph
" boundary, this utility remap the key "{" and "}" to handle that.
"
" The utility uses a custom regexp to define paragraph boundaries, the
" matched line will be treated as paragraph boundary.
" Note that the regexp will be enforced to match from the start of line, to
" avoid strange behaviour when moving.
"
" It supports in normal and visual mode, and able to handle with count. It
" also support redefine the regexp for boundary, or local definition of
" boundary.
"
" Install:
" Simply copy the file to plugin folder and restart vim.
"
" If you do not know where to place it,
" check with "USING A GLOBAL PLUGIN" under :help standard-plugin
"
" Without any setting, it will treat empty line (with or without space) as
" paragraph boundary.
"
" Configuration Variables:
" g:ip_skipfold     Set as 1 will make the "{" and "}" motion skip paragraph
"                   boundaries in closed fold.
"                   Default is 0.
"
" g:ip_boundary     The global definition of paragraph boundary.
"                   Default value is "\s*$".
"                   It can be changed in .vimrc or anytime. Defining
"                   b:ip_boundary will override this setting.
"
"                   Example:
"                       :let g:ip_boundary = '"\?\s*$'
"                   Setting that will make empty lines, and lines only
"                   contains '"' as boundaries.
"
"                   Note that there is no need adding a "^" sign at the
"                   beginning. It is enforced by the script.
"
" b:ip_boundary     Local definition of paragraph boundary. It will override
"                   g:ip_boundary if set. Useful when customize boundary for
"                   local buffer or only apply to particular file type.
"                   Default is unset.

if exists('g:loaded_ipmotion')
  finish
endif
let g:loaded_ipmotion = 1

if !exists('g:ip_boundary')
  let g:ip_boundary='\s*$'
endif
if !exists('g:ip_skipfold')
  let g:ip_skipfold=1
endif

nnoremap <silent> { :<C-U>call <SID>SetCount()<Bar>call <SID>ParagBack()<CR>
nnoremap <silent> } :<C-U>call <SID>SetCount()<Bar>call <SID>ParagFore()<CR>
vnoremap <silent> { :<C-U>call <SID>SetCount()<Bar>exe "normal! gv"<Bar>call <SID>ParagBack()<CR>
vnoremap <silent> } :<C-U>call <SID>SetCount()<Bar>exe "normal! gv"<Bar>call <SID>ParagFore()<CR>
onoremap <silent> { :<C-U>call <SID>SetCount()<Bar>call <SID>ParagBack()<CR>
onoremap <silent> <expr> } <SID>CheckForLastLine("\<SID>ParagFore")
" onoremap <silent> } :<C-U>call <SID>SetCount()<Bar>call <SID>ParagFore()<CR>

function! s:Unfold(fore)
  if a:fore && foldclosedend('.') == line('$')
    normal! G
  endif
  while foldclosed('.') > 0
    normal za
  endwhile
  let boundary='^\%('.(exists('b:ip_boundary') ? b:ip_boundary : g:ip_boundary).'\)'
  if getline('.') !~ boundary
    execute "normal! ".(a:fore ? 'g_' : '0')
  endif
endfunction

function! s:SetCount()
  let s:count1=v:count1
endfunction

function! s:ParagBack()
  try
    let boundary='^\%('.(exists('b:ip_boundary') ? b:ip_boundary : g:ip_boundary).'\)'
    let notboundary=boundary.'\@!'
    let res = search(notboundary, 'cWb')
    if res <= 0
      call cursor(1,1)
      return s:Unfold(0)
    endif
    let res = search(boundary, 'Wb')
    if res <= 0
      call cursor(1,1)
      return s:Unfold(0)
    endif
    if !g:ip_skipfold || foldclosed('.') < 0
      let l:count = s:count1 - 1
    else
      call cursor(foldclosed('.'), 1)
      let l:count = s:count1
    endif
    while l:count > 0
      let res = search(notboundary, 'cWb')
      let res = search(boundary, 'Wb')
      if res <= 0
        call cursor(1,1)
        return s:Unfold(0)
      endif
      if !g:ip_skipfold || foldclosed('.') < 0
        let l:count = l:count - 1
      else
        call cursor(foldclosed('.'), 1)
      endif
    endwhile
    return s:Unfold(0)
  finally
    echo
  endtry
endfunction

function! s:ParagFore()
  try
    let boundary='^\%('.(exists('b:ip_boundary') ? b:ip_boundary : g:ip_boundary).'\)'
    let notboundary=boundary.'\@!'
    while s:OnBlank(boundary)
      if line('.') == line('$') || foldclosedend('.') == line('$')
        return s:Unfold(1)
      endif
      normal! j
    endwhile
    let l:count = s:count1
    while l:count > 0 && line('.') < line('$')
      if line('.') == line('$') || foldclosedend('.') == line('$')
        return s:Unfold(1)
      endif
      while s:OnBlank(boundary)
        if line('.') == line('$') || foldclosedend('.') == line('$')
          return s:Unfold(1)
        endif
        normal! j
      endwhile
      normal! j
      if s:OnBlank(boundary)
        let l:count -= 1
      endif
    endwhile
    return s:Unfold(1)
  finally
    echo
  endtry
endfunction

function! s:OnBlank(boundary)
  return foldclosed('.') < 0 && getline('.') =~ a:boundary
endfunction

" Fix last character missing from last line
function! s:CheckForLastLine(func)
  call s:SetCount()
  let boundary='^\%('.(exists('b:ip_boundary') ? b:ip_boundary : g:ip_boundary).'\)'
  let nblanks = 0
  let start = line('.')
  while start <= line('$') && getline(start) =~# boundary
    let start += 1
  endwhile
  if start > line('$') | return "}" | endif
  let last_blank = -1
  for line in range(start, line('$'))
    if getline(line) =~# boundary && (!g:ip_skipfold || foldclosed(line) == -1)
      " Treat consecutive blanks as a single blank
      if line != last_blank + 1
        let nblanks += 1
      endif
      let last_blank = line
    endif
  endfor
  if nblanks < s:count1
    return '}'
  else
    return ":\<C-U>call ".a:func."()\<CR>"
  endif
endfunction

augroup ipmotion
  autocmd!
  autocmd FileType fortran let b:ip_boundary = '[!C[:blank:]]*$'
  autocmd FileType c,cpp,arduino let b:ip_boundary = '\s*\(//\)\?\s*$'
  autocmd FileType matlab let b:ip_boundary = '[%[:blank:]]*$'
  autocmd FileType help let b:ip_boundary = '[<>[:blank:]]*$'
  autocmd FileType gitcommit let b:ip_boundary = '[#[:blank:]]*$'
augroup END

" vim:set et ts=2 sts=2 sw=2:
