" Interface {{{1
fu comment#paste#main(where, how_to_indent) abort "{{{2
    " In a markdown file, there're no comments.
    " However, it could still be useful to format the text as code output or quote.
    if &ft is# 'markdown'
        let is_quote = indent('.') == 0
        call s:paste(a:where)
        let [start, end] = [line("'["), line("']")]
        if is_quote
            '[,']CommentToggle
        else
            " Which alternatives could I use?{{{
            "
            "     let [wrap_save, winid, bufnr] = [&l:wrap, win_getid(), bufnr('%')]
            "     try
            "         setl nowrap
            "         exe "norm! '[V']\<c-v>0o$A~"
            "     finally
            "         if winbufnr(winid) == bufnr
            "             let [tabnr, winnr] = win_id2tabwin(winid)
            "             call settabwinvar(tabnr, winnr, '&wrap', wrap_save)
            "         endif
            "     endtry
            "
            " ---
            "
            "     call setreg(v:register, join(map(getreg(v:register, 1, 1),
            "         \ {_,v -> substitute(v, '$', '\~', '')}), "\n"), 'l')
            "}}}

            " Do *not* use this `norm! '[V']A~`!{{{
            "
            " This sequence  of keys works  in an interactive usage,  because of
            " our custom  mapping `x_A`, but  it would fail with  `:norm!` (note
            " the bang).
            " It  would probably  work with  `:norm` though,  although it  would
            " still fail on a long wrapped line (see next comment).
            "}}}
            "     nor this `exe "norm! '[V']\<c-v>0o$A~"`!{{{
            "
            " This is better, because it doesn't rely on any custom mapping.
            "
            " But, it would still fail on a long line wrapped onto more than one
            " screen line; that is, `~` would not be appended at the very end of
            " the line, but a few characters  before; the more screen lines, the
            " more characters before the end.
            "
            " MWE:
            "
            "     $ vim +'put =repeat(\"a\", winwidth(0)-5).\"-aaa\nb\"' +'setl wrap' +'exe "norm! 1GV+\<c-v>0o$A~"'
            "
            " The explanation of this behavior may be given at `:h v_b_A`.
            " Anyway, with a long wrapped line,  it's possible that the block is
            " defined in a weird way.
            "}}}
            sil keepj keepp '[,']g/^/norm! A~
            sil keepj keepp '[,']g/^\~$/s/\~//
        endif
    else
        let [l, r] = comment#util#get_cml()
        let l = matchstr(l, '\S*')

        call s:paste(a:where)
        " some of the next commands may alter the change marks; save them now
        let [start, end] = [line("'["), line("']")]
        let range = start..','..end
        " comment
        exe range..'CommentToggle'
        " I don't like empty non-commented line in "the middle of a multi-line comment.
        sil exe 'keepj keepp '..range..'g/^$/'
            \ ..'exe "norm! i\<c-v>\<c-a>"'
            \ ..' | CommentToggle'
            \ ..' | exe "norm! =="'
            \ ..' | s/\s*\%x01//e'

        " If `>cp` is pressed, increase the indentation of the text *after* the comment leader.{{{
        "
        " This allows us  to paste some code and highlight it  as a codeblock in
        " one single mapping.
        "}}}
        if a:how_to_indent is# '>'
            sil exe 'keepj keepp '..range..'s/^\s*\V'..escape(l, '\/')..'\m\zs\ze.*\S/    /e'
            "                                                                 ├─────┘
            "                                                                 └ don't add trailing whitespace
            "                                                                   on an empty commented line
            return
        endif
    endif
    if a:how_to_indent isnot# ''
        exe 'norm! '..start..'G'..a:how_to_indent..end..'G'
    endif
endfu
"}}}1
" Core {{{1
fu s:paste(where) abort "{{{2
    " Do *not* remove the bang.{{{
    "
    " We have a custom mapping which replaces `""` with `"+`.
    " We use it because it's convenient in an interactive usage (easier to type).
    " But we don't want it to interfere here (we're in a script now).
    "}}}
    exe 'norm! "'..v:register
    " Do *not* add a bang.{{{
    "
    " We need our custom `]p` to be pressed so that the the text is pasted as if
    " it was linewise, even if in reality it's characterwise.
    "}}}
    exe 'norm '..a:where..'p'
endfu

