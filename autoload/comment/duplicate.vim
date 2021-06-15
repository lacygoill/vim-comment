vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import Opfunc from 'lg.vim'
const SID: string = execute('fu Opfunc')->matchstr('\C\<def\s\+\zs<SNR>\d\+_')

def comment#duplicate#main(): string #{{{1
    &operatorfunc = SID .. 'Opfunc'
    g:operatorfunc = {core: Core}
    return 'g@'
enddef

def Core(_)
    # TODO: prevent the function from doing anything if a line is already commented.
    # For example, if you press by accident `+dd` twice on the same line, it
    # shouldn't do anything the second time.
    sil norm! '[y']
    :'[,'] CommentToggle
    exe "sil :'[,']" .. ' s/^\s*'
        .. '\V'
        .. comment#util#getCml()[0]->matchstr('\S*')->escape('\/')
        .. '\m'
        .. '\zs/    /'
    norm! `]]p
enddef

