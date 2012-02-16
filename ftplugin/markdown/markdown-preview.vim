"
" While editing a Markdown document in Vim, preview it in the
" default browser.
"
" See readme.mdown for more information
"

if !exists("g:markdown_preview_templatefile")
	let s:current_file=expand("<sfile>")
	let s:current_path = matchstr(s:current_file, '^.*/')
	let g:markdown_preview_templatefile = s:current_path . 'markdown-preview.html'
endif

function!PreviewMarkdown() range
    " **************************************************************
    " Configurable settings

    let MARKDOWN_COMMAND = 'markdown'

	if exists("g:BROWSER_COMMAND")
		let BROWSER_COMMAND = g:BROWSER_COMMAND
	else
		if has('win32')
			" note important extra pair of double-quotes
			let BROWSER_COMMAND = 'cmd.exe /c start ""'
		else
			let BROWSER_COMMAND = 'xdg-open'
		endif
	endif

    " End of configurable settings
    " **************************************************************

    silent update
	let output_name = tempname() . '.html'

	if &ff == 'mac'
		let le = "\r"
	elseif &ff == 'dos'
		let le = "\r\n"
	else "unix and others?
		let le = "\n"
	endif

	let buffer = ''
    "Step through each line in the range...
    for linenum in range(a:firstline, a:lastline)
        "Replace loose ampersands (as in DeAmperfy())...
        let curr_line  = getline(linenum)
        let buffer = buffer . curr_line . le
    endfor

    " Some Markdown implementations, especially the Python one,
    " work best with UTF-8. If our buffer is not in UTF-8, convert
    " it before running Markdown, then convert it back.
    let original_encoding = &fileencoding
    let original_bomb = &bomb
    if original_encoding != 'utf-8' || original_bomb == 1
        set nobomb
        set fileencoding=utf-8
        silent update
    endif

	let html = []
	if filereadable(g:markdown_preview_templatefile)
		let html = readfile(g:markdown_preview_templatefile)
	else
		" Write the HTML header. Do a CSS reset, followed by setting up
		" some basic styles from YUI, so the output looks nice.
		let html = ['<html>', '<head>',
			\ '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">',
			\ '<title>Markdown Preview</title>',
			"\ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssreset/reset-min.css">',
			"\ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssbase/base-min.css">',
			"\ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssfonts/fonts-min.css">',
			"\ '<style>body{padding:20px;}div#container{background-color:#F2F2F2;padding:0 20px;margin:0px;border:solid #D0D0D0 1px;}</style>',
			\ '</head>', '<body>', '<div id="container">', '</div>', '</body>', '</html>']
	endif

	let md_command = MARKDOWN_COMMAND
	let md_output = system(md_command, buffer)

	let html = split(substitute(join(html, le), '\(<div id="container">\).*\(</div>\)', '\1' . md_output . '\2', ''), le)
	call writefile(html, output_name)

    " If we changed the encoding, change it back.
    if original_encoding != 'utf-8' || original_bomb == 1
        if original_bomb == 1
            set bomb
        endif
        silent exec 'set fileencoding=' . original_encoding
        silent update
    endif

	silent exec '!' . BROWSER_COMMAND . ' "' . output_name . '"'

    exec input('Press ENTER to continue...')
	exec delete(output_name)
	"echo s:current_file
	"echo s:current_path
	"echo g:markdown_preview_templatefile
	"echo md_output
	"echo html
	"echo a:firstline
	"echo a:lastline
	"echo buffer
endfunction

" Map this feature to the command :Markdownpreview
command! -range=% MarkdownPreview <line1>,<line2>call PreviewMarkdown()
