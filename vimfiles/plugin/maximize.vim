" Vim plugin file
" Maintainer: kAtremer <katremer@yandex.ru>
" Last changed: 2007 Oct 16
"
" maximize.vim
" maximize gVim's window on startup on Win32
"
" to install, put the script and maximize.dll
" in $VIM\vimfiles\plugin

" Execute only once {{{
if exists("g:loaded_maximize")
	finish
endif
let g:loaded_maximize=1
" }}}
" Set the default compatibility options {{{
" (don't know if they do any difference, in such a small script...)
let s:save_cpoptions=&cpoptions
set cpoptions&vim
" }}}
let s:dllfile=expand('<sfile>:p:h').'/maximize.dll'
let haswin=has("win16") || has("win32") || has("win64")
if haswin
    autocmd GUIEnter * call libcallnr(s:dllfile, 'Maximize', 1)
endif
" Restore the saved compatibility options {{{
let &cpoptions=s:save_cpoptions
" }}}

" vim:fdm=marker:fmr={{{,}}}
