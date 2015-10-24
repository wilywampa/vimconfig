let sources = filter(copy(unite#get_current_unite().source_names), 'v:val =~ "grep\\|line"')
if len(sources)
  setlocal foldlevel=1
  setlocal foldmethod=expr
  setlocal foldexpr=matchstr(getline(v:lnum),'^\s*[^:]\\+')==#matchstr(getline(v:lnum+1),'^\s*[^:]\\+')?1:'<1'
endif
