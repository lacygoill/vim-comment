fu comment#duplicate#main() abort "{{{1
    let &opfunc = 'lg#opfunc'
    let g:opfunc_core = 'comment#duplicate#main_core'
    return 'g@'
endfu

fu comment#duplicate#main_core(_) abort
    " TODO: prevent the function from doing anything if a line is already commented.
    " For example, if you press by accident `+dd` twice on the same line, it
    " shouldn't do anything the second time.
    sil norm! '[y']
    '[,']CommentToggle
    sil exe "'[,']s/^\\s*\\V"..comment#util#get_cml()[0]->matchstr('\S*')->escape('\/')..'\m\zs/    /'
    norm! `]]p
endfu

