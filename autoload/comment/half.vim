fu comment#half#main(_) abort "{{{1
    let first_line = line("'{")+1
    let last_line = line("'}")-1
    if line("'{") == 1 && getline(1) =~# '\S' | let first_line = 1 | endif
    if line("'}") == line('$') && getline('$') =~# '\S' | let last_line = line('$') | endif
    let d = last_line - first_line + 1
    if get(s:, 'half_to_comment', '') is# 'top'
        let range = first_line..','..(first_line + d/2 - (d%2 != 0))
    else
        let range = (last_line - d/2 + (d%2 == 0))..','..last_line
    endif
    exe range..'CommentToggle'
endfu

fu comment#half#save(where) abort "{{{1
    let s:half_to_comment = a:where
endfu

