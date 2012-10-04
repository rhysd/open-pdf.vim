scriptencoding utf-8

" variables {{{
let g:pdf_cache_dir       = get(g:, 'pdf_cache_dir', $HOME . "/.open-pdf.vim.cache")
let g:pdf_open_cmd        = get(g:, 'pdf_open_cmd', 'vsplit | view')
let g:pdf_edit_cmd        = get(g:, 'pdf_read_cmd', 'edit')
let g:pdf_read_cmd        = get(g:, 'pdf_read_cmd', 'read')
let g:pdf_pdftotext_path  = get(g:, 'pdf_pdftotext_path', 'pdftotext')
let g:pdf_convert_on_edit = get(g:, 'pdf_convert_on_edit', 0)
let g:pdf_convert_on_read = get(g:, 'pdf_convert_on_read', 0)
let g:pdf_hooks           = get(g:, 'pdf_hooks', {})
"}}}

" data dir {{{
if !isdirectory(g:pdf_cache_dir)
    call mkdir(g:pdf_cache_dir, 'p')
endif
"}}}

function! s:system(...) "{{{
    let cmd = join(a:000, ' ')
    try
        call vimproc#system(cmd)
    catch
        call system(cmd)
    endtry
endfunction
"}}}

function! s:pdftotext(from,to) "{{{
    " check existence of pdftotext
    if !executable(g:pdf_pdftotext_path)
        throw "`pdftotext` command is not found!"
    endif

    echo "converting ".a:from." ..."
    call s:system(g:pdf_pdftotext_path.' -layout -nopgbrk '.a:from.' - > '.a:to)
    echo "done."
endfunction
"}}}

function! s:cache(path, bang) "{{{
    " check extension
    if a:path !~ '\.pdf$'
        throw a:path." : This is NOT pdf file."
    endif

    " get cache name
    let cache = g:pdf_cache_dir.'/'.fnamemodify(a:path,':t:r').'.txt'

    " convert pdf and cache it
    if !filereadable(cache) || a:bang==#'!'
        call s:pdftotext(a:path,cache)
    endif

    return cache
endfunction
"}}}

function! s:open_pdf(path, bang) "{{{
    execute g:pdf_open_cmd s:cache(a:path,a:bang)
    if has_key(g:pdf_hooks, 'on_opened')
        call g:pdf_hooks.on_opened()
    endif
endfunction
"}}}

" read and edit command for pdf file {{{
function! s:read_pdf(path, bang)
    execute g:pdf_read_cmd s:cache(a:path,a:bang)
    if has_key(g:pdf_hooks, 'on_read')
        call g:pdf_hooks.on_read()
    endif
endfunction

function! s:edit_pdf(path, bang)
    execute g:pdf_edit_cmd s:cache(a:path,a:bang)
    if has_key(g:pdf_hooks, 'on_edited')
        call g:pdf_hooks.on_edited()
    endif
endfunction
"}}}

function! s:clean_cache(...) "{{{
    if empty(a:000)
        let input = input('Are you sure to delete all caches? [y/N] :')
        if input !=# 'y'
            return
        endif
        " if name omitted, delete all cache
        for path in split(glob(g:pdf_cache_dir.'/*'), '\n')
            call delete(path)
        endfor
        echo 'deleted: all cache'
    else
        " if name specified
        let deleted = []
        for name in a:000
            let path = g:pdf_cache_dir . '/' . fnamemodify(name, ':t:r') . '.txt'
            if filereadable(path)
                call delete(path)
                call add(deleted, path)
            else
                echoerr "A cache doesn't exist. : " . path
            endif
        endfor
        echo "deleted: ".join(deleted, ', ')
    endif
endfunction
"}}}

function! s:reload_cache(...) "{{{
    for path in a:000
        let cache = g:pdf_cache_dir.'/'.fnamemodify(path,':t:r').'.txt'
        call s:pdftotext(path,cache)
    endfor
endfunction
"}}}

" commands "{{{
command! -complete=file -nargs=1 -bar -bang Pdf            call <SID>open_pdf(<q-args>, <q-bang>)
command! -complete=file -nargs=1 -bar -bang PdfRead        call <SID>read_pdf(<q-args>, <q-bang>)
command! -complete=file -nargs=1 -bar -bang PdfEdit        call <SID>read_pdf(<q-args>, <q-bang>)
command! -nargs=*                           PdfCacheClean  call <SID>clean_cache(<f-args>)
command! -complete=file -nargs=+            PdfCacheReload call <SID>reload_cache(<f-args>)
"}}}

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

" auto conversion at BufReadCmd and FileReadCmd {{{
if g:pdf_convert_on_edit
    augroup OpenPdfBufRead
        autocmd!
        autocmd BufReadCmd *.pdf PdfEdit <afile>
    augroup END
endif

if g:pdf_convert_on_read
    augroup OpenPdfFileRead
        autocmd!
        autocmd FileReadCmd *.pdf PdfRead <afile>
    augroup END
endif
"}}}
