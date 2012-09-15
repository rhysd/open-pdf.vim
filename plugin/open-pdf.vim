scriptencoding utf-8

" variables {{{
let g:pdf_cache_dir = get(g:, 'pdf_cache_dir', $HOME . "/.open-pdf.vim.cache")
let g:pdf_open_cmd = get(g:, 'pdf_open_cmd', 'vsplit | view')
let g:pdf_edit_cmd = get(g:, 'pdf_read_cmd', 'edit')
let g:pdf_read_cmd = get(g:, 'pdf_read_cmd', 'read')
let g:pdf_pdftotext_path = get(g:, 'pdf_pdftotext_path', 'pdftotext')
let g:pdf_convert_buf_read = get(g:, 'pdf_convert_buf_read', 0)
let g:pdf_convert_file_read = get(g:, 'pdf_convert_file_read', 0)

let g:pdf_hooks = get(g:, 'pdf_hooks', {})
"}}}

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

function! s:cache(path) "{{{
    " check existence of pdftotext
    if !executable(g:pdf_pdftotext_path)
        throw "`pdftotext` command is not found!"
    endif

    " check extension
    if a:path !~ '\.pdf$'
        throw a:path." : This is NOT pdf file."
    endif

    " get cache name
    let cache = g:pdf_cache_dir.'/'.fnamemodify(a:path,':t:r').'.txt'

    " convert pdf and cache it
    if !filereadable(cache)
        echo "converting ".a:path." ..."
        call s:system(g:pdf_pdftotext_path.' -layout -nopgbrk '.a:path.' - > '.cache)
        echo "done."
    endif

    return cache
endfunction
"}}}

function! s:open_pdf(path) "{{{

    let cache_file = s:cache(a:path)

    " open cache file
    execute g:pdf_open_cmd cache_file
    if has_key(g:pdf_hooks, 'on_opened')
        call g:pdf_hooks.on_opened()
    endif
endfunction
"}}}

" read and edit command for pdf file {{{
function! s:read_pdf(path)
    execute g:pdf_read_cmd s:cache(a:path)
    if has_key(g:pdf_hooks, 'on_read')
        call g:pdf_hooks.on_read()
    endif
endfunction

function! s:edit_pdf(path)
    execute g:pdf_edit_cmd s:cache(a:path)
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

command! -complete=file -nargs=1 Pdf           call <SID>open_pdf(<q-args>)
command! -complete=file -nargs=1 PdfRead       call <SID>read_pdf(<q-args>)
command! -complete=file -nargs=1 PdfEdit       call <SID>read_pdf(<q-args>)
command! -nargs=* PdfCacheClean call <SID>clean_cache(<f-args>)

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
if g:pdf_convert_buf_read
    augroup OpenPdfBufRead
        autocmd!
        autocmd BufReadCmd *.pdf PdfEdit <afile>
    augroup END
endif

if g:pdf_convert_file_read
    augroup OpenPdfFileRead
        autocmd!
        autocmd FileReadCmd *.pdf PdfRead <afile>
    augroup END
endif
"}}}
