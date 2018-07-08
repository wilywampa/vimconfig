if exists("g:loaded_insertmotion") || &compatible
  finish
endif
let g:loaded_insertmotion = 1
let s:killed = ''

function! s:char_class(c, big) abort " {{{
  if a:c =~ '\s'
    return 0
  elseif a:c =~ '\k' || a:big
    return 2
  else
    return 1
  endif
endfunction " }}}

function! s:back_word(big) abort " {{{
  let pos = strchars(getline('.')) - strchars(getline('.')[col('.')-1:]) + 1
  if pos == 1
    return 0
  endif

  let line = split(getline('.'), '\zs')
  if col('.') > len(line) && line[-1] !~ '[[:print:]]\|\s'
    let s:killed = line[-1]
    return 1
  endif
  let col = strchars(getline('.')[:col('.')-1]) - 1

  " Skip white space before the word
  while col > 1 && s:char_class(line[col-1], a:big) == 0
    let col -= 1
  endwhile
  let cls = s:char_class(line[col-1], a:big)

  " Move backward to start of this word
  while col > 1 && s:char_class(line[col-1], a:big) == cls
    let col -= 1
  endwhile

  " Check for overshoot
  if cls != s:char_class(line[col-1], a:big)
    let col += 1
  endif

  let s:killed = join(line[(col - pos):], '')
  return pos - col
endfunction " }}}

function! s:forward_word(big) abort " {{{
  let pos = strchars(getline('.')) - strchars(getline('.')[col('.')-1:]) + 1
  let end = strchars(getline('.'))
  if pos > end
    return 0
  endif

  let line = split(getline('.'), '\zs')
  let cls = s:char_class(line[pos-1], a:big)
  let col = pos + 1

  " Go one char past end of current word
  if cls != 0
    while col <= end && s:char_class(line[col-1], a:big) == cls
      let col += 1
    endwhile
  endif

  " Go to next non-white
  while col <= end && s:char_class(line[col-1], a:big) == 0
    let col += 1
  endwhile

  return col - pos
endfunction " }}}

function! s:kill_line() " {{{
  if !pumvisible()
    let before = strchars(getline('.')[:col('.')-1]) - 1
    let blanks = strchars(matchstr(getline('.'), '^\s*'))
    let s:killed = join(split(getline('.'), '\zs')[(blanks):(before)], '')
  endif
  return "\<C-u>"
endfunction " }}}

function! s:killed() " {{{
  return s:killed
endfunction " }}}

" Move backward/forward by words without breaking undo
inoremap <expr> <C-Left> repeat('<C-g>U<Left>', <SID>back_word(0))
inoremap <expr> <M-Left> repeat('<C-g>U<Left>', <SID>back_word(1))
inoremap <expr> <C-Right> repeat('<C-g>U<Right>', <SID>forward_word(0))
inoremap <expr> <M-Right> repeat('<C-g>U<Right>', <SID>forward_word(1))

" Restore text after <C-w>/<C-u>
inoremap <expr> <C-w> repeat('', <SID>back_word(0)) . '<C-w>'
inoremap <expr> <C-u> <SID>kill_line()
inoremap <silent> <C-x><C-u> <C-r><C-r>=<SID>killed()<CR>

" vim:set ft=vim sw=2 sts=2 fdm=marker:
