vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Commands {{{1

command -range -bar CommentToggle comment#toggle#main(<line1>, <line2>)

# Mappings {{{1
# toggle {{{2

nnoremap <expr><unique> gc comment#toggle#main()
xnoremap <expr><unique> gc comment#toggle#main()
nnoremap <expr><unique> gcc comment#toggle#main() .. '_'

onoremap <unique> ic <Cmd>call comment#object#main(v:operator ==# 'c')<CR>
xnoremap <unique> ic <C-\><C-N><Cmd>call comment#object#main()<CR>

# Why not just `gcic` in the rhs?{{{
#
# Suppose you accidentally press `gcu` on an *un*commented line.
# `ic` won't select anything, and `gc` will comment the current line.
# That's not what  we want; if there's  no commented line where we  are, then we
# don't want anything to happen.
#}}}
nmap <unique> gcu vic<Plug>(uncomment-selection)
xmap <expr> <Plug>(uncomment-selection) mode() =~# '^[vV<C-V>]$' ? 'gc' : ''

# paste and comment {{{2

# Paste and comment right afterwards.
# Rationale:{{{
#
# We often have to press ``]pgc`]`` and it's hard/awkward to type.
#}}}
# How to select the text which I've just pasted with these mappings?{{{
#
# Press `gV` or `g C-v` (custom mappings installed from our vimrc).
#}}}
nnoremap <expr><unique> cp comment#paste#setup(']', '')
nnoremap <expr><unique> cP comment#paste#setup('[', '')

nnoremap <expr><unique> <cp comment#paste#setup(']', '<')
nnoremap <expr><unique> <cP comment#paste#setup('[', '<')

nnoremap <expr><unique> >cp comment#paste#setup(']', '>')
nnoremap <expr><unique> >cP comment#paste#setup('[', '>')

nnoremap <expr><unique> =cp comment#paste#setup(']', '=')
nnoremap <expr><unique> =cP comment#paste#setup('[', '=')

# duplicate code {{{2

nnoremap <expr><unique> +d  comment#duplicate#main()
nnoremap <expr><unique> +dd comment#duplicate#main() .. '_'
xnoremap <expr><unique> +d  comment#duplicate#main()

# comment half a block {{{2

# Useful when we  debug an issue and try  to reduce a custom vimrc  to a minimum
# amount of lines.
nnoremap <expr><unique> gct comment#half#setup('top')
nnoremap <expr><unique> gcb comment#half#setup('bottom')

# motion {{{2

noremap <expr><unique> ]" comment#motion#main()
noremap <expr><unique> [" comment#motion#main(v:false)

