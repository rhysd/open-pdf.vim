scriptencoding utf-8

function! open_pdf#unite_action_pdf#add() " {{{
    let view_pdf = { 'description' : 'open pdf file' }

    function! view_pdf.func(candidate)
        call open_pdf#open(a:candidate.action__path, '')
    endfunction

    " :call fails when unite doesn't exist.
    try
        call unite#custom_action('file', 'pdf', deepcopy(view_pdf))
    catch
        " skip throwing exception.
    endtry
endfunction
"}}}
