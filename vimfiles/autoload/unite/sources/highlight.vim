scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#highlight#define()
	return s:source
endfunction


function! s:as_syntax(highlight)
	let highlight = matchstr(a:highlight, '\s*\S*\ze\s\+xxx')
	if highlight == ""
		return ""
	endif
	return printf("syntax match %s /\\s*%s/ contained containedin=uniteSource_Highlight", highlight, substitute(a:highlight, 'xxx', '\\zsxxx\\ze', "g"))
endfunction



let s:source = {
\	"name" : "highlight",
\	"description" : "output :highlight",
\	"syntax" : "uniteSource_Highlight",
\	"max_candidates" : 100,
\	"hooks" : {},
\}



function! s:source.hooks.on_init(args, context)
	redir => output
	silent! highlight
	redir END
	let self.highlight_list = split(output, "\n")
endfunction


function! s:source.hooks.on_syntax(args, context)
	for highlight in self.highlight_list
		try
			execute s:as_syntax(highlight)
		catch /\v^Vim%(\(\a+\))=:(E402)/
			" https://github.com/osyo-manga/unite-highlight/issues/2
		endtry
	endfor
endfunction


function! s:source.gather_candidates(args, context)
	return map(copy(self.hooks.highlight_list), '{
\		"word" : v:val,
\	}')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
