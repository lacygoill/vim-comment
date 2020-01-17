if exists('g:loaded_comment')
    finish
endif
let g:loaded_comment = 1

" Commands {{{1

com -range -bar CommentToggle call comment#toggle#main('Ex', <line1>,<line2>)

" Mappings {{{1
" toggle {{{2

nno <silent><unique> gc  :<c-u>set opfunc=comment#toggle#main<cr>g@
xno <silent><unique> gc  :<c-u>call comment#toggle#main('visual')<cr>
nno <silent><unique> gcc :<c-u>set opfunc=comment#toggle#main
                         \ <bar>exe 'norm! g@'.v:count1.'_'<cr>

ono <silent><unique> ic :<c-u>call comment#object#main(v:operator is# 'c')<cr>
xno <silent><unique> ic :<c-u>call comment#object#main(0)<cr>

nmap <silent><unique> gcu gcic
"                       │
"                       └ Uncomment text-object

" paste and comment {{{2

" Paste and comment right afterwards.
" Rationale:{{{
"
" We often have to press ``]pgc`]`` and it's hard/awkward to type.
"}}}
" How to select the text which I've just pasted with these mappings?{{{
"
" Press `gV` or `g C-v` (custom mappings installed from our vimrc).
"}}}
nno <silent> cp :<c-u>call comment#paste#main(']', '')<cr>
nno <silent> cP :<c-u>call comment#paste#main('[', '')<cr>

nno <silent> <cp :<c-u>call comment#paste#main(']', '<')<cr>
nno <silent> <cP :<c-u>call comment#paste#main('[', '<')<cr>

nno <silent> >cp :<c-u>call comment#paste#main(']', '>')<cr>
nno <silent> >cP :<c-u>call comment#paste#main('[', '>')<cr>

nno <silent> =cp :<c-u>call comment#paste#main(']', '=')<cr>
nno <silent> =cP :<c-u>call comment#paste#main('[', '=')<cr>

" duplicate code {{{2

nno <silent><unique> +d  :<c-u>set opfunc=comment#duplicate#main<cr>g@
nno <silent><unique> +dd :<c-u>set opfunc=comment#duplicate#main
                         \ <bar>exe 'norm! '.v:count1.'g@_'<cr>
xno <silent><unique> +d  :<c-u>call comment#duplicate#main('vis')<cr>

" comment half a block {{{2

" Useful when we  debug an issue and try  to reduce a custom vimrc  to a minimum
" amount of lines.
nno <silent> gct :<c-u>call comment#half#save('top')<bar>set opfunc=comment#half#main<cr>g@l
nno <silent> gcb :<c-u>call comment#half#save('bottom')<bar>set opfunc=comment#half#main<cr>g@l

" motion {{{2

noremap <expr><silent><unique> [" comment#motion#main(0)
noremap <expr><silent><unique> ]" comment#motion#main(1)

