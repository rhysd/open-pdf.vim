scriptencoding utf-8

let g:pdf_cache_dir = get(g:, 'pdf_cache_dir', $HOME . "/.open-pdf.vim.cache")
let g:pdf_open_cmd = get(g:, 'pdf_open_cmd', 'vsplit | view')
let g:pdf_pdftotext_path = get(g:, 'pdf_pdftotext_path', 'pdftotext')

let s:pdf_hooks_default = {}
function! s:pdf_hooks_default.on_opened()
    setl nowrap nonumber nolist
endfunction

let g:pdf_hooks = get(g:, 'pdf_hooks', s:pdf_hooks_default)

if !isdirectory(g:pdf_cache_dir)
    call mkdir(g:pdf_cache_dir, 'p')
endif

function! s:system(...) "{{{
    let cmd = join(a:000, ' ')
    try
        call vimproc#system(cmd)
    catch
        call system(cmd)
    endtry
endfunction
"}}}

function! s:open_pdf(path) "{{{

    " check existence of pdftotext
    if !executable(g:pdf_pdftotext_path)
        echoerr "`pdftotext` command is not found!"
        return
    endif

    " check extension
    if a:path !~ '\.pdf$'
        echoerr a:path." : This is NOT pdf file."
        return
    endif

    " get cache name
    let cache = g:pdf_cache_dir.'/'.fnamemodify(a:path,':t:r').'.txt'

    " convert pdf and cache it
    if !filereadable(cache)
        echo "converting ".a:path." ..."
        call s:system(g:pdf_pdftotext_path.' -layout -nopgbrk '.a:path.' - > '.cache)
        echo "done."
    endif

    " open cache file
    execute g:pdf_open_cmd . ' ' . cache
    call g:pdf_hooks.on_opened()
endfunction
"}}}

function! s:clean_cache(...) "{{{
    if empty(a:000) || empty(a:000[0])
        " if name omitted, delete all cache
        for path in split(glob(g:pdf_cache_dir.'/*'), '\n')
            call delete(path)
        endfor
        echo 'deleted: all cache'
    else
        " if name specified
        let path = g:pdf_cache_dir . '/' . fnamemodify(a:1, ':t:r') . '.txt'
        if filereadable(path)
            call delete(path)
            echo 'deleted: '.path
        else
            echo path
            echo "cache doesn't exist."
        endif
    endif
endfunction
"}}}

command! -complete=file -nargs=1 Pdf call <SID>open_pdf(<q-args>)
command! -complete=file -nargs=? PdfClean call <SID>clean_cache(<q-args>)

" add action to unite file source {{{
let s:view_pdf = { 'description' : 'open pdf file' }

function! s:view_pdf.func(candidate)
    call s:open_pdf(a:candidate.action__path)
endfunction

" :call fails when unite doesn't exist.
try
    call unite#custom_action('file', 'pdf', s:view_pdf)
catch
    " skip throwing exception.
endtry

unlet s:view_pdf
"}}}
