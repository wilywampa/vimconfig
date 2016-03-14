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
  if !exists('*whitespace#get_enabled') | return 1 | endif
  return (whitespace#get_enabled()
      \ && !exists('b:whitespace_check')) ||
      \ (exists('b:whitespace_check')
      \ && b:whitespace_check == s:wsPrev
      \ && whitespace#get_enabled() == s:wsEnabledPrev)
endfunction

function! s:HunksSame()
  return !exists('*GitGutterGetHunkSummary') ||
      \ GitGutterGetHunkSummary() == s:hunksPrev
endfunction

function! s:GetHunks()
  return printf('+%s ~%s -%s ',
      \ s:hunksPrev[0], s:hunksPrev[1], s:hunksPrev[2])
endfunction

function! ShortCWD()
  if &filetype ==# 'unite'
    return substitute(get(unite#get_context(), 'buffer_name', ''),
        \ '^default$', '', '')
  endif
  if getcwd() == s:cwdPrev && @% == s:bufNamePrev &&
      \ winwidth(0) == s:winWidthPrev && &mod == s:bufModPrev &&
      \ s:HunksSame() && s:WhitespaceSame()
    return s:cwd
  endif

  let sep = !exists("+shellslash") || &shellslash ? '/' : '\'
  let s:cwdPrev = getcwd()
  let s:bufNamePrev = @%
  let s:winWidthPrev = winwidth(0)
  let s:bufModPrev = &modified
  let s:cwd = fnamemodify(s:cwdPrev,':~')
  if exists('*whitespace#get_enabled')
    let s:wsEnabledPrev = whitespace#get_enabled()
  endif
  if exists('b:whitespace_check')
      \ && s:wsEnabledPrev
    let s:wsPrev = b:whitespace_check
  else
    let s:wsPrev = ''
  endif

  let git = ''
  if exists('b:git_dir') && len(b:git_dir)
    let git = g:airline_symbols.branch . ' '
    if exists("*GitGutterGetHunkSummary")
      let s:hunksPrev = GitGutterGetHunkSummary()
      if max(s:hunksPrev)
        let git = s:GetHunks() . git
      endif
    endif
  endif

  let s:maxLen = winwidth(0) - 4 * (&modified || !&modifiable) -
      \ 34 - strchars(s:wsPrev) - (empty(s:wsPrev) ? 0 : 3) -
      \ strchars(&filetype) - 2 * &readonly -
      \ strchars(exists('*LightLineFilename') ? LightLineFilename() :
      \ expand(&filetype ==# 'help' ? '%:t' : '%:~:.'))

  if len(git) | let s:maxLen -= 2 | endif
  let s:maxLen -= len(FFinfo())

  if strchars(s:cwd) + strchars(git) > s:maxLen
    if strchars(pathshorten(s:cwd)) + strchars(git) < s:maxLen
      let parts = split(s:cwd, sep)
      let partNum = s:hasWin ? 1 : 0
      while (strchars(s:cwd) + strchars(git) >= s:maxLen) &&
          \ (partNum <= len(parts))
        let parts[partNum] = parts[partNum][0]
        let s:cwd = join(parts, sep)
        if sep ==# '/' && parts[0] != '~' | let s:cwd = '/' . s:cwd | endif
        let partNum += 1
      endwhile
      if strchars(s:cwd) + strchars(git) > s:maxLen && len(parts)
        let s:cwd = parts[-1]
      endif
    else
      let s:cwd = fnamemodify(s:cwd, ':t')
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
