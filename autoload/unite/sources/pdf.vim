scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" definition {{{
let s:source = {
    \   "name" : "pdf/history",
    \   "description" : "list of pdf.vim cache files",
    \   "action_table" : {},
    \   "default_action" : {'common' : 'view_pdf'},
    \}

function! unite#sources#pdf#define()
    return s:source
endfunction
"}}}

" candidates {{{
function! s:source.gather_candidates(args,context)
    let files = split( glob(g:pdf_cache_dir.'/*'), '\n' )

    return map(files, "{
             \ 'word' : fnamemodify(v:val, ':t:r'),
             \ 'source__file' : v:val
             \ }")
endfunction
"}}}

" action {{{
let s:my_action_table = {}
let s:my_action_table.view_pdf = { 'description' : 'open pdf.vim cache file' }

function! s:my_action_table.view_pdf.func(candidate)
    execute ':Pdf' a:candidate.source__file
endfunction
let s:source.action_table = s:my_action_table
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
