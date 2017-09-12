" guard {{{1

if exists('g:autoloaded_comment')
    finish
endif
let g:autoloaded_comment = 1

" functions {{{1
fu! comment#duplicate(type) abort "{{{2
    if count([ 'v', 'V', "\<c-v>" ], a:type)
        '<,'>yank
        '<,'>CommentToggle
        norm! `>]p
    else
        norm! '[y']
        '[,']CommentToggle
        norm! `]]p
    endif
endfu

fu! s:get_cml() abort "{{{2
    " This function should return a list of 2 strings:
    "
    "     • the beginning of a comment string; e.g. for vim:    `" `
    "     • the end of a comment string;       e.g. for html:   ` -->`

    " if we operate on lines of code, make sure the comment leader ends with `@`
    let cms = get(s:, 'operate_on', 'text') ==# 'code'
           \?     substitute(&l:cms, '\ze%s', '@', '')
           \:     &l:cms

    " make sure there's a space between the comment leader and the comment:
    "         "%s   →   " %s
    " more readable
    let cms = substitute(cms, '\S\zs\ze%s', ' ', '')

    " make sure there's a space between the comment and the end-comment leader
    "         <-- %s-->    →    <-- %s -->
    let cms = substitute(cms,'%s\zs\ze\S', ' ', '')

    " return the comment leader, and the possible end-comment leader,
    " through a list of 2 items
    return split(cms, '%s', 1)
    "                       │
    "                       └─ always return 2 items, even if there's nothing
    "                          after `%s` (in this case, the 2nd item will be '')
endfu

fu! s:is_commented(line, l, r) abort "{{{2
    "                            ┌─ trim beginning whitespace
    "                            │
    let line = matchstr(a:line, '\S.*\s\@<!')
    "                                └────┤
    "                                     └ trim ending whitespace

    "                           ┌ the line begins with the comment leader
    "      ┌────────────────────┤
    return stridx(line, a:l) == 0 && line[strlen(line)-strlen(a:r):] ==# a:r
    "                                └─────────────────────────────────────┤
    "                             it also ends with the end-comment leader ┘
endfu

fu! s:is_commented_code(line) abort "{{{2
    let line = matchstr(a:line, '\S.*\s\@<!')

    return   stridx(line, s:l.'@') == 0
        &&   line[strlen(line)-strlen(s:r):] ==# s:r
endfu

fu! s:is_commented_text(line) abort "{{{2
    let line = matchstr(a:line, '\S.*\s\@<!')

    return   stridx(line, s:l) == 0
       \&&   stridx(line, s:l.'@') == -1
       \&&   line[strlen(line)-strlen(s:r):] ==# s:r
endfu

fu! s:is_relevant(line) abort "{{{2
    return !(s:operate_on ==# 'code' && s:is_commented_text(a:line))
       \&& !(s:operate_on ==# 'text' && s:is_commented_code(a:line))
endfu

fu! s:maybe_trim_cml(line, l_, r_) abort "{{{2
    let [l_, r_] = [ a:l_    , a:r_   ]
    let [l, r]   = [ l_[0:-2], r_[1:] ]
    "                  └────┤    └──┤
    "                       │       └ remove 1st  whitespace
    "                       └──────── remove last whitespace

    " if the line is commented with the trimmed comment leaders, but not with
    " the original ones, return the trimmed ones
    if s:is_commented(a:line, l, r) && !s:is_commented(a:line, l_, r_)
        return [l, r]
    endif

    " by default, return the original ones
    return [l_, r_]
endfu

fu! comment#object(op_is_c) abort "{{{2
    let [ s:l, s:r ] = split(&l:cms, '%s', 1)
    let [ l_, r_ ]   = s:get_cml()
    let boundaries   = [ line('.')+1, line('.')-1 ]

    " We consider a line to be in a comment object iff it's:{{{
    "
    "         • commented
    "         • relevant
    "         • not the start/end of a fold
    " … OR:
    "         • an empty line
    "
    "           If the boundary has reached the end/beginning of the buffer,
    "           there's no next line.
    "           But `getline()` will still return an empty string.
    "           So the test:
    "
    "                   next_line !~ '\S'
    "
    "           … will succeed, wrongly.
    "           We mustn't include this non-existent line.
    "           Otherwise, we'll be stuck in an infinite loop,
    "           forever (inc|dec)rementing the boundary and forever including
    "           new non-existent lines.
    "           Hence:
    "                   boundaries[which] != limit
"}}}
    let Next_line_is_in_object = { -> s:is_commented(next_line, l, r)
                             \&&      s:is_relevant(next_line)
                             \
                             \||      next_line !~ '\S' && boundaries[which] != limit
                             \}

    "       ┌─ 0 or 1:  upper or lower boundary
    "       │
    for   [ which,   dir,       limit,      next_line ]
   \in  [ [     0,    -1,           1,   getline('.') ]
   \,     [     1,     1,   line('$'),   getline('.') ] ]

        let [ l , r  ] = s:maybe_trim_cml(getline('.'), l_, r_)
        while Next_line_is_in_object()
            " stop if the boundary has reached the beginning/end of a fold
            if match(next_line, '{{{\|}}}') != -1
                break
            endif

            " the test was successful so (inc|dec)rement the boundary
            let boundaries[which] += dir

            " update `line`, `l`, `r` before next test
            let next_line = getline(boundaries[which]+dir)
            let [l, r]    = s:maybe_trim_cml(next_line, l_, r_)
        endwhile
    endfor

    "  ┌─ we operate on the object with `c`
    "  │            ┌─ OR the object doesn't end at the very end of the buffer
    "  │            │
    if a:op_is_c || boundaries[1] != line('$')
        " make sure there's no empty lines at the BEGINNING of the object
        " by incrementing the upper boundary as long as necessary
        while getline(boundaries[0]) !~ '\S'
            let boundaries[0] += 1
        endwhile
    endif

    if a:op_is_c
        " make sure there's no empty lines at the END of the object
        while getline(boundaries[1]) !~ '\S'
            let boundaries[1] -= 1
        endwhile
    endif

    " Check that upper boundary comes before lower boundary.
    " If it does not, something went wrong, and we shouldn't select anything.
    if boundaries[0] > boundaries[1]
        return
    endif

    " position the cursor on the 1st line of the object
    exe 'norm! '.boundaries[0].'G'

    " select the object
    exe 'norm! V'.boundaries[1].'G'

    unlet! s:l s:r
endfu

fu! comment#toggle(type, ...) abort "{{{2
    if empty(&l:cms)
        return
    endif

    " Define the range of lines to (un)comment.

    if a:type ==# 'Ex'
        let [lnum1, lnum2] = [a:1, a:2]
    elseif a:type ==# 'visual'
        let [lnum1, lnum2] = [line("'<"), line("'>")]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    " get original comment leader
    " (no space added for better readability; no `@` for code)
    let [ s:l, s:r ] = split(&l:cms, '%s', 1)

    "    ┌─ comment leader (modified: add padding space, and `@` for code)
    "    │   ┌─ end-comment leader ('' if there's none)
    "    │   │
    let [l_, r_] = s:get_cml()

    " Decide what to do:   comment or uncomment?
    " The decision will be stored in the variable `uncomment`:
    "
    "         • 0 = the operator will comment    the range of lines
    "         • 2 = "                 uncomment  "

    "               ┌─ Why 2 instead of 1?
    "               │  Nested comments use numbers to denote the level of imbrication.
    "               │  2 is a convenient value to compute an (in|de)cremented level:
    "               │
    "               │             old_lvl - uncomment + 1
    "               │                       │
    "               │                       └─ should be 2 or 0
    let uncomment = 2
    for l:lnum in range(lnum1, lnum2)
        let line = getline(l:lnum)
        " If needed for the current line, trim the comment leader.
        let [l, r] = s:maybe_trim_cml(line, l_, r_)

        " To comment a range of lines, one of them must be:
        "
        "         • not empty
        "         • not commented
        "         • relevant
        "
        " What is an irrelevant line?
        " A commented line of text, when we operate on code. (1)
        " Or a commented line of code, when we operate on text. (2)
        "
        " (1) Such a line is indeed NOT commented (because no `@` in the cml).
        " But if we operate on code, we don't care. So we need to ignore it.
        "
        " (2) Such a line should also be ignored, but is NOT a problem.
        " Why? Because the previous condition has checked that the line is not
        " commented. So:
        "
        "         we operate on text
        "       + the line is not commented    ⇒    the line can't be
        "                                           a commented line of code
        "
        " IOW: if you aren't a commented line of text, you can't be
        " a commented line of code.

        if line =~ '\S'
      \&& !s:is_commented(line, l, r)
      \&&  s:is_relevant(line)
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

        " Don't do anything if the line is:
        "
        "         • empty
        "         • irrelevant

        if  line !~ '\S' || !s:is_relevant(line)
            continue
        endif

        let [l, r] = s:maybe_trim_cml(line, l_, r_)

        " Add support for nested comments.
        " Example: In an html file:
        "
        "     <!-- hello world -->                          comment
        "     <!-- <1!-- hello world --1> -->               comment in a comment
        "     <!-- <1!-- <2!-- hello world --2> --1> -->    comment in a comment in a comment
        "
        " We need to make sure the right part of the comment leader has several
        " characters, otherwise the incrementation/decrementation would occur
        " on numbers which are not concerned. But why >2?
        "
        " We also make sure that neither the left part nor the right part of
        " the comment leader contains a backslash.
        " Maybe to prevent something like `\1` to be interpreted as
        " a backref. Shouldn't the nomagic flag `\M` already prevent that?
        if strlen(r) > 2 && l.r !~ '\\'
            let left_number  = l[0] . '\zs\d\+\ze' . l[1:]
            let right_number = r[:-2] . '\zs\d\+\ze' . r[-1:-1]
            let pat          = '\M' . left_number . '\|' . right_number
            let rep          = '\=submatch(0)-uncomment+1 == 0 ? '''' : submatch(0)-uncomment+1'
            let line         = substitute(line, pat, rep, 'g')
        endif

        if uncomment
            let pat = '\S.*\s\@<!'
            let rep = '\=submatch(0)[strlen(l) : -1 - strlen(r)]'
        else
            let pat = '\v^%('.indent.'|\s*)\zs.*'
            let rep = '\=l.submatch(0).r'
        endif

        let line = substitute(line, pat, rep, '')
        call setline(l:lnum, line)
    endfor

    " We execute all the autocmds using the event `User` and the filter
    " `CommentTogglePost`.
    " It allows us to execute a callback after (un)commenting some text, by
    " installing an autocmd outside this function, using the same event and
    " filter. Example:
    "
    "         augroup my_comment_toggle
    "             au!
    "             au User CommentTogglePost `do some stuff`
    "         augroup END

    if exists('#User#CommentTogglePost')
        doautocmd <nomodeline> User CommentTogglePost
        " By default, when an autocmd is executed, the modelines in the current
        " buffer are processed (if &modelines != 0).
        " Indeed, the modelines must be able to overrule the settings changed by
        " autocmds. For example, when we edit a file, the settings set by
        " modelines must be able to overrule the ones set by the autocmds
        " watching the BufRead event.
        "
        " But here, we probably don't want the modelines to change anything.
        " So we add the <nomodeline> argument to prevent the modelines in the
        " current buffer to be processed. From :h :do:
        "
        "         You probably want to use <nomodeline> for events that are not
        "         used when loading a buffer, such as |User|.
    endif

    " don't unlet `s:operate_on`:  it would break the dot command
    unlet! s:l s:r
endfu

fu! comment#what(this) abort "{{{2
    let s:operate_on = a:this
endfu
