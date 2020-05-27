fu comment#half#setup(dir) abort "{{{1
    let s:half_to_comment = a:dir
    let &opfunc = 'comment#half#do'
    return 'g@l'
endfu
"}}}1
fu comment#half#do(_) abort "{{{1
    let half = get(s:, 'half_to_comment', '')
    let first_lnum = line("'{")+1
    let last_lnum = line("'}")-1
    if line("'{") == 1 && getline(1) =~# '\S' | let first_lnum = 1 | endif
    if line("'}") == line('$') && getline('$') =~# '\S' | let last_lnum = line('$') | endif
    let d = last_lnum - first_lnum + 1
    if half is# 'top'
        let [lnum1, lnum2] = [first_lnum, first_lnum + d/2 - (d%2 == 0)]
    else
        let [lnum1, lnum2] = [last_lnum - d/2 + 1, last_lnum]
    endif
    exe lnum1..','..lnum2..'CommentToggle'
    " position cursor on first/last line of the remaining uncommented block of lines
    exe half is# 'top' ? lnum2 : lnum1
endfu

