" TODO:
" `gc` should ignore code lines.
" `gC` should ignore text lines.

" FIXME:
" In `s:remove_trailing_wsp()`, we shouldn't trim trailing whitespace twice.
" Find a way to detect the proper range.
" Or better, get rid of `s:remove_trailing_wsp()`:  need to tweak `toggle()`
" for that.

" TODO:
" `ZD` should consider the lines as text by default. Currently, it doesn't if
" we've just used `gC`.

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

nno  <silent>  gc     :<c-u>call comment#what('text')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gc     :<c-u>call comment#what('text')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gcc    :<c-u>call comment#what('text')
                      \<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  io     :<c-u>call comment#what('text')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  io     :<c-u>call comment#what('text')<bar>call comment#object(0)<cr>

nmap <silent>  gcu    gcio
"                │
"                └─ Uncomment text-object



nno  <silent>  gC     :<c-u>call comment#what('code')<bar>set opfunc=comment#toggle<cr>g@
xno  <silent>  gC     :<c-u>call comment#what('code')<bar>call comment#toggle('visual')<cr>
nno  <silent>  gCC    :<c-u>call comment#what('code')
                      \<bar>set opfunc=comment#toggle
                      \<bar>exe 'norm! g@'.v:count1.'_'<cr>

ono  <silent>  iO     :<c-u>call comment#what('code')<bar>call comment#object(v:operator ==# 'c')<cr>
xno  <silent>  iO     :<c-u>call comment#what('code')<bar>call comment#object(0)<cr>

nmap <silent>  gCu    gCiO
