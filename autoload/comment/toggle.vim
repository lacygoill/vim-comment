vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def comment#toggle#main(arg_type: any = '', arg_lnum2 = 0): string #{{{2
    if arg_type->typename() == 'string' && arg_type == ''
        &opfunc = 'comment#toggle#main'
        return 'g@'
    endif

    var type: string
    if arg_lnum2 == 0
        type = arg_type
    else
        type = 'Ex'
    endif

    if empty(&l:cms)
        return ''
    endif

    # Define the range of lines to (un)comment.
    var lnum1: number
    var lnum2: number
    if type == 'Ex'
        [lnum1, lnum2] = [arg_type, arg_lnum2]
    else
        [lnum1, lnum2] = [line("'["), line("']")]
    endif

    # comment leader (with a padding space at the end)
    var l_: string
    # end-comment leader (with a padding space at the start; or just an empty string)
    var r_: string
    [l_, r_] = comment#util#getCml()

    var uncomment: number = DoWeUncomment(lnum1, lnum2, l_, r_)

    # Why do you get the indent of first line?{{{
    #
    # When we comment, if we simply add the left part of the comment string
    # right before the first non whitespace of each line, and the latter have
    # different levels of indentation, the comment characters won't be aligned.
    #
    # We want all of them to be aligned under the first one.
    # To do this, we need to know the level of indentation of the first line.
    #}}}
    var indent: string = getline(lnum1)->matchstr('^\s*')

    for lnum in range(lnum1, lnum2)
        var line: string = getline(lnum)

        # Don't do anything if the line is empty.
        if line !~ '\S'
            continue
        endif

        var l: string
        var r: string
        [l, r] = comment#util#maybeTrimCml(line, l_, r_)

        # Add support for nested comments.
        # Example: In an html file:
        #
        #     <!-- hello world -->                          comment
        #     <!-- <1!-- hello world --1> -->               comment in a comment
        #     <!-- <1!-- <2!-- hello world --2> --1> -->    comment in a comment in a comment

        #            ┌ the end-comment leader should have at least 2 characters:{{{
        #            │         -->
        #            │ … otherwise the incrementation/decrementation could affect
        #            │ numbers inside the comment text, which are not concerned:
        #            │         r = 'x'
        #            │         right_number = r[: -2] .. '\zs\d\+\ze' .. r[-1 : -1]
        #            │                      = '\zs\d\+\zex'
        #            │ }}}
        if strlen(r) >= 2 && l .. r !~ '\\'
        #                               │
        #                               └ No matter the magicness of a pattern, a backslash
        #                                 has always a special meaning.  So, we make sure
        #                                 that there's none in the comment leader.

            var left_number: string = l[0] .. '\zs\d\*\ze' .. l[1 :]
            var right_number: string = r[: -2] .. '\zs\d\*\ze' .. r[-1 : -1]
            var pat: string = '\V' .. left_number .. '\|' .. right_number
            var Rep: func = (m: string): string =>
                m[0]->str2nr() - uncomment + 1 <= 0
                    ? ''
                    : m[0]->str2nr() - uncomment + 1
            line = substitute(line, pat, Rep, 'g')
        endif

        var pat: string
        var Rep: func
        if uncomment != 0
            pat = '\S.*\s\@1<!'
            Rep = (m: list<string>): string => m[0][strlen(l) : -1 - strlen(r)]
        else
            pat = '^\%(' .. indent .. '\|\s*\)\zs.*'
            # Why?{{{
            #
            # Without,  a comment  leader may  be misaligned  if it  comments an
            # empty commented line.
            #
            # ---
            #
            # Select these lines:
            #
            #     echo ''
            #         " foo
            #         "
            #         " bar
            #
            # Comment them by pressing `gc`.
            #
            # Result:
            #
            #     " echo ''
            #     "      " foo
            #     "     "
            #     "      " bar
            #
            # Notice  how the  comment leader  on the  third line  is misaligned
            # compared to the other ones.
            # We want this instead:
            #
            #     " echo ''
            #     "      " foo
            #     "      "
            #     "      " bar
            #}}}
            if line =~ '^\s*' .. l .. '$'
                l ..= ' '
            endif
            Rep = (m: list<string>): string => l .. m[0] .. r
        endif

        line = substitute(line, pat, Rep, '')
        setline(lnum, line)
    endfor

    # fire a custom event to allow us executing a callback after (un)commenting some text
    if exists('#User#CommentTogglePost')
        do <nomodeline> User CommentTogglePost
    endif

    return ''
enddef
#}}}1
# Core {{{1
def DoWeUncomment(lnum1: number, lnum2: number, l_: string, r_: string): number
    # by default, let's assume we want to uncomment
    # Why 2 instead of 1?{{{
    #
    # Nested comments use numbers to express the level of imbrication.
    # 2 is a convenient value to compute a decremented level:
    #
    #     var new_lvl: number = old_lvl - uncomment + 1
    #                                     │
    #                                     └ should be 2 for `new_lvl` to be correct
    #}}}
    var uncomment: number = 2
    for lnum in range(lnum1, lnum2)
        var line: string = getline(lnum)
        # if needed for the current line, trim the comment leader
        var l: string
        var r: string
        [l, r] = comment#util#maybeTrimCml(line, l_, r_)
        # to comment a range of lines, one of them must be non-empty and non-commented
        if line =~ '\S' && !comment#util#isCommented(line, l, r)
            uncomment = 0
        endif
    endfor
    return uncomment
enddef

