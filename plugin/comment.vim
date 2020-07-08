if exists('g:loaded_comment')
    finish
endif
let g:loaded_comment = 1

" Commands {{{1

com -range -bar CommentToggle call comment#toggle#main(<line1>, <line2>)

" Mappings {{{1
" toggle {{{2

nno <expr><unique> gc comment#toggle#main()
xno <expr><unique> gc comment#toggle#main()
nno <expr><unique> gcc comment#toggle#main()..'_'

ono <silent><unique> ic :<c-u>call comment#object#main(v:operator is# 'c')<cr>
xno <silent><unique> ic :<c-u>call comment#object#main(0)<cr>

" Why not just `gcic` in the rhs?{{{
"
" Suppose you accidentally press `gcu` on an *un*commented line.
" `ic` won't select anything, and `gc` will comment the current line.
" That's not what  we want; if there's  no commented line where we  are, then we
" don't want anything to happen.
"}}}
nmap <silent><unique> gcu vic<plug>(uncomment-selection)
xmap <expr> <plug>(uncomment-selection) mode() =~# '^[vV<c-v>]$' ? 'gc' : ''

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

nno <expr><unique> +d  comment#duplicate#main()
nno <expr><unique> +dd comment#duplicate#main()..'_'
xno <expr><unique> +d  comment#duplicate#main()

" comment half a block {{{2

" Useful when we  debug an issue and try  to reduce a custom vimrc  to a minimum
" amount of lines.
nno <expr><unique> gct comment#half#setup('top')
nno <expr><unique> gcb comment#half#setup('bottom')

" motion {{{2

noremap <expr><silent><unique> [" comment#motion#main(0)
noremap <expr><silent><unique> ]" comment#motion#main(1)

