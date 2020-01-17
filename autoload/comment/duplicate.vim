fu comment#duplicate#main(type) abort "{{{1
    let cb_save = &cb
    let sel_save = &selection
    let reg_save = ['"', getreg('"'), getregtype('"')]
    try
        set cb-=unnamed cb-=unnamedplus
        set selection=inclusive

        " TODO: prevent the function from doing anything if a line is already commented.
        " For example, if you press by accident `+dd` twice on the same line, it
        " shouldn't do anything the second time.
        if a:type is# 'vis'
            sil '<,'>yank
            '<,'>CommentToggle
            " add four spaces between comment  leader and beginning of the text,
            " so that if it's code, it's highlighted as a code block
            sil exe "'<,'>s/^\\s*\\V"..escape(matchstr(comment#util#get_cml(), '\S*'), '\/')..'\m\zs/    /'
            norm! `>]p
        else
            sil norm! '[y']
            '[,']CommentToggle
            sil exe "'[,']s/^\\s*\\V"..escape(matchstr(comment#util#get_cml(), '\S*'), '\/')..'\m\zs/    /'
            norm! `]]p
        endif
    catch
        return lg#catch_error()
    finally
        let &cb = cb_save
        let &sel = sel_save
        call call('setreg', reg_save)
    endtry
endfu

