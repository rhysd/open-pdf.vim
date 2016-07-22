scriptencoding utf-8

function! s:system(...) "{{{
    let cmd = join(a:000, ' ')
    if exists('s:vimproc_does_not_exist')
        call system(cmd)
    else
        try
            call vimproc#system(cmd)
        catch
            let s:vimproc_does_not_exist = 1
            call system(cmd)
        endtry
    endif
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

function! open_pdf#open(path, bang) "{{{
    execute g:pdf_open_cmd s:cache(fnameescape(a:path),a:bang)
    if has_key(g:pdf_hooks, 'on_opened')
        call g:pdf_hooks.on_opened()
    endif
endfunction
"}}}

" read and edit command for pdf file {{{
function! open_pdf#read(path, bang)
    execute g:pdf_read_cmd s:cache(fnameescape(a:path),a:bang)
    if has_key(g:pdf_hooks, 'on_read')
        call g:pdf_hooks.on_read()
    endif
endfunction

function! open_pdf#edit(path, bang)
    execute g:pdf_edit_cmd s:cache(fnameescape(a:path),a:bang)
    if has_key(g:pdf_hooks, 'on_edited')
        call g:pdf_hooks.on_edited()
    endif
endfunction
"}}}

function! open_pdf#clean_cache(...) "{{{
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

function! open_pdf#reload_cache(...) "{{{
    for path in a:000
        let cache = g:pdf_cache_dir.'/'.fnamemodify(path,':t:r').'.txt'
        call s:pdftotext(path,cache)
    endfor
endfunction
"}}}
