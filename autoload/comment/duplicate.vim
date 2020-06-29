fu comment#duplicate#main(...) abort "{{{1
    if !a:0
        let &opfunc = 'comment#duplicate#main'
        return 'g@'
    endif
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = getreginfo('"')
    try
        set cb= sel=inclusive

        " TODO: prevent the function from doing anything if a line is already commented.
        " For example, if you press by accident `+dd` twice on the same line, it
        " shouldn't do anything the second time.
        sil norm! '[y']
        '[,']CommentToggle
        sil exe "'[,']s/^\\s*\\V"..escape(matchstr(comment#util#get_cml()[0], '\S*'), '\/')..'\m\zs/    /'
        norm! `]]p
    catch
        return lg#catch()
    finally
        let [&cb, &sel] = [cb_save, sel_save]
        call setreg('"', reg_save)
    endtry
endfu

