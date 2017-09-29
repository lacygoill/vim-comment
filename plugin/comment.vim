" Guard {{{1

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

"                                   ┌─ We need to set `s:operate_on`, like we do for all normal commands
"                                   │  (gc, gC, …). Otherwise, there's a risk that the plugin complains
"                                   │  that the variable doesn't exist.
"                                   │
"                                   │  We choose to set `s:operate_on` to `text` instead of `code`.
"                                   │  Because, I think we'll want to use the Ex command only for text.
"                                   │  For code, the normal command is more well-suited.
"                                   │
com! -range -bar CommentToggle call comment#what('text') | call comment#toggle('Ex', <line1>,<line2>)

" Mappings {{{1
" duplicate code {{{2

"                                              ┌─ we will always want to duplicate code (not text)
"                                              │
nno  <silent>  Zd     :<c-u>call comment#what('code')<bar>set opfunc=comment#duplicate<cr>g@
nno  <silent>  Zdd    :<c-u>call comment#what('code')<bar>set opfunc=comment#duplicate<bar>exe 'norm! '.v:count1.'g@_'<cr>
xno  <silent>  Zd     :<c-u>call comment#what('code')<bar>call comment#duplicate(visualmode())<cr>

nmap           ZD     Zd
xmap           ZD     Zd
nmap           ZDD    Zdd

" motion {{{2

nno <silent> [" :<c-u>call comment#search('text', 1)<cr>
nno <silent> ]" :<c-u>call comment#search('text', 0)<cr>

xno <silent> [" :<c-u>call comment#search('text', 1, 'vis')<cr>
xno <silent> ]" :<c-u>call comment#search('text', 0, 'vis')<cr>

ono <silent> [" :norm V["<cr>
ono <silent> ]" :norm V]"<cr>

nno <silent> [@ :<c-u>call comment#search('code', 1)<cr>
nno <silent> ]@ :<c-u>call comment#search('code', 0)<cr>

xno <silent> [@ :<c-u>call comment#search('code', 1, 'vis')<cr>
xno <silent> ]@ :<c-u>call comment#search('code', 0, 'vis')<cr>

ono <silent> [@ :norm V[@<cr>
ono <silent> ]@ :norm V]@<cr>

" toggle code {{{2

nno  <silent>  gC     :<c-u>call comment#what('code')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gC     :<c-u>call comment#what('code')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gCC    :<c-u>call comment#what('code')<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  iC     :<c-u>call comment#what('code')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  iC     :<c-u>call comment#what('code')<bar>call comment#object(0)<cr>

nmap <silent>  gCu    gCiC

" toggle text {{{2

nno  <silent>  gc     :<c-u>call comment#what('text')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gc     :<c-u>call comment#what('text')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gcc    :<c-u>call comment#what('text')<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  ic     :<c-u>call comment#what('text')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  ic     :<c-u>call comment#what('text')<bar>call comment#object(0)<cr>

nmap <silent>  gcu    gcic
"                │
"                └─ Uncomment text-object
