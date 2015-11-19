let s:save_cpo = &cpo
set cpo&vim

function! s:define_sources() abort " {{{
  for type in ['converters', 'matchers', 'sorters']
    let s:source = {
        \ 'name': type,
        \ 'required_pattern_length': 0,
        \ 'action_table' : {},
        \ 'default_action' : 'set',
        \ }

    function! s:source.gather_candidates(args, context) abort
      let items = unite#get_filters()
      call filter(items, 'v:key =~# "^' . self.name[:-2] . '_"')
      let len = max(map(copy(items), 'len(v:key)'))
      let current = a:context.temporary ? s:unite['current_' . self.name] : []
      let items.none = {'description': 'remove ' . self.name}
      return values(map(copy(items),
          \ '{ "word": v:key,
          \    "abbr": printf("%-'.len.'s - %s", v:key, v:val.description),
          \    "source": s:source.name,
          \    "unite__is_marked": index(current, v:key) != -1,
          \    "unite__marked_time": localtime(),
          \  }'))
    endfunction

    let s:source.action_table.set = {
        \ 'description' : 'set current ' . type,
        \ 'is_selectable' : 1,
        \ 'is_quit' : 0,
        \ 'source' : type,
        \ }
    function! s:source.action_table.set.func(candidates) " {{{
      if len(a:candidates) == 0 && a:candidates[0].word ==# 'none'
        let items = []
      else
        let items = map(filter(copy(a:candidates), 'v:val.word !=# "none"'),
            \ 'v:val.word')
      endif
      let temporary = unite#get_context().temporary
      call unite#force_quit_session()
      if temporary
        let s:unite['current_' . self.source] = items
        let s:unite.context.is_redraw = 1
      else
        let profile = unite#get_context().profile_name
        let profile = unite#util#input('Profile: ',
            \ len(profile) ? profile : 'default',
            \ 'customlist,' . s:SID_PREFIX() . 'profiles')
        call unite#custom#profile(profile, self.source, items)
      endif
    endfunction " }}}

    call unite#define_source(s:source)
  endfor
endfunction " }}}

function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

function! s:profiles(arglead, cmdline, cursorpos) abort " {{{
  return sort(keys(unite#custom#get().profiles))
endfunction " }}}

function! s:set(type) abort " {{{
  let s:unite = unite#get_current_unite()
  call unite#start_temporary([a:type], {}, a:type)
endfunction " }}}

function! s:define_mappings() abort " {{{
  nnoremap <silent> <buffer> <C-x><C-c>
      \ :<C-u>call <SID>set('converters')<CR>
  nnoremap <silent> <buffer> <C-x><C-m>
      \ :<C-u>call <SID>set('matchers')<CR>
  nnoremap <silent> <buffer> <C-x><C-s>
      \ :<C-u>call <SID>set('sorters')<CR>
  inoremap <silent> <buffer> <C-x><C-c>
      \ <C-o>:<C-u>call <SID>set('converters')<CR>
  inoremap <silent> <buffer> <C-x><C-m>
      \ <C-o>:<C-u>call <SID>set('matchers')<CR>
  inoremap <silent> <buffer> <C-x><C-s>
      \ <C-o>:<C-u>call <SID>set('sorters')<CR>
endfunction " }}}

augroup unite_custom
  autocmd!
  autocmd VimEnter * if exists(':Unite') | call s:define_sources() | endif
  autocmd FileType unite call s:define_mappings()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2:
