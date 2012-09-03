if !executable('pdftotext')
    finish
endif

let g:pdf_cache_dir = get(g:, 'pdf_cache_dir', $HOME . "/.vim-pdf.cache")
let g:pdf_open_cmd = get(g:, 'pdf_open_cmd', 'vsplit | view')

if !isdirectory(g:pdf_cache_dir)
    call mkdir(g:pdf_cache_dir, 'p')
endif

function! s:has_vimproc()
    if !exists('s:exists_vimproc')
        try
            call vimproc#version()
            let s:exists_vimproc = 1
        catch
            let s:exists_vimproc = 0
        endtry
    endif
    return s:exists_vimproc
endfunction


function! s:open_pdf(path)
    " check extension
    if a:path !~ '\.pdf$'
        echoerr a:path." : This is NOT pdf file."
        return
    endif

    " get cache name
    let cache = g:pdf_cache_dir.'/'.fnamemodify(a:path,':t:r').'.txt'

    " convert pdf and cache it
    if !filereadable(cache)
        if s:has_vimproc()
            call vimproc#system('pdftotext -layout -nopgbrk '.a:path.' - > '.cache)
        else
            call system('pdftotext -layout -nopgbrk '.a:path.' - > '.cache)
        endif
    endif

    " open cache file
    execute g:pdf_open_cmd . ' ' . cache
    setl nowrap nonumber
endfunction

command! -complete=file Pdf call <SID>open_pdf(<q-args>)

function! s:clean_cache(...)
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

command! -complete=file -nargs=? PdfCacheClean call <SID>clean_cache(<q-args>)
