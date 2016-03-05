" Copyright 2015 Jacob Niehus
" jacob.niehus@gmail.com
" Do not distribute without permission.

if exists('g:ShortCWDloaded')
  finish
endif

let g:ShortCWDloaded = 1

let s:hasWin = has("win16") || has("win32") || has("win64")
let s:cwdPrev = ''
let s:bufNamePrev = ''
let s:winWidthPrev = -1
let s:bufModPrev = 0
let s:wsPrev = ''
let s:wsEnabledPrev = 0
let s:hunksPrev = [0, 0, 0]

function! s:WhitespaceSame()
  if !exists('*airline#extensions#whitespace#get_enabled') | return 1 | endif
  return (airline#extensions#whitespace#get_enabled()
      \ && !exists('b:airline_whitespace_check')) ||
      \ (exists('b:airline_whitespace_check')
      \ && b:airline_whitespace_check == s:wsPrev
      \ && airline#extensions#whitespace#get_enabled() == s:wsEnabledPrev)
endfunction

function! s:HunksSame()
  return !exists('*GitGutterGetHunkSummary') ||
      \ GitGutterGetHunkSummary() == s:hunksPrev
endfunction

function! ShortCWD()
  if getcwd() == s:cwdPrev && @% == s:bufNamePrev &&
      \ winwidth(0) == s:winWidthPrev && &mod == s:bufModPrev &&
      \ s:HunksSame() && s:WhitespaceSame()
    return s:cwd
  endif

  if !exists("+shellslash") || &shellslash
    let pathSep = '/'
  else
    let pathSep = '\'
  endif

  let s:cwdPrev = getcwd()
  let s:bufNamePrev = @%
  let s:winWidthPrev = winwidth(0)
  let s:bufModPrev = &modified
  let s:cwd = fnamemodify(s:cwdPrev,':~')
  if exists('*airline#extensions#whitespace#get_enabled')
    let s:wsEnabledPrev = airline#extensions#whitespace#get_enabled()
  endif
  if exists('b:airline_whitespace_check')
      \ && s:wsEnabledPrev
    let s:wsPrev = b:airline_whitespace_check
  else
    let s:wsPrev = ''
  endif

  let git = ''
  if exists('b:git_dir') && len(b:git_dir)
    let git = g:airline_symbols.branch . ' '
    if exists("*GitGutterGetHunkSummary")
      let s:hunksPrev = GitGutterGetHunkSummary()
      if max(s:hunksPrev)
        let git = airline#extensions#hunks#get_hunks() . git
      endif
    endif
  endif

  if &buftype == 'help'
    let s:maxLen = winwidth(0) - strchars(expand('%:t')) - 37
  else
    let s:maxLen = winwidth(0) - strchars(expand('%:~:.')) -
        \ strchars(&filetype) - 3 * &modified - 2 * &readonly - 37 -
        \ strchars(s:wsPrev) - (strchars(s:wsPrev) ? 3 : 0)
  endif
  if len(git) | let s:maxLen -= 2 | endif
  let s:maxLen -= len(FFinfo())

  if strchars(s:cwd) + strchars(git) > s:maxLen
    let parts = split(s:cwd, pathSep)
    let partNum = s:hasWin ? 1 : 0
    while (strchars(s:cwd) + strchars(git) >= s:maxLen) &&
        \ (partNum < len(parts) - 1)
      let parts[partNum] = parts[partNum][0]
      let s:cwd = join(parts, pathSep)
      if pathSep ==# '/' && parts[0] != '~' | let s:cwd = '/' . s:cwd | endif
      let partNum += 1
    endwhile
    if strchars(s:cwd) + strchars(git) > s:maxLen && len(parts)
      let s:cwd = parts[-1]
    endif
  endif
  if s:cwd == '~/' | let s:cwd = '~' | endif

  if strchars(s:cwd) + strchars(git) <= s:maxLen
    let s:cwd = git . s:cwd
  elseif strchars(s:cwd) + (len(git) ? 2 : 0) <= s:maxLen
    let s:cwd = (len(git) ? g:airline_symbols.branch . ' ' : '') . s:cwd
  else
    let s:cwd = ''
  endif

  return s:cwd
endfunction

function! FFinfo()
  return printf('%s%s', &fileencoding == 'utf-8' ? '' : &fileencoding,
      \ &fileformat == 'unix' ? '' : printf('[%s]', &fileformat))
endfunction

" vim:set et ts=2 sts=2 sw=2:
