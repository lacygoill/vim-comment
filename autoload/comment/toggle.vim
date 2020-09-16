" Interface {{{1
fu comment#toggle#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'comment#toggle#main'
        return 'g@'
    endif
    let type = a:0 == 1 ? a:1 : 'Ex'
    if empty(&l:cms) | return | endif

    " Define the range of lines to (un)comment.
    if type is# 'Ex'
        let [lnum1, lnum2] = [a:1, a:2]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    "    ┌ comment leader (with a padding space at the end)
    "    │   ┌ end-comment leader (with a padding space at the start; or just an empty string)
    "    │   │
    let [l_, _r] = comment#util#get_cml()

    let uncomment = s:do_we_uncomment(lnum1, lnum2, l_, _r)

    " Why do you get the indent of first line?{{{
    "
    " When we comment, if we simply add the left part of the comment string
    " right before the first non whitespace of each line, and the latter have
    " different levels of indentation, the comment characters won't be aligned.
    "
    " We want all of them to be aligned under the first one.
    " To do this, we need to know the level of indentation of the first line.
    "}}}
    let indent = getline(lnum1)->matchstr('^\s*')

    for lnum in range(lnum1, lnum2)
        let line = getline(lnum)

        " Don't do anything if the line is empty.
        if line !~ '\S' | continue | endif

        let [l, r] = comment#util#maybe_trim_cml(line, l_, _r)

        " Add support for nested comments.
        " Example: In an html file:
        "
        "     <!-- hello world -->                          comment
        "     <!-- <1!-- hello world --1> -->               comment in a comment
        "     <!-- <1!-- <2!-- hello world --2> --1> -->    comment in a comment in a comment

        "            ┌ the end-comment leader should have at least 2 characters:{{{
        "            │         -->
        "            │ … otherwise the incrementation/decrementation could affect
        "            │ numbers inside the comment text, which are not concerned:
        "            │         r = 'x'
        "            │         right_number = r[:-2] .. '\zs\d\+\ze' .. r[-1:-1]
        "            │                      = '\zs\d\+\zex'
        "            │ }}}
        if strlen(r) >= 2 && l .. r !~ '\\'
        "                               │
        "                               └ No matter the magicness of a pattern, a backslash
        "                                 has always a special meaning.  So, we make sure
        "                                 that there's none in the comment leader.

            let left_number = l[0] .. '\zs\d\*\ze' .. l[1:]
            let right_number = r[:-2] .. '\zs\d\*\ze' .. r[-1:-1]
            let pat = '\V' .. left_number .. '\|' .. right_number
            let l:Rep = {m -> m[0]-uncomment+1 <= 0 ? '' : m[0]-uncomment+1}
            let line = substitute(line, pat, Rep, 'g')
        endif

        if uncomment
            let pat = '\S.*\s\@1<!'
            let l:Rep = {m -> m[0][strlen(l) : -1 - strlen(r)]}
        else
            let pat = '^\%(' .. indent .. '\|\s*\)\zs.*'
            " Why?{{{
            "
            " Without,  a comment  leader may  be misaligned  if it  comments an
            " empty commented line.
            "
            " ---
            "
            " Select these lines:
            "
            "     echo ''
            "         " foo
            "         "
            "         " bar
            "
            " Comment them by pressing `gc`.
            "
            " Result:
            "
            "     " echo ''
            "     "      " foo
            "     "     "
            "     "      " bar
            "
            " Notice  how the  comment leader  on the  third line  is misaligned
            " compared to the other ones.
            " We want this instead:
            "
            "     " echo ''
            "     "      " foo
            "     "      "
            "     "      " bar
            "}}}
            if line =~# '^\s*' .. l .. '$' | let l ..= ' ' | endif
            let l:Rep = {m -> l .. m[0] .. r}
        endif

        let line = substitute(line, pat, Rep, '')
        call setline(lnum, line)
    endfor

    " fire a custom event to allow us executing a callback after (un)commenting some text
    if exists('#User#CommentTogglePost')
        do <nomodeline> User CommentTogglePost
    endif
endfu
"}}}1
" Core {{{1
fu s:do_we_uncomment(lnum1, lnum2, l_, _r) abort
    " by default, let's assume we want to uncomment
    " Why 2 instead of 1?{{{
    "
    " Nested comments use numbers to express the level of imbrication.
    " 2 is a convenient value to compute a decremented level:
    "
    "     let new_lvl = old_lvl - uncomment + 1
    "                             │
    "                             └ should be 2 for `new_lvl` to be correct
    "}}}
    let uncomment = 2
    for lnum in range(a:lnum1, a:lnum2)
        let line = getline(lnum)
        " if needed for the current line, trim the comment leader
        let [l, r] = comment#util#maybe_trim_cml(line, a:l_, a:_r)
        " to comment a range of lines, one of them must be non-empty and non-commented
        if line =~ '\S' && !comment#util#is_commented(line, l, r)
            let uncomment = 0
        endif
    endfor
    return uncomment
endfu

