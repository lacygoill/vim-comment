fu comment#object#main(op_is_c) abort "{{{1
    let [l_, _r] = comment#util#get_cml()
    let boundaries = [line('.') + 1, line('.') - 1]

    "       ┌ 0 or 1:  upper or lower boundary
    "       │
    for  [which, dir, limit, next_line]
  \ in  [[0, -1, 1, getline('.')],
  \ [1, 1, line('$'), getline('.')]]

        let [l , r] = getline('.')->comment#util#maybe_trim_cml(l_, _r)
        while comment#util#is_commented(next_line, l, r)
            " stop if the boundary has reached the beginning/end of a fold
            let fmr = split(&l:fmr, ',')->join('\|')
            if match(next_line, fmr) != -1 | break | endif

            " the test was successful so (inc|dec)rement the boundary
            let boundaries[which] += dir

            " update `line`, `l`, `r` before next test
            let next_line = getline(boundaries[which]+dir)
            let [l, r] = comment#util#maybe_trim_cml(next_line, l_, _r)
        endwhile
    endfor

    let l:Invalid_boundaries = {->
        \    boundaries[0] < 1
        \ || boundaries[1] > line('$')
        \ || boundaries[0] > boundaries[1]
        \ }

    if l:Invalid_boundaries() | return | endif

    "  ┌ we operate on the object with `c`
    "  │            ┌ OR the object doesn't end at the very end of the buffer
    "  │            │
    if a:op_is_c || boundaries[1] != line('$')
        " make sure there's no empty lines at the *start* of the object
        " by incrementing the upper boundary as long as necessary
        while getline(boundaries[0]) !~ '\S'
            let boundaries[0] += 1
        endwhile
    endif

    if a:op_is_c
        " make sure there are no empty lines at the *end* of the object
        while getline(boundaries[1]) !~ '\S'
            let boundaries[1] -= 1
        endwhile
    endif

    if l:Invalid_boundaries() | return | endif

    " position the cursor on the 1st line of the object
    exe 'norm! ' .. boundaries[0] .. 'G'

    " select the object
    exe 'norm! V' .. boundaries[1] .. 'G'
endfu

