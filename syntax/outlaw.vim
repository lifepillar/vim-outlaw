" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:current_syntax")
  finish
endif

syntax case match
syntax sync minlines=10 maxlines=100

let s:tab = &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
let s:num = get(b:, 'outlaw_levels', get(g:, 'outlaw_levels',
      \ ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X']))
let s:mark = get(b:, 'outlaw_header_mark', get(g:, 'outlaw_header_mark', '\(===\|\[x\]\|\[ \]\|\[-\]\)'))
let s:hg = get(b:, 'outlaw_highlight_groups', get(g:, 'outlaw_highlight_groups',
      \ ['Statement', 'Identifier', 'Constant', 'PreProc']))

for i in range(0, len(s:num) - 1)
  execute 'syn match OutlawHead'.s:num[i] '/\m^'.repeat(s:tab,i).s:mark.'.*$/'
  execute 'hi def link OutlawHead'.s:num[i] s:hg[i % len(s:hg)]
endfor

let b:current_syntax = "outlaw"

