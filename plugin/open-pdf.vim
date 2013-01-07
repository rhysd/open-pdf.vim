scriptencoding utf-8

" load once
if exists("g:loaded_open_pdf")
    finish
endif

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

" commands "{{{
command! -complete=file -nargs=1 -bar -bang Pdf            call open_pdf#open(<q-args>, <q-bang>)
command! -complete=file -nargs=1 -bar -bang PdfRead        call open_pdf#read(<q-args>, <q-bang>)
command! -complete=file -nargs=1 -bar -bang PdfEdit        call open_pdf#edit(<q-args>, <q-bang>)
command! -nargs=*                           PdfCacheClean  call open_pdf#clean_cache(<f-args>)
command! -complete=file -nargs=+            PdfCacheReload call open_pdf#reload_cache(<f-args>)
"}}}

" add unite action to open pdf when unite.vim is used {{{
augroup OpenPdfUniteAction
    autocmd!
    autocmd FileType unite,vimfiler call open_pdf#unite_action_pdf#add()
augroup END
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

let g:loaded_open_pdf = 1
