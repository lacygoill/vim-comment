" TODO:
" Invert the operators `gc` and `gC` (and the objects `ic`, `iC`).
" `gc` is easier to type and we'll (un)comment code more frequently than text.
" Do it once we've concealed `@` in Vim files.
"
" Actually, it may be a bad idea, because when you use the code from someone
" else, they won't use `@`. So, when you will want to uncomment their code,
" you may constantly hit the wrong mapping.
"
" Think more about it.
" Edit:
" Ok, I've thought about it, and I think it may still be worth a try.
" Whatever we decide to do, be consistent with the mappings `yc`, `yC`, `myc`, `myC`.

" TODO:
" Integrate `myfuncs#search_comment()` (["  ]").
" Tweak the code so that it ignores commented code. Only commented text.
" Should we also integrate `yc` &friends?

" FIXME:
" In `~/bin/awk/histogram.awk`, right under `draw last bar`, hit `vic`.
" Nothing is selected. 4 lines should be selected.
" On the empty line 87, hit `viC`. 7 lines should be selected. Only 4 are.
"
" Hit `viC` on the line `let s:some_var = 42`.
" The lines above are selected. They shouldn't.
" It's fixed. For now.
let s:some_var = 42

" FIXME:
" If we select 2 paragraphs separated by an empty line, and hit `gC`, the
" empty line isn't commented. Do we want it to be commented.
"
" Pro: easier to select both commented paragraph with `vip`.
"
" Con: ugly empty commented line
"      somewhat useless if we have a properly implemented object (`viC`)
"      need to re-add a lot of code we've deleted
"      need to remove trailing whitespace, after uncommenting empty line
"
" Suggestion:
" Maybe we should reverse `ic` and `iC` (as well as the other mappings),
" because `ic` is easier to type, and maybe we'll select commented text
" more often than commented code.

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

com! -range -bar CommentToggle call comment#toggle('Ex', <line1>,<line2>)

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

" toggle code {{{2

nno  <silent>  gc     :<c-u>call comment#what('code')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gc     :<c-u>call comment#what('code')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gcc    :<c-u>call comment#what('code')<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  ic     :<c-u>call comment#what('code')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  ic     :<c-u>call comment#what('code')<bar>call comment#object(0)<cr>

nmap <silent>  gcu    gcic

" toggle text {{{2

nno  <silent>  gC     :<c-u>call comment#what('text')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gC     :<c-u>call comment#what('text')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gCC    :<c-u>call comment#what('text')<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  iC     :<c-u>call comment#what('text')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  iC     :<c-u>call comment#what('text')<bar>call comment#object(0)<cr>

nmap <silent>  gCu    gCiC
"                │
"                └─ Uncomment text-object
