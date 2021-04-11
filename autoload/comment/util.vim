vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import IsVim9 from 'lg.vim'

def comment#util#getCml(): list<string> #{{{1
    # handle Vim9 comments
    if IsVim9()
        return ['# ', '']
    endif

    # This function should return a list of 2 strings:
    #
    #    - the beginning of a comment string; e.g. for vim:    `" `
    #    - the end of a comment string;       e.g. for html:   ` -->`

    return &l:cms
        # make sure there's a space between the comment leader and the comment:
        #         "%s   →   " %s
        # more readable
        ->substitute('\S\zs\ze%s', ' ', '')
        # make sure there's a space between the comment and the end-comment leader
        #         <-- %s-->    →    <-- %s -->
        ->substitute('%s\zs\ze\S', ' ', '')
        # return the comment leader, and the possible end-comment leader,
        # through a list of 2 items
        ->split('%s', true)
        #             │
        #             └ always return 2 items, even if there's nothing
        #               after `%s` (in this case, the 2nd item will be '')
enddef

def comment#util#maybeTrimCml( #{{{1
    line: string,
    l_: string,
    r_: string
): list<string>

    var l: string = l_->trim(' ', 2)
    var r: string = r_->trim(' ', 1)

    # if the  line is commented with  the trimmed comment leaders,  but not with
    # the space-padded ones, return the trimmed ones
    if comment#util#isCommented(line, l, r) && !comment#util#isCommented(line, l_, r_)
        return [l, r]
    endif

    # don't break `:h line-continuation-comment` when commenting a line starting
    # with a backslash (i.e. don't insert a space between the comment leader and
    # the backslash)
    if &ft == 'vim' && line =~ '^\s*\\ ' && l_ =~ '"'
        return ['"', '']
    endif

    # by default, return the space-padded comment leaders
    return [l_, r_]
enddef

def comment#util#isCommented( #{{{1
    arg_line: string,
    l: string,
    r: string
): bool
    #                                      ┌ trim beginning whitespace
    #                                      │
    var line: string = matchstr(arg_line, '\S.*\s\@1<!')
    #                                            ├─────┘
    #                                            └ trim ending whitespace

    #      ┌ the line begins with the comment leader
    #      ├────────────────────┐
    return stridx(line, l) == 0 && line[strcharlen(line) - strcharlen(r) :] == r
    #                              └──────────────────────────────────────┤
    #                            it also ends with the end-comment leader ┘
enddef

