fu comment#util#get_cml() abort "{{{1
    " This function should return a list of 2 strings:
    "
    "    - the beginning of a comment string; e.g. for vim:    `" `
    "    - the end of a comment string;       e.g. for html:   ` -->`

    let cml = &l:cms

    " make sure there's a space between the comment leader and the comment:
    "         "%s   →   " %s
    " more readable
    let cml = substitute(cml, '\S\zs\ze%s', ' ', '')

    " make sure there's a space between the comment and the end-comment leader
    "         <-- %s-->    →    <-- %s -->
    let cml = substitute(cml,'%s\zs\ze\S', ' ', '')

    " return the comment leader, and the possible end-comment leader,
    " through a list of 2 items
    return split(cml, '%s', 1)
    "                       │
    "                       └ always return 2 items, even if there's nothing
    "                         after `%s` (in this case, the 2nd item will be '')
endfu

fu comment#util#maybe_trim_cml(line, l_, r_) abort "{{{1
    let [l_, r_] = [a:l_    , a:r_]
    let [l, r]   = [l_[0:-2], r_[1:]]
    "                 ├────┘    ├──┘{{{
    "                 │         └ remove 1st  whitespace
    "                 │
    "                 └ remove last whitespace
    "}}}

    " if the line is commented with the trimmed comment leaders, but not with
    " the original ones, return the trimmed ones
    if comment#util#is_commented(a:line, l, r) && !comment#util#is_commented(a:line, l_, r_)
        return [l, r]
    endif

    " by default, return the original ones
    return [l_, r_]
endfu

fu comment#util#is_commented(line, l, r) abort "{{{1
    "                            ┌ trim beginning whitespace
    "                            │
    let line = matchstr(a:line, '\S.*\s\@1<!')
    "                                ├─────┘
    "                                └ trim ending whitespace

    "      ┌ the line begins with the comment leader
    "      ├────────────────────┐
    return stridx(line, a:l) == 0 && line[strlen(line)-strlen(a:r):] is# a:r
    "                                └─────────────────────────────────────┤
    "                             it also ends with the end-comment leader ┘
endfu

