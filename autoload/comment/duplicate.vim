vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

import Opfunc from 'lg.vim'
const SID: string = execute('fu Opfunc')->matchstr('\C\<def\s\+\zs<SNR>\d\+_')

def comment#duplicate#main(): string #{{{1
    &opfunc = SID .. 'Opfunc'
    g:opfunc = {core: 'comment#duplicate#main_core'}
    return 'g@'
enddef

def comment#duplicate#main_core(_: any)
    # TODO: prevent the function from doing anything if a line is already commented.
    # For example, if you press by accident `+dd` twice on the same line, it
    # shouldn't do anything the second time.
    sil norm! '[y']
    :'[,']CommentToggle
    # comment#toggle#main(line("'["), line("']"))
    sil exe ":'[,']s/^\\s*\\V"
        .. comment#util#getCml()[0]->matchstr('\S*')->escape('\/')
        .. '\m\zs/    /'
    norm! `]]p
enddef

