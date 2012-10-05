scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" definition {{{
let s:source = {
    \   "name"        : "pdf/search",
    \   "description" : "search pdf files",
    \   "default_action" : 'pdf',
    \   "max_candidates" : 30,
    \   "is_volatile" : 1,
    \}

function! unite#sources#pdf_search#define()
    return s:source
endfunction
"}}}

" command to search {{{
let s:cmd = get(g:, 'unite_pdf_search_cmd', '')
if empty(s:cmd)
    if has('mac')
        let s:cmd = "mdfind -name 'kMDItemFSName == \"*%s*.pdf\"'c"
    elseif has('unix') && executable('locate')
        echo s:source.max_candidates
        let s:cmd = 'locate -l '
                    \ . s:source.max_candidates
                    \ . ' "*%s*.pdf"'
    elseif (has('win32') || has('win64')) && executable('es')
        let s:cmd = 'es -i -r -n '
                    \ . s:source.max_candidates
                    \ . ' %s.pdf'
    endif
endif
"}}}

" candidates {{{
function! s:source.gather_candidates(args,context)

    if empty(s:cmd)
        echoerr 'set a command for search to g:unite_pdf_search_cmd.'
        return {}
    endif
    echomsg printf(s:cmd, a:context.input) 
    return map( split( unite#util#system( printf(s:cmd, a:context.input) ), "\n" ),
                \ '{
                \ "word" : v:val,
                \ "source" : "pdf/search",
                \ "kind" : "file",
                \ "action__path" : v:val,
                \ "action__directory" : fnamemodify(v:val, ":p:h"),
                \ }' )
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
