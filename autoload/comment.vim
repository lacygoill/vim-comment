fu! s:is_commented_text(line) abort
    return match(a:line, '^\s*'.s:cms.'@\@!') != -1
endfu
fu! s:is_commented_code(line) abort
    return match(a:line, '^\s*'.s:cms.'@') != -1
endfu

" guard {{{1

" TODO: restore the guard

" if exists('g:auto_loaded_comment')
"     finish
" endif
" let g:auto_loaded_comment = 1

" autocmd {{{1

" Currently, uncommenting an (indented) empty line leaves undesired whitespace.
" Remove them.

augroup my_comment_toggle
    au!
    au User CommentTogglePost call s:remove_trailing_wsp()
augroup END

fu! s:adapt_commentstring(line, l, r) abort " {{{1
    let [line, l_, r_] = [a:line, a:l, a:r]
    let [l, r]         = [l_[0:-2], r_[1:]]

    if !s:is_commented(line, l_, r_) && s:is_commented(line, l, r)
        return [l, r]
    endif

    return [l_, r_]
endfu

fu! comment#duplicate(type) abort "{{{1
    if count([ 'v', 'V', "\<c-v>" ], a:type)
        norm! gvygv
        norm gc
    else
        norm! '[y']
        '[,']CommentToggle
    endif

    norm! `]]p
endfu

fu! s:get_commentstring() abort "{{{1
    " This function should return a list of 2 strings:
    "
    "     - the beginning of a comment string; e.g. for vim: `" `
    "     - the end of a comment string;       e.g. for html: ` -->`
    "
    " To do so it relies on the template `&commenstring`.

    if get(s:, 'toggle_what', 'text') ==# 'code'
        return [ split(&cms, '%s', 1)[0].'@ ' ] + [ split(&cms, '%s', 1)[1] ]
    endif

    " To make the commented text more readable, we don't want the item `%s` to be
    " directly preceded by a non whitespace.
    " So we add a space between the beginning of the comment string and `%s`:
    "
    "         `"%s` → `" %s`
    let cms = substitute(&commentstring, '\S\zs\ze%s',' ','')
    " Same thing if `%s` is followed by a non whitespace:
    "
    "         `<-- %s-->`    →    `<-- %s -->`
    let cms = substitute(cms,'%s\zs\ze\S', ' ', '')

    " Finally, we return the beginning and end of the comment string through
    " a list of 2 items.
    return split(cms, '%s', 1)
    " To be sure that the returned list always has 2 items, we pass the 3rd argument
    " `1` to split(). This way, it will return an empty string as the 2nd item if
    " the comment string is not in 2 parts, that is if the template ends with `%s`.
endfu

fu! s:is_commented(line, l, r) abort "{{{1
    let line   = matchstr(a:line, '\S.*\s\@<!')
    let [l, r] = [a:l, a:r]

    return stridx(line, l) == 0 && line[strlen(line)-strlen(r):] ==# r
endfu

