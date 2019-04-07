if exists('g:autoloaded_comment')
    finish
endif
let g:autoloaded_comment = 1

let s:operate_on = 'text'

fu! comment#and_paste(dir) abort "{{{1
    exe 'norm ' . a:dir . 'p'
    norm gc`]
    " I don't like empty non-commented line in the middle of a multi-line comment.
    sil keepj keepp '[,']g/^$/exe "norm! i\<c-v>\<c-a>" | exe 'norm gcc' | s/\s*\%x01//e
endfu

fu! comment#duplicate(type) abort "{{{1
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
            sil exe "'<,'>s/^\\s*\\V".escape(matchstr(s:get_cml(), '\S*'), '\/').'\m\zs/    /'
            norm! `>]p
        else
            sil norm! '[y']
            '[,']CommentToggle
            sil exe "'[,']s/^\\s*\\V".escape(matchstr(s:get_cml(), '\S*'), '\/').'\m\zs/    /'
            norm! `]]p
        endif
    catch
        return lg#catch_error()
    finally
        let &cb  = cb_save
        let &sel = sel_save
        call call('setreg', reg_save)
    endtry
endfu

fu! s:get_cml() abort "{{{1
    " This function should return a list of 2 strings:
    "
    "     - the beginning of a comment string; e.g. for vim:    `" `
    "     - the end of a comment string;       e.g. for html:   ` -->`

    " if we operate on lines of code, make sure the comment leader ends with `@`
    let cms = get(s:, 'operate_on', 'text') is# 'code'
          \ ?     substitute(&l:cms, '\ze\s*%s', '@', '')
          \ :     &l:cms

    " make sure there's a space between the comment leader and the comment:
    "         "%s   →   " %s
    " more readable
    let cms = substitute(cms, '\S\zs\ze%s', ' ', '')

    " make sure there's a space between the comment and the end-comment leader
    "         <-- %s-->    →    <-- %s -->
    let cms = substitute(cms,'%s\zs\ze\S', ' ', '')

    " return the comment leader, and the possible end-comment leader,
    " through a list of 2 items
    return split(cms, '%s', 1)
    "                       │
    "                       └─ always return 2 items, even if there's nothing
    "                          after `%s` (in this case, the 2nd item will be '')
endfu

