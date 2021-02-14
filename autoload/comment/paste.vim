vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def comment#paste#main(where: string, how_to_indent: string) #{{{2
    var cnt: number = v:count1
    var view: dict<number> = winsaveview()
    # you can get a weird result if you paste some text containing a fold marker;
    # let's disable folding temporarily, to avoid any interference
    var fen_save: bool = &l:fen | setl nofen

    var start: number
    var end: number
    var change_pos: list<number>
    # In a markdown file, there're no comments.
    # However, it could still be useful to format the text as code output or quote.
    if &ft == 'markdown'
        var is_quote: bool = indent('.') == 0
        Paste(where)
        change_pos = getpos("'[")
        start = line("'[")
        end = line("']")
        if is_quote
            :'[,']CommentToggle
        else
            # Which alternatives could I use?{{{
            #
            #     var wrap_save: bool = &l:wrap
            #     var winid: number
            #     var bufnr: number
            #     try
            #         setl nowrap
            #         exe "norm! '[V']\<c-v>0o$A~"
            #     finally
            #         if winbufnr(winid) == bufnr
            #             var tabnr: number
            #             var winnr: number
            #             [tabnr, winnr] = win_id2tabwin(winid)
            #             settabwinvar(tabnr, winnr, '&wrap', wrap_save)
            #         endif
            #     endtry
            #
            # ---
            #
            #     var reginfo: dict<any> = getreginfo(v:register)
            #     var contents: list<string> = get(reginfo, 'regcontents', [])
            #     map(contents, (_, v) => substitute(v, '$', '\~', ''))
            #     deepcopy(reginfo)
            #         ->extend({regcontents: contents, regtype: 'l'})
            #         ->setreg(v:register)
            #
            #     ...
            #     Paste(where)
            #     ...
            #     setreg(v:register, reginfo)
            #}}}

            # Do *not* use this `norm! '[V']A~`!{{{
            #
            # This sequence  of keys works  in an interactive usage,  because of
            # our custom  mapping `x_A`, but  it would fail with  `:norm!` (note
            # the bang).
            # It  would probably  work with  `:norm` though,  although it  would
            # still fail on a long wrapped line (see next comment).
            #}}}
            #     nor this `exe "norm! '[V']\<c-v>0o$A~"`!{{{
            #
            # This is better, because it doesn't rely on any custom mapping.
            #
            # But, it would still fail on a long line wrapped onto more than one
            # screen line; that is, `~` would not be appended at the very end of
            # the line, but a few characters  before; the more screen lines, the
            # more characters before the end.
            #
            # MWE:
            #
            #     $ vim +'put =repeat(\"a\", winwidth(0) - 5) .. \"-aaa\nb\"' +'setl wrap' +'exe "norm! 1GV+\<c-v>0o$A~"'
            #
            # The explanation of this behavior may be given at `:h v_b_A`.
            # Anyway, with a long wrapped line,  it's possible that the block is
            # defined in a weird way.
            #}}}
            sil keepj keepp :'[,']g/^/norm! A~
            sil keepj keepp :'[,']g/^\~$/s/\~//
        endif
    else
        var l: string
        var r: string
        if &l:cms != ''
            [l, r] = comment#util#getCml()
            l = matchstr(l, '\S*')
        else
            l = ''
        endif

        Paste(where)
        change_pos = getpos("'[")

        # some of the next commands may alter the change marks; save them now
        start = line("'[")
        end = line("']")
        var range: string = ':' .. start .. ',' .. end
        # comment
        exe range .. 'CommentToggle'
        # I don't like empty non-commented line in "the middle of a multi-line comment.
        sil exe 'keepj keepp ' .. range .. 'g/^$/'
            .. 'exe "norm! i\<c-v>\<c-a>"'
            .. ' | CommentToggle'
            .. ' | exe "norm! =="'
            .. ' | s/\s*\%x01//e'
        # If `>cp` is pressed, increase the indentation of the text *after* the comment leader.{{{
        #
        # This lets us  paste some code and  highlight it as a  codeblock in one
        # single mapping.
        #}}}
        if how_to_indent == '>'
            #                                                      ┌ don't add trailing whitespace on an empty commented line
            #                                                      ├─────┐
            var pat: string = '^\s*\V' .. escape(l, '\/') .. '\m\zs\ze.*\S'
            var rep: string = repeat(' ', &l:sw * cnt)
            sil exe 'keepj keepp ' .. range .. 's/' .. pat .. '/' .. rep .. '/e'
        endif
    endif
    if how_to_indent != '' && how_to_indent != '>'
        exe 'norm! ' .. start .. 'G' .. how_to_indent .. end .. 'G'
    endif
    &l:fen = fen_save
    winrestview(view)
    setpos('.', change_pos)
    search('\S', 'cW')
enddef
#}}}1
# Core {{{1
def Paste(where: string) #{{{2
    # Do *not* remove the bang.{{{
    #
    # We have a custom mapping which replaces `""` with `"+`.
    # We use it because it's convenient in an interactive usage (easier to type).
    # But we don't want it to interfere here (we're in a script now).
    #}}}
    exe 'norm! "' .. v:register
    # Do *not* add a bang.{{{
    #
    # We need our custom `]p` to be pressed so that the the text is pasted as if
    # it was linewise, even if in reality it's characterwise.
    #}}}
    exe 'norm ' .. where .. 'p'
enddef