fu! comment#object(inner) abort " {{{1
    let [l_, r_]      = s:get_commentstring()
    let [l, r]        = [l_, r_]
    let boundaries    = [ line('.')+1, line('.')-2 ]

    for [ index, dir, limit, line ] in [ [0, -1, 1, ''], [1, 1, line('$'), ''] ]

        " line !~ '\S'    ⇔    line =~ '^\s*$'
        while s:is_commented(line, l, r)
        \|| ( line !~ '\S' && boundaries[index] != limit )

            let boundaries[index] += dir
            let line               = getline(boundaries[index]+dir)
            let [l, r]             = s:adapt_commentstring(line,l_,r_)

            " In a Vim buffer, a comment can't span across several folds
            if &ft ==# 'vim' && dir == -1 && match(getline(boundaries[index]), '"\+\s*{{{\s*$') != -1
                let boundaries[index] += 1
                break
            elseif &ft ==# 'vim' && dir == 1 && match(getline(boundaries[index]), '"\+\s*}}}\s*$') != -1
                let boundaries[index] -= 1
                break
            endif

        endwhile
    endfor

    " If there're empty lines at the very beginning of the comment object,
    " remove them by incrementing the upper boundary.
    " Do it only if the operator is `c` (a:inner == 1), or if the comment
    " object doesn't end at the very end of the buffer (`boundaries[1] != line('$')`).
    if a:inner || boundaries[1] != line('$')
        while getline(boundaries[0]) !~ '\S'
            let boundaries[0] += 1
        endwhile
    endif

    " If there're empty lines at the end of the comment object, remove them by
    " decrementing the lower boundary.
    " Do it only if the operator is `c` (a:inner == 1).
    if a:inner
        while getline(boundaries[1]) !~ '\S'
            let boundaries[1] -= 1
        endwhile
    endif

    " Check that upper boundary is lower than lower boundary.
    " If it's not, something went wrong, and we shouldn't select anything.
    if boundaries[0] <= boundaries[1]
        " Position the cursor on the 1st line of the comment object.
        exe 'norm! ' . boundaries[0] . 'G'
        if foldlevel(line('.')) > 0
            " If there're folds on the current line, open them.
            exe 'norm! ' . foldlevel(line('.')) . 'zo'
        endif
        " Select the comment object.
        exe 'norm! V' . boundaries[1] . 'G'
    endif
endfu

fu! s:remove_trailing_wsp() abort "{{{1
    let view = winsaveview()

    sil! keepj keepp '[,']s/^\s\+$//
    sil! keepj keepp '<,'>s/^\s\+$//

    call winrestview(view)
endfu

