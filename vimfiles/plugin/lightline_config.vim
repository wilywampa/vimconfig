if !exists('g:lightline')
  let g:lightline = {}
endif

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
call extend(g:airline_symbols, {
    \ 'crypt': '🔒',
    \ 'modified': '+',
    \ 'notexists': '∄',
    \ 'paste': 'PASTE',
    \ 'readonly': '',
    \ 'space': ' ',
    \ 'whitespace': '✹',
    \ 'linenr': 'L',
    \ 'branch': '',
    \ 'leftsep': '',
    \ 'leftsubsep': '|',
    \ 'rightsep': '',
    \ 'rightsubsep': '|',
    \ }, 'keep')

if get(g:, 'lightline_powerline_fonts', 0)
  call extend(g:airline_symbols, {
      \ 'linenr': '',
      \ 'branch': '',
      \ 'leftsep': '',
      \ 'leftsubsep': '',
      \ 'rightsep': '',
      \ 'rightsubsep': '',
      \ }, 'force')
endif

let g:lightline.colorscheme = 'solarized'
let g:lightline.component = {
    \   'lineinfo': '%3p%% ' . g:airline_symbols.linenr . '%3l:%-2v',
    \   'filetype': '%{&filetype}',
    \ }
let g:lightline.component_function = {
    \   'ffinfo': 'FFinfo',
    \   'shortcwd': 'ShortCWD',
    \   'mode': 'LightLineMode',
    \ }
let g:lightline.component_expand = {
    \   'info': 'LightLineInfo',
    \   'whitespace': 'whitespace#check',
    \ }
let g:lightline.component_type = {'whitespace': 'error'}
let g:lightline.active = {
    \   'left': [['mode', 'paste'], ['shortcwd'], ['info']],
    \   'right': [['whitespace', 'lineinfo'], ['ffinfo'], ['filetype']],
    \ }
let g:lightline.inactive = {
    \   'left': [['absolutepath']],
    \   'right': [['lineinfo']],
    \ }
let g:lightline.separator = {
    \   'left': g:airline_symbols.leftsep,
    \   'right': g:airline_symbols.rightsep,
    \ }
let g:lightline.subseparator = {
    \   'left': g:airline_symbols.leftsubsep,
    \   'right': g:airline_symbols.rightsubsep,
    \ }

function! LightLineInfo() abort
  if get(g:, 'solarized_termcolors', 256) == 16
    return '%#StatusFlag#%{LightLineFlags()}'.
        \  '%#LightLineMiddle_active#%<%{LightLineFile()}'.
        \  '%{&modifiable?"":" [-] "}%#StatusFlag#'.
        \  '%{&readonly?"  '.g:airline_symbols.readonly.'":""}'.
        \  '%#StatusModified#'.
        \  '%{LightLineFileModified()}%0*'
  else
    return '%{LightLineFlags()}%<%f '.
        \  '%{&modifiable?"":" [-] "}'.
        \  '%{&readonly?"  '.g:airline_symbols.readonly.'":""}%'.
        \  '{&modified?" [+]":""}'
  endif
endfunction

function! LightLineFilename() abort
  let name = &filetype ==# 'help' ? expand('%:t') : expand('%:~:.')
  return stridx(name, '__Gundo') == 0 ? '' :
      \ &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
      \ &filetype ==# 'unite' ? unite#get_status_string() :
      \ empty(name) ? '[No Name]' : name
endfunction

function! LightLineFile() abort
  return &modified ? '' : LightLineFilename()
endfunction

function! LightLineFileModified() abort
  return &modified ? LightLineFilename() . ' [+]' : ''
endfunction

function! LightLineMode() abort
  let name = expand('%:t')
  return name ==# '__Gundo__' ? 'Gundo' :
      \ name ==# '__Gundo_Preview__' ? 'Gundo Preview' :
      \ &filetype ==# 'unite' ? 'Unite' :
      \ &filetype ==# 'vimfiler' ? 'vimfiler' :
      \ &previewwindow ? 'Preview' : lightline#mode()
endfunction

function! LightLineFlags() abort
  return printf('%s%s%s',
      \ &ignorecase ? '' : '↑',
      \ empty(&eventignore) ? '' : '!',
      \ get(g:, "ipython_store_history", 1) ? '' : '☢')
endfunction

silent! call whitespace#init()

" vim: fdl=1 tw=100 et sw=2:
