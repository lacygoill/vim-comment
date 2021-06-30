vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Declarations {{{1

var where: string
var how_to_indent: string

# Interface {{{1
def comment#paste#setup(arg_where: string, how: string): string #{{{2
    where = arg_where
    how_to_indent = how
    &operatorfunc = expand('<SID>') .. 'Do'
    return 'g@l'
enddef
#}}}1
# Core {{{1
def Do(_) #{{{2
    var cnt: number = v:count1
    var view: dict<number> = winsaveview()
    # you can get a weird result if you paste some text containing a fold marker;
    # let's disable folding temporarily, to avoid any interference
    var foldenable_save: bool = &l:foldenable | &l:foldenable = false

    var start: number
    var end: number
    var change_pos: list<number>
    # In a markdown file, there're no comments.
    # However, it could still be useful to format the text as code output or quote.
    if &filetype == 'markdown'
        var is_quote: bool = indent('.') == 0
        Paste()
        change_pos = getpos("'[")
        start = line("'[")
        end = line("']")
        if is_quote
            :'[,'] CommentToggle
        else
            # Which alternatives could I use?{{{
            #
            #     var wrap_save: bool = &l:wrap
            #     var winid: number
            #     var bufnr: number
            #     try
            #         &l:wrap = false
            #         execute "normal! '[V']\<C-V>0o$A˜"
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
            #         ->map((_, v: string): string => v->substitute('$', '˜', ''))
            #     deepcopy(reginfo)
            #         ->extend({regcontents: contents, regtype: 'l'})
            #         ->setreg(v:register)
            #
            #     ...
            #     Paste()
            #     ...
            #     setreg(v:register, reginfo)
            #}}}

            # Do *not* use this `normal! '[V']A˜`!{{{
            #
            # This sequence  of keys works  in an interactive usage,  because of
            # our custom mapping `x_A`, but  it would fail with `:normal!` (note
            # the bang).
            # It would  probably work with  `:normal` though, although  it would
            # still fail on a long wrapped line (see next comment).
            #}}}
            #     nor this `execute "normal! '[V']\<C-V>0o$A˜"`!{{{
            #
            # This is better, because it doesn't rely on any custom mapping.
            #
            # But, it would still fail on a long line wrapped onto more than one
            # screen line; that is, `˜` would not be appended at the very end of
            # the line, but a few characters  before; the more screen lines, the
            # more characters before the end.
            #
            # MWE:
            #
            #     $ vim +'put =repeat(\"a\", winwidth(0) - 5) .. \"-aaa\nb\"' +'setlocal wrap' +'execute "normal! 1GV+\<C-V>0o$A˜"'
            #
            # The explanation of this behavior may be given at `:help v_b_A`.
            # Anyway, with a long wrapped line,  it's possible that the block is
            # defined in a weird way.
            #}}}
            silent keepjumps keeppatterns :'[,'] global/^/normal! A˜
            silent keepjumps keeppatterns :'[,'] global/^˜$/ substitute/˜//
        endif
    else
        var l: string
        var r: string
        if &commentstring != ''
            [l, r] = comment#util#getCml()
            l = l->matchstr('\S*')
        else
            l = ''
        endif

        Paste()
        change_pos = getpos("'[")

        # some of the next commands may alter the change marks; save them now
        start = line("'[")
        end = line("']")
        var range: string = ':' .. start .. ',' .. end
        # comment
        execute range .. 'CommentToggle'
        # I don't like empty non-commented line in "the middle of a multi-line comment.
        execute 'silent keepjumps keeppatterns ' .. range .. 'global/^$/CommentEmptyLine()'
        # If `>cp` is pressed, increase the indentation of the text *after* the comment leader.{{{
        #
        # This lets us  paste some code and  highlight it as a  codeblock in one
        # single mapping.
        #}}}
        if how_to_indent == '>'
            var pat: string = '^\s*'
                .. '\V' .. escape(l, '\/')
                .. '\m' .. '\zs\ze.*\S'
                #              ├─────┘
                #              └ don't add trailing whitespace on an empty commented line
            # Do *not* replace `4` with `&l:shiftwidth`.{{{
            #
            # We often press `>cp` on a comment codeblock.
            # Those are always  indented with 4 spaces after  the comment leader
            # (and the space which always needs to follow for readability).
            #
            # And  when we  do,  we usually  expect the  pasted  line to  become
            # a  part  of the  codeblock.   That  wouldn't  happen if  we  wrote
            # `&l:shiftwidth` and the latter was not 4 (e.g. it could be 2).
            #}}}
            var rep: string = repeat(' ', 4 * cnt)
            execute 'silent keepjumps keeppatterns ' .. range .. 'substitute/' .. pat .. '/' .. rep .. '/e'
        endif
    endif
    if how_to_indent != '' && how_to_indent != '>'
        execute 'normal! ' .. start .. 'G' .. how_to_indent .. end .. 'G'
    endif
    &l:foldenable = foldenable_save
    winrestview(view)
    setpos('.', change_pos)
    search('\S', 'cW')
enddef

def Paste() #{{{2
    # Make sure the next `]p` command puts  the text as if it was linewise, even
    # if in reality it's characterwise.
    getreginfo(v:register)
        ->extend({regtype: 'l'})
        ->setreg(v:register)
    execute 'normal! "' .. v:register .. where .. 'p'
enddef

def CommentEmptyLine() #{{{2
    execute "normal! i\<C-V>\<C-A>"
    CommentToggle
    normal! ==
    substitute/\s*\%x01//e
enddef

