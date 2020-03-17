" Interface {{{1
fu comment#motion#main(is_fwd, ...) abort "{{{2
    " This function positions the cursor on the next/previous beginning of a comment.
    " Inspiration: $VIMRUNTIME/ftplugin/vim.vim

    if empty(&l:cms) | return '' | endif

    let mode = mode(1)

    let seq = ''
    if mode is# 'n' | let seq ..= "m'" | endif

    let pat = s:get_search_pat()

    " Why `1|`?{{{
    "
    " Necessary when:
    "
    "    - we look for a pattern, like the previous beginning of a comment section
    "    - the current line matches
    "    - we want to ignore this match
    "
    " `norm! 1|` + no `c` flag in search() = no match  ✔
    "}}}
    " Why not in operator-pending mode?{{{
    "
    " This function is going to return something like:
    "
    "     1|123G
    "
    " For Vim, `1|` will be the object, and `123G` just a simple motion.
    " That's not what we want.
    "}}}
    let seq ..= mode =~# "[nvV\<c-v>]"
           \ ?     '1|'
           \ :     ''

    " don't remove the `W` flag; I like knowing when I've reached the last/first comment
    let new_address = search(pat, (a:is_fwd ? '' : 'b')..'nW')
    if new_address != 0
        let seq ..= new_address..'G'
    else
        return ''
    endif

    if mode is# 'n'
        let seq ..= 'zMzv'
    elseif mode =~# "^[vV\<c-v>]$"
        " don't close fold in visual mode,
        " it makes Vim select whole folds instead of some part of them
        let seq ..= 'zv'
    endif

    return seq
endfu
"}}}1
" Util {{{1
fu s:get_search_pat() abort "{{{2
    " `['"']` in Vim
    " `['/*', '*/']` in C
    let cml = split(&l:cms, '%s')

    " `\V"\m` in Vim
    " `\V/*\m` in C
    let l = '\V'..escape(matchstr(cml[0], '\S\+'), '\')..'\m'

    " `\V"\m` in Vim
    " `\V*/\m` in C
    let r = len(cml) == 2 ? '\V'..escape(matchstr(cml[1], '\S\+'), '\')..'\m' : l

    " We're looking for a commented line of text.
    " It must begin a fold.
    " Or the line before must not be commented.
    "
    "            ┌ no commented line just before
    "            │                        ┌ a commented line of text
    "            ├───────────────────────┐├─────┐
    let pat  =  '^\%(^\s*'..l..'.*\n\)\@<!\s*'..l
    let pat ..= '\|^\s*'..l..'.*{{'..'{'
    return pat
endfu