fu! comment#toggle(type, ...) abort "{{{1
    " Define the range of lines to (un)comment.

    if a:type ==# 'Ex'
        let [lnum1, lnum2] = [a:1, a:2]
    elseif a:type ==# 'visual'
        let [lnum1, lnum2] = [line("'<"), line("'>")]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    " Get the original comment string.
    " We wrap the code in a `try` conditional to handle the case where the
    " comment string is empty.
    " It raises an error, and there's nothing the operator can do without
    " a comment string.
    " So, if `s:get_commentstring()` fails to return sth, we stop immediately.
    try
        let [l_, r_]   = s:get_commentstring()
    catch
        return
    endtry

    let s:cms  = split(&cms, '%s')[0]
    " Decide what to do: comment or uncomment?
    " The decision is stored in the variable `uncomment`.
    " `0` means the operator will comment the range of lines.
    " `2` "                       uncomment   "
    let uncomment  = 2
    for l:lnum in range(lnum1, lnum2)
        let line   = getline(l:lnum)
        " Adapt the comment string to the current line, by removing padding
        " whitespace placed between the text and the comment, if needed.
        let [l, r] = s:adapt_commentstring(line, l_, r_)

        " To comment a range of lines, one of them must be:
        "
        "         • not empty
        "         • not commented
        "         • not a commented line of text
        "
        " TODO:
        " Why the need for the 3rd condition?
        " How can a line be not commented and a commented line of text at the
        " same time?
        " It could be a commented line of code.
        "
        " What if the line is a commented line of text.
        " Don't we need a similar condition for it?
        " No. Because, if the line is not empty, and commented … to finish
        "
        " Refactor this part of the code. Not clear.
        " Do we still need `s:is_commented()`?

        if line =~ '\S'
       \&& !s:is_commented(line, l, r)
       \&& !s:is_commented_text(line)
            let uncomment = 0
        endif
    endfor

    " Get the indent of first line.
    " Why?
    "
    " When we comment, if we simply add the left part of the comment string
    " right before the first non whitespace of each line, and the latter have
    " different levels of indentation, the comment characters won't be aligned.
    "
    " We want all of them to be aligned under the first one.
    " To do this, we need to know the level of indentation of the first line.
    let indent = matchstr(getline(lnum1), '^\s*')
    for l:lnum in range(lnum1,lnum2)
        let line = getline(l:lnum)
        let [l, r] = s:adapt_commentstring(line, l_, r_)

        " Add support for nested comments.
        " Example: In a html file:
        "
        "     <!-- hello world -->                          comment
        "     <!-- <1!-- hello world --1> -->               comment in a comment
        "     <!-- <1!-- <2!-- hello world --2> --1> -->    comment in a comment in a comment
        "
        " We need to make sure the right part of the comment has several
        " characters, otherwise the incrementation/decrementation would occur
        " on numbers which are not concerned.
        " But why >2?
        "
        " We also make sure that neither the left part nor the right part of
        " the comment string contains a backslash.
        " Maybe to prevent something like `\1` to be interpreted as
        " a backref. Shouldn't the nomagic flag `\M` already prevent that?
        if strlen(r) > 2 && l.r !~# '\\'
            let left_number  = l[0] . '\zs\d\+\ze' . l[1:]
            let right_number = r[:-2] . '\zs\d\+\ze' . r[-1:-1]
            let pattern      = '\M' . left_number . '\|' . right_number
            let replacement  = '\=submatch(0)-uncomment+1 == 0 ? '''' : submatch(0)-uncomment+1'
            let line         = substitute(line, pattern, replacement, 'g')
        endif

        if uncomment
            let pattern     = '\S.*\s\@<!'
            let replacement = '\=submatch(0)[strlen(l) : -1 - strlen(r)]'
        else
            " At the end of the pattern, we could write `\zs.*\s@<!`, but then
            " it could comment an empty line.
            " We don't want that, so we write `\zs.*\S` instead.
            " This pattern makes sure at least one non-whitespace character is
            " present on the line.

            " Switch to 2nd pattern/replacement, if you want to comment empty lines.
            " Beware, it's not perfect, uncommenting on a block of lines containing
            " an indented empty line leaves trailing whitespace.
            " For the moment, I think I fixed this issue by installing an
            " autocmd listening to the `CommentTogglePost` event.

            " let pattern     = '\v^%(' . indent . '|\s*)\zs.*\S'
            let pattern     = '\v^%(' . indent . '|\s*)\zs.*'
            " let replacement = '\=l . submatch(0) . r'
            let replacement = '\=!empty(submatch(0)) ? l.submatch(0).r : indent.l[:-2].r'
            "                                                                       │
            "                                                        remove space  ─┘
            "                                             after comment character
        endif

        " Don't do anything if the line is:
        "
        "         • empty
        "         • commented code, but we want to toggle text
        "         • commented text, but we want to toggle code
        if    line =~# '^\s*$'
       \||    s:is_commented_code(line) && s:toggle_what ==# 'text'
       \||    s:is_commented_text(line) && s:toggle_what ==# 'code'
        else
            let line = substitute(line, pattern, replacement, '')
            call setline(l:lnum, line)
        endif
    endfor
    unlet! s:cms

    " We execute all the autocmds using the event `User` and the filter
    " `CommentTogglePost`.
    " It allows us to execute a callback after (un)commenting some text, by
    " installing an autocmd outside this function, using the same event and
    " filter. Example:
    "
    "         augroup my_comment_toggle
    "             autocmd!
    "             autocmd User CommentTogglePost `do some stuff`
    "         augroup END
    "
    " By default, when an autocmd is executed, the modelines in the current
    " buffer are processed (if 'modelines' != 0).
    " Indeed, the modelines must be able to overrule the settings changed by
    " autocmds. For example, when we edit a file, the settings set by
    " modelines must be able to overrule the ones set by the autocmds watching
    " the BufRead event.
    "
    " But here, we probably don't want the modelines to change anything.
    " So we add the <nomodeline> argument to prevent the modelines in the
    " current buffer to be processed:
    "
    "     https://github.com/tpope/vim-commentary/issues/26

    if exists('#User#CommentTogglePost')
        doautocmd <nomodeline> User CommentTogglePost
    endif
endfu

fu! comment#what(this) abort "{{{1
    let s:toggle_what = a:this
endfu
