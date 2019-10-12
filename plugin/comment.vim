if exists('g:loaded_comment')
    finish
endif
let g:loaded_comment = 1

" Commands {{{1

" This command could be useful when we're working from the command-line
" (script, global command, Ex mode …). E.g.:
"
"         :g/pattern/'{,'}CommentToggle
"                    ^
"                    (Un)Comment every paragraph containing `pattern`.
"
"          :.,'aCommentToggle
"           ^
"          (Un)Comment from the current line to the one where mark `a` is set.
"
" Alternatively, we could use `:norm gc{object}`, but in a script,
" `:CommentToggle` is more readable.

com -range -bar CommentToggle call comment#toggle('Ex', <line1>,<line2>)

" Mappings {{{1
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
nno <silent> cp :<c-u>call comment#and_paste(']', '')<cr>
nno <silent> cP :<c-u>call comment#and_paste('[', '')<cr>

nno <silent> <cp :<c-u>call comment#and_paste(']', '<')<cr>
nno <silent> <cP :<c-u>call comment#and_paste('[', '<')<cr>

nno <silent> >cp :<c-u>call comment#and_paste(']', '>')<cr>
nno <silent> >cP :<c-u>call comment#and_paste('[', '>')<cr>

nno <silent> =cp :<c-u>call comment#and_paste(']', '=')<cr>
nno <silent> =cP :<c-u>call comment#and_paste('[', '=')<cr>

" duplicate code {{{2

nno  <silent><unique>  +d   :<c-u>set opfunc=comment#duplicate<cr>g@
nno  <silent><unique>  +dd  :<c-u>set opfunc=comment#duplicate
                           \ <bar>exe 'norm! '.v:count1.'g@_'<cr>
xno  <silent><unique>  +d   :<c-u>call comment#duplicate('vis')<cr>

" motion {{{2

noremap  <expr><silent><unique>  ["  comment#search(0)
noremap  <expr><silent><unique>  ]"  comment#search(1)

" toggle {{{2

nno  <silent><unique>  gc   :<c-u>set opfunc=comment#toggle<cr>g@
xno  <silent><unique>  gc   :<c-u>call comment#toggle('visual')<cr>
nno  <silent><unique>  gcc  :<c-u>set opfunc=comment#toggle
                           \ <bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent><unique>  ic  :<c-u>call comment#object(v:operator is# 'c')<cr>
xno  <silent><unique>  ic  :<c-u>call comment#object(0)<cr>

nmap  <silent><unique>  gcu  gcic
"                         │
"                         └ Uncomment text-object

