vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def comment#motion#main(is_fwd = true): string #{{{2
    # This function positions the cursor on the next/previous beginning of a comment.
    # Inspiration: $VIMRUNTIME/ftplugin/vim.vim

    if empty(&l:cms)
        return ''
    endif

    var mode: string = mode(true)

    var seq: string
    if mode == 'n'
        seq ..= "m'"
    endif

    var pat: string = GetSearchPat()

    # Why `1|`?{{{
    #
    # Necessary when:
    #
    #    - we look for a pattern, like the previous beginning of a comment section
    #    - the current line matches
    #    - we want to ignore this match
    #
    # `norm! 1|` + no `c` flag in search() = no match  ✔
    #}}}
    # Why not in operator-pending mode?{{{
    #
    # This function is going to return something like:
    #
    #     1|123G
    #
    # For Vim, `1|` will be the object, and `123G` just a simple motion.
    # That's not what we want.
    #}}}
    seq ..= mode =~ "[nvV\<c-v>]"
        ?     '1|'
        :     ''

    # don't remove the `W` flag; I like knowing when I've reached the last/first comment
    var res: list<number> = searchpos(pat, (is_fwd ? '' : 'b') .. 'W')
    # we need `virtcol()` to handle a possible leading tab character
    var lnum: number = line('.')
    var vcol: number = virtcol('.')
    if res != [0, 0]
        # we need to  return this sequence, because we use  an `<expr>` mapping,
        # and Vim is going to restore the cursor position
        seq ..= lnum .. 'G' .. vcol .. '|'
    else
        return ''
    endif

    if mode == 'n'
        seq ..= 'zMzv'
    elseif mode =~ "^[vV\<c-v>]$"
        # don't close fold in visual mode,
        # it makes Vim select whole folds instead of some part of them
        seq ..= 'zv'
    endif

    return seq
enddef
#}}}1
# Util {{{1
def GetSearchPat(): string #{{{2
    var l: string
    if &ft == 'vim'
        l = '["#]'
    else
        var cml: list<string> = split(&l:cms, '%s')
        l = '\V' .. matchstr(cml[0], '\S\+')->escape('\') .. '\m'
    endif

    # We're looking for a commented line of text.
    # It must begin a fold.
    # Or the line before must not be commented.
    #
    #                  ┌ no commented line just before
    #                  │                            ┌ a commented line of text
    #                  ├───────────────────────────┐├──────────┐
    var pat: string = '^\%(^\s*' .. l .. '.*\n\)\@<!\s*\zs' .. l
        .. '\|^\s*\zs' .. l .. '.*{{' .. '{'
    return pat
enddef

