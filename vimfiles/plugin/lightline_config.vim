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

let g:lightline.colorscheme = 'solarized_custom'
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
    \   'inactive_filename': 'LightLineInactiveFilename',
    \ }
let g:lightline.component_type = {'whitespace': 'error'}
let g:lightline.active = {
    \   'left': [['mode', 'paste'], ['shortcwd'], ['info']],
    \   'right': [['whitespace', 'lineinfo'], ['ffinfo'], ['filetype']],
    \ }
let g:lightline.inactive = {
    \   'left': [['inactive_filename']],
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
  return '%#StatusFlag#%{LightLineFlags()}'.
      \  '%#LightLineMiddle_active#%<%{LightLineFile()}'.
      \  '%#StatusModified#%{LightLineFileModified()}'.
      \  '%#LightLineMiddle_active#%{&modifiable?"":"[-]"}'.
      \  '%#StatusFlag#%{&readonly?"  '.g:airline_symbols.readonly.'":""}'
endfunction

function! LightLineInactiveFilename()
  return '%<%{LightLineFile()}%#StatusModified#%{LightLineFileModified()}'
endfunction

function! LightLineFilename() abort
  let name = &filetype ==# 'help' ? expand('%:t') : expand('%:~:.')
  return stridx(name, '__Mundo') == 0 ? '' :
      \ stridx(name, '--Python--') != -1 ? 'IPython' :
      \ &previewwindow ? 'Preview' :
      \ &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
      \ &filetype ==# 'unite' ? unite#get_status_string() :
      \ &filetype ==# 'qf' ? get(w:, 'quickfix_title', '') :
      \ empty(name) ? '[No Name]' : name
endfunction

function! LightLineFile() abort
  return &modified ? '' : LightLineFilename()
endfunction

function! LightLineFileModified() abort
  return &modified ? LightLineFilename() . '[+]' : ''
endfunction

function! LightLineMode() abort
  let name = expand('%:t')
  return name ==# '__Mundo__' ? 'Mundo' :
      \ name ==# '__Mundo_Preview__' ? 'Mundo Preview' :
      \ &filetype ==# 'qf' ? (empty(getloclist(0)) ?
      \   'Quickfix' : 'Location List') :
      \ &filetype ==# 'help' ? 'Help' :
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
