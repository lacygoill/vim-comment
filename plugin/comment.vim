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
com! -range -bar CommentToggle <line1>,<line2>call comment#toggle()

" Mappings {{{1

nno  <silent>  gc     :<c-u>set opfunc=comment#toggle<cr>g@
nno  <silent>  gcc    :<c-u>set opfunc=comment#toggle<bar>exe 'norm! g@'.v:count1.'_'<cr>
xno  <silent>  gc     :call comment#toggle()<cr>

ono  <silent>  gC     :<c-u>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  gC     :<c-u>call comment#object(0)<cr>

nmap <silent>  gcu    gcgC
"                │
"                └─ Uncomment text-object
