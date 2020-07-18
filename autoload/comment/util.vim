fu comment#util#get_cml() abort "{{{1
    " handle Vim9 comments
    if &ft is# 'vim' && getline(1) is# 'vim9script'
        return ['# ', '']
    endif

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

fu comment#util#maybe_trim_cml(line, l_, _r) abort "{{{1
    let [l_, _r] = [a:l_    , a:_r]
    let [l, r]   = [l_[0:-2], _r[1:]]
    "                 ├────┘    ├──┘{{{
    "                 │         └ remove 1st whitespace
    "                 │
    "                 └ remove last whitespace
    "}}}

    " if the  line is commented with  the trimmed comment leaders,  but not with
    " the space-padded ones, return the trimmed ones
    if comment#util#is_commented(a:line, l, r) && !comment#util#is_commented(a:line, l_, _r)
        return [l, r]
    endif

    " don't break `:h line-continuation-comment` when commenting
    if &ft is# 'vim' && a:line =~# '^\s*\\ '
        return ['"', '']
    endif

    " by default, return the space-padded comment leaders
    return [l_, _r]
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

