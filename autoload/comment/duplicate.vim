vim9script noclear

import Opfunc from 'lg.vim'
const SID: string = execute('function Opfunc')->matchstr('\C\<def\s\+\zs<SNR>\d\+_')

def comment#duplicate#main(): string #{{{1
    &operatorfunc = SID .. 'Opfunc'
    g:operatorfunc = {core: Core}
    return 'g@'
enddef

def Core(_)
    # TODO: prevent the function from doing anything if a line is already commented.
    # For example, if you press by accident `+dd` twice on the same line, it
    # shouldn't do anything the second time.
    silent normal! '[y']
    :'[,'] CommentToggle
    execute "silent :'[,']" .. ' substitute/^\s*'
        .. '\V'
        .. comment#util#getCml()[0]->matchstr('\S*')->escape('\/')
        .. '\m'
        .. '\zs/    /'
    normal! `]]p
enddef

