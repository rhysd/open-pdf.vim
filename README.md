Convert pdf file to plain-text file, cache it and open it in Vim.
=================================================================

### Commands
- `:Pdf path/to/pdf-file` converts, caches and opens the pdf-file.

- `:Unite pdf/history` displays histories you have ever opened.

### Dependency
`pdftotext` command must have been installed in advance to convert a pdf file and 
unite.vim is required to use a unite interface.

### Auto Conversion
When a pdf file is edited with `:edit` or `:read`, conversion from pdf to txt is automatically executed and open the text file instead of pdf file. You must set `g:pdf_convert_on_edit` or `g:pdf_convert_on_read` to 1 to enable these features.

Read `doc/open-pdf.txt` to get more information.
