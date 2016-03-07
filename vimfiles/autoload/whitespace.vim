" MIT License. Copyright (c) 2013-2016 Bailey Ling.
" From bling/vim-airline
" vim: et ts=2 sts=2 sw=2

" http://got-ravings.blogspot.com/2008/10/vim-pr0n-statusline-whitespace-flags.html

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
call extend(g:airline_symbols, {
    \ 'space': ' ',
    \ 'whitespace': '✹'},
    \ 'keep')

let s:show_message = get(g:, 'whitespace#show_message', 0)
let s:symbol = get(g:, 'whitespace#symbol', g:airline_symbols.whitespace)
let s:default_checks = ['indent', 'trailing', 'mixed-indent-file']

let s:trailing_format = get(g:, 'whitespace#trailing_format', 'trailing[%s]')
let s:mixed_indent_format = get(g:, 'whitespace#mixed_indent_format', 'mixed-indent[%s]')
let s:long_format = get(g:, 'whitespace#long_format', 'long[%s]')
let s:mixed_indent_file_format = get(g:, 'whitespace#mixed_indent_file_format', 'mix-indent-file[%s]')
let s:indent_algo = get(g:, 'whitespace#mixed_indent_algo', 0)
let s:skip_check_ft = {'make': ['indent', 'mixed-indent-file'] }

let s:max_lines = get(g:, 'whitespace#max_lines', 20000)

let s:enabled = get(g:, 'whitespace#enabled', 1)

function! s:check_mixed_indent()
  if s:indent_algo == 1
    " [<tab>]<space><tab>
    " spaces before or between tabs are not allowed
    let t_s_t = '(^\t* +\t\s*\S)'
    " <tab>(<space> x count)
    " count of spaces at the end of tabs should be less than tabstop value
    let t_l_s = '(^\t+ {' . &ts . ',}' . '\S)'
    return search('\v' . t_s_t . '|' . t_l_s, 'nw')
  elseif s:indent_algo == 2
    return search('\v(^\t* +\t\s*\S)', 'nw')
  else
    return search('\v(^\t+ +)|(^ +\t+)', 'nw')
  endif
endfunction

function! s:check_mixed_indent_file()
  if stridx(&ft, 'c') == 0 || stridx(&ft, 'cpp') == 0
    " for C/CPP only allow /** */ comment style with one space before the '*'
    let head_spc = '\v(^ +\*@!)'
  else
    let head_spc = '\v(^ +)'
  endif
  let indent_tabs = search('\v(^\t+)', 'nw')
  let indent_spc  = search(head_spc, 'nw')
  if indent_tabs > 0 && indent_spc > 0
    return printf("%d:%d", indent_tabs, indent_spc)
  else
    return ''
  endif
endfunction

function! whitespace#check()
  if &readonly || !&modifiable || !s:enabled || line('$') > s:max_lines
    return ''
  endif

  if !exists('b:whitespace_check')
    let b:whitespace_check = ''
    let checks = get(g:, 'whitespace#checks', s:default_checks)

    let trailing = 0
    if index(checks, 'trailing') > -1
      try
        let regexp = get(g:, 'whitespace#trailing_regexp', '\s$')
        let trailing = search(regexp, 'nw')
      catch
        echomsg 'whitespace: error occured evaluating '. regexp
        echomsg v:exception
        return ''
      endtry
    endif

    let mixed = 0
    let check = 'indent'
    if index(checks, check) > -1 && index(get(s:skip_check_ft, &ft, []), check) < 0
      let mixed = s:check_mixed_indent()
    endif

    let mixed_file = ''
    let check = 'mixed-indent-file'
    if index(checks, check) > -1 && index(get(s:skip_check_ft, &ft, []), check) < 0
      let mixed_file = s:check_mixed_indent_file()
    endif

    let long = 0
    if index(checks, 'long') > -1 && &tw > 0
      let long = search('\%>'.&tw.'v.\+', 'nw')
    endif

    if trailing != 0 || mixed != 0 || long != 0 || !empty(mixed_file)
      let b:whitespace_check = s:symbol
      if s:show_message
        if trailing != 0
          let b:whitespace_check .= (g:airline_symbols.space).printf(s:trailing_format, trailing)
        endif
        if mixed != 0
          let b:whitespace_check .= (g:airline_symbols.space).printf(s:mixed_indent_format, mixed)
        endif
        if long != 0
          let b:whitespace_check .= (g:airline_symbols.space).printf(s:long_format, long)
        endif
        if !empty(mixed_file)
          let b:whitespace_check .= (g:airline_symbols.space).printf(s:mixed_indent_file_format, mixed_file)
        endif
      endif
    endif
  endif
  return b:whitespace_check
endfunction

function! whitespace#toggle()
  if s:enabled
    augroup whitespace_check
      autocmd!
    augroup END
    augroup! whitespace_check
    let s:enabled = 0
  else
    call whitespace#init()
    let s:enabled = 1
  endif

  if exists("*airline#update_statusline")
    let g:whitespace#enabled = s:enabled
    if s:enabled && match(g:airline_section_warning, '#whitespace#check') < 0
      let g:airline_section_warning .= airline#section#create(['whitespace'])
      call airline#update_statusline()
    endif
  elseif exists("*lightline#update")
    call lightline#update()
  endif
  echo 'Whitespace checking: '.(s:enabled ? 'Enabled' : 'Disabled')
endfunction

function! whitespace#init(...)
  silent! call airline#parts#define_function('whitespace', 'whitespace#check')

  unlet! b:whitespace_check
  augroup whitespace_check
    autocmd!
    autocmd CursorHold,BufWritePost * unlet! b:whitespace_check
  augroup END
endfunction

function! whitespace#get_enabled()
  return s:enabled
endfunction