fu! s:get_search_pat(kind) abort "{{{1
    " ['"']         in Vim
    " ['/*', '*/']  in C
    let cml = split(&l:cms, '%s')

    " \V"\v           in Vim
    " \V/*\v          in C
    let l = '\V'.escape(matchstr(cml[0], '\S\+'), '\').'\v'

    " \V"\v           in Vim
    " \V*/\v          in C
    let r = len(cml) ==# 2 ? '\V'.escape(matchstr(cml[1], '\S\+'), '\').'\v' : l

    if a:kind is# 'text'
        " We're looking for a commented line of text.
        " It must begin a fold.
        " OR the line before must be:
        "         - NOT commented
        "         - a commented line of code
        "
        "                                 ┌──────────── NO commented line just before
        "                                 │           ┌ a commented line of text
        "              ┌──────────────────┤┌──────────┤
        let pat  =  '\v^%(^\s*'.l.'.*\n)@<!\s*'.l.'\@@!'
        let pat .= '|^%(^\s*'.l.'\@.*\n)@<=\s*'.l.'\@@!'
        "            └────────────────────┤
        "                                 └──────────── a commented line of code
        "                                               just before a commented line of text
        let pat .= '|^\s*'.l.'\@@!.*\{\{\{'

    else
        "                                   ┌────────── NO commented line just before
        "                                   │         ┌ a commented line of code
        "                ┌──────────────────┤┌────────┤
        let pat  =    '\v^%(^\s*'.l.'.*\n)@<!\s*'.l.'\@'
        let pat .= '|^%(^\s*'.l.'\@@!.*\n)@<=\s*'.l.'\@'
        "            └──────────────────────┤
        "                                   └ a commented line of text
        "                                     just before a commented line of code
        let pat .= '|^\s*'.l.'\@.*\{\{\{'
    endif
    return pat
endfu

fu! s:is_commented(line, l, r) abort "{{{1
    "                            ┌─ trim beginning whitespace
    "                            │
    let line = matchstr(a:line, '\S.*\s\@1<!')
    "                                └─────┤
    "                                      └ trim ending whitespace

    "                            ┌ the line begins with the comment leader
    "      ┌─────────────────────┤
    return stridx(line, a:l) ==# 0 && line[strlen(line)-strlen(a:r):] is# a:r
    "                                 └─────────────────────────────────────┤
    "                              it also ends with the end-comment leader ┘
endfu

fu! s:is_commented_code(line) abort "{{{1
    let line = matchstr(a:line, '\S.*\s\@1<!')

    return   stridx(line, s:l.'@') ==# 0
        &&   line[strlen(line)-strlen(s:r):] is# s:r
endfu

fu! s:is_commented_text(line) abort "{{{1
    let line = matchstr(a:line, '\S.*\s\@1<!')

    return   stridx(line, s:l) ==# 0
       \ &&  stridx(line, s:l.'@') ==# -1
       \ &&  line[strlen(line)-strlen(s:r):] is# s:r
endfu

fu! s:is_relevant(line) abort "{{{1
    return  !(s:operate_on is# 'code' && s:is_commented_text(a:line))
       \ && !(s:operate_on is# 'text' && s:is_commented_code(a:line))
endfu

fu! s:maybe_trim_cml(line, l_, r_) abort "{{{1
    let [l_, r_] = [a:l_    , a:r_]
    let [l, r]   = [l_[0:-2], r_[1:]]
    "                 ├────┘    ├──┘{{{
    "                 │         └ remove 1st  whitespace
    "                 │
    "                 └ remove last whitespace
    "}}}

    " if the line is commented with the trimmed comment leaders, but not with
    " the original ones, return the trimmed ones
    if s:is_commented(a:line, l, r) && !s:is_commented(a:line, l_, r_)
        return [l, r]
    endif

    " by default, return the original ones
    return [l_, r_]
endfu

fu! comment#object(op_is_c) abort "{{{1
    let [s:l, s:r] = split(&l:cms, '%s', 1)
    let [l_, r_]   = s:get_cml()
    let boundaries = [line('.')+1, line('.')-1]

    " We consider a line to be in a comment object iff it's:{{{
    "
    "         - commented
    "         - relevant
    "         - not the start/end of a fold
    " … OR:
    "         - an empty line
    "
    "           If the boundary has reached the end/beginning of the buffer,
    "           there's no next line.
    "           But `getline()` will still return an empty string.
    "           So the test:
    "
    "                   next_line !~ '\S'
    "
    "           … will succeed, wrongly.
    "           We mustn't include this non-existent line.
    "           Otherwise, we'll be stuck in an infinite loop,
    "           forever (inc|dec)rementing the boundary and forever including
    "           new non-existent lines.
    "           Hence:
    "                   boundaries[which] !=# limit
"}}}
    let l:Next_line_is_in_object = { ->    s:is_commented(next_line, l, r)
        \     && s:is_relevant(next_line)
        \
        \     || next_line !~ '\S' && boundaries[which] !=# limit
        \ }

    "       ┌ 0 or 1:  upper or lower boundary
    "       │
    for  [which,   dir,       limit,      next_line]
  \ in  [[    0,    -1,           1,   getline('.')]
  \ ,    [    1,     1,   line('$'),   getline('.')]]

        let [l , r] = s:maybe_trim_cml(getline('.'), l_, r_)
        while l:Next_line_is_in_object()
            " stop if the boundary has reached the beginning/end of a fold
            if match(next_line, '{{{\|}}}') !=# -1
                break
            endif

            " the test was successful so (inc|dec)rement the boundary
            let boundaries[which] += dir

            " update `line`, `l`, `r` before next test
            let next_line = getline(boundaries[which]+dir)
            let [l, r]    = s:maybe_trim_cml(next_line, l_, r_)
        endwhile
    endfor

    let l:Invalid_boundaries = { ->    boundaries[0] < 1
    \                               || boundaries[1] > line('$')
    \                               || boundaries[0] > boundaries[1]
    \                          }

    if l:Invalid_boundaries()
        return
    endif

    "  ┌─ we operate on the object with `c`
    "  │            ┌─ OR the object doesn't end at the very end of the buffer
    "  │            │
    if a:op_is_c || boundaries[1] !=# line('$')
        " make sure there's no empty lines at the BEGINNING of the object
        " by incrementing the upper boundary as long as necessary
        while getline(boundaries[0]) !~ '\S'
            let boundaries[0] += 1
        endwhile
    endif

    if a:op_is_c
        " make sure there's no empty lines at the END of the object
        while getline(boundaries[1]) !~ '\S'
            let boundaries[1] -= 1
        endwhile
    endif

    if l:Invalid_boundaries()
        return
    endif

    " position the cursor on the 1st line of the object
    exe 'norm! '.boundaries[0].'G'

    " select the object
    exe 'norm! V'.boundaries[1].'G'

    unlet! s:l s:r
endfu

fu! comment#search(kind, is_fwd, ...) abort "{{{1
    " This function positions the cursor on the next/previous beginning
    " of a comment (kind = 'text' or 'code').

    " Inspiration:
    " $VIMRUNTIME/ftplugin/vim.vim

    if empty(&l:cms)
        return ''
    endif

    let mode = mode(1)

    let seq = ''
    if mode is# 'n'
        let seq .= "m'"
    endif

    let pat = s:get_search_pat(a:kind)

    " Why `1|`?{{{
    "
    " Necessary when:
    "
    "       - we look for a pattern, like the previous beginning of a comment section
    "       - the current line matches
    "       - we want to ignore this match
    "
    " `norm! 1|` + no `c` flag in search() = no match  ✔
    "}}}
    " Why not in operator-pending mode?{{{
    "
    " This function is going to return something like:
    "
    "     1|123G
    "
    " For Vim, `1|` will be the object, and `123G` just a simple motion.
    " That's not what we want.
    "}}}
    let seq .= index(['n', 'v', 'V', "\<c-v>"], mode) >= 0
           \ ?     '1|'
           \ :     ''

    let new_address = search(pat, (a:is_fwd ? '' : 'b').'nW')
    if new_address !=# 0
        let seq .= new_address.'G'
    else
        return ''
    endif

    if mode is# 'n'
        let seq .= 'zMzv'
    elseif index(['v', 'V', "\<c-v>"], mode) >= 0
        " don't close fold in visual mode,
        " it makes Vim select whole folds instead of some part of them
        let seq .= 'zv'
    endif

    return seq
endfu

fu! comment#toggle(type, ...) abort "{{{1
    if empty(&l:cms)
        return
    endif

    " Define the range of lines to (un)comment.

    if a:type is# 'Ex'
        let [lnum1, lnum2] = [a:1, a:2]
    elseif a:type is# 'visual'
        let [lnum1, lnum2] = [line("'<"), line("'>")]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    " get original comment leader
    " (no space added for better readability; no `@` for code)
    let [s:l, s:r] = split(&l:cms, '%s', 1)

    "    ┌─ comment leader (modified: add padding space, and `@` for code)
    "    │   ┌─ end-comment leader ('' if there's none)
    "    │   │
    let [l_, r_] = s:get_cml()

    " Decide what to do:   comment or uncomment?
    " The decision will be stored in the variable `uncomment`:
    "
    "         - 0 = the operator will comment    the range of lines
    "         - 2 = "                 uncomment  "

    "               ┌─ Why 2 instead of 1?
    "               │  Nested comments use numbers to denote the level of imbrication.
    "               │  2 is a convenient value to compute an (in|de)cremented level:
    "               │
    "               │             old_lvl - uncomment + 1
    "               │                       │
    "               │                       └─ should be 2 or 0
    let uncomment = 2
    for lnum in range(lnum1, lnum2)
        let line = getline(lnum)
        " If needed for the current line, trim the comment leader.
        let [l, r] = s:maybe_trim_cml(line, l_, r_)

        " To comment a range of lines, one of them must be:
        "
        "         - not empty
        "         - not commented
        "         - relevant
        "
        " What is an irrelevant line?
        " A commented line of text, when we operate on code. (1)
        " Or a commented line of code, when we operate on text. (2)
        "
        " (1) Such a line is indeed NOT commented (because no `@` in the cml).
        " But if we operate on code, we don't care. So we need to ignore it.
        "
        " (2) Such a line should also be ignored, but is NOT a problem.
        " Why? Because the previous condition has checked that the line is not
        " commented. So:
        "
        "         we operate on text
        "       + the line is not commented    ⇒    the line can't be
        "                                           a commented line of code
        "
        " IOW: if you aren't a commented line of text, you can't be
        " a commented line of code.

        if  line =~ '\S'
      \ && !s:is_commented(line, l, r)
      \ &&  s:is_relevant(line)
            let uncomment = 0
        endif
    endfor

    " Get the indent of first line.
    " Why?
    "
    " When we comment, if we simply add the left part of the comment string
    " right before the first non whitespace of each line, and the latter have
    " different levels of indentation, the comment characters won't be aligned.
    "
    " We want all of them to be aligned under the first one.
    " To do this, we need to know the level of indentation of the first line.
    let indent = matchstr(getline(lnum1), '^\s*')

    for lnum in range(lnum1,lnum2)
        let line = getline(lnum)

        " Don't do anything if the line is:
        "
        "         - empty
        "         - irrelevant

        if  line !~ '\S' || !s:is_relevant(line)
            continue
        endif

        let [l, r] = s:maybe_trim_cml(line, l_, r_)

        " Add support for nested comments.
        " Example: In an html file:
        "
        "     <!-- hello world -->                          comment
        "     <!-- <1!-- hello world --1> -->               comment in a comment
        "     <!-- <1!-- <2!-- hello world --2> --1> -->    comment in a comment in a comment

        "            ┌─ the end-comment leader should have at least 2 characters:
        "            │          -->
        "            │  … otherwise the incrementation/decrementation could affect
        "            │  numbers inside the comment text, which are not concerned:
        "            │          r = 'x'
        "            │          right_number = r[:-2].'\zs\d\+\ze'.r[-1:-1]
        "            │                       = '\zs\d\+\zex'
        if strlen(r) >= 2 && l.r !~ '\\'
        "                            │
        "                            └─ No matter the magicness of a pattern, a backslash
        "                               has always a special meaning. So, we make sure
        "                               that there's none in the comment leader.

            let left_number  = l[0].'\zs\d\*\ze'.l[1:]
            let right_number = r[:-2].'\zs\d\*\ze'.r[-1:-1]
            let pat          = '\V'.left_number.'\|'.right_number
            let l:Rep        = {m -> m[0]-uncomment+1 <= 0 ? '' : m[0]-uncomment+1}
            let line         = substitute(line, pat, l:Rep, 'g')
        endif

        if uncomment
            let pat   = '\S.*\s\@1<!'
            let l:Rep = {m -> m[0][strlen(l) : -1 - strlen(r)]}
        else
            let pat   = '\v^%('.indent.'|\s*)\zs.*'
            let l:Rep = {m -> l.m[0].r}
        endif

        let line = substitute(line, pat, l:Rep, '')
        call setline(lnum, line)
    endfor

    " We execute all the autocmds using the event `User` and the filter
    " `CommentTogglePost`.
    " It allows us to execute a callback after (un)commenting some text, by
    " installing an autocmd outside this function, using the same event and
    " filter. Example:
    "
    "         augroup my_comment_toggle
    "             au!
    "             au User CommentTogglePost `do some stuff`
    "         augroup END

    if exists('#User#CommentTogglePost')
        doautocmd <nomodeline> User CommentTogglePost
        " By default, when an autocmd is executed, the modelines in the current
        " buffer are processed (if &modelines !=# 0).
        " Indeed, the modelines must be able to overrule the settings changed by
        " autocmds. For example, when we edit a file, the settings set by
        " modelines must be able to overrule the ones set by the autocmds
        " watching the BufRead event.
        "
        " But here, we probably don't want the modelines to change anything.
        " So we add the <nomodeline> argument to prevent the modelines in the
        " current buffer to be processed. From :h :do:
        "
        "         You probably want to use <nomodeline> for events that are not
        "         used when loading a buffer, such as |User|.
    endif

    " don't unlet `s:operate_on`:  it would break the dot command
    unlet! s:l s:r
endfu

fu! comment#what(this) abort "{{{1
    let s:operate_on = a:this
endfu
