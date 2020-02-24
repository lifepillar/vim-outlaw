" Author: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

if exists("b:current_syntax")
  finish
endif

syntax case ignore
syntax sync minlines=10 maxlines=100
syn keyword OutlawKeyword FIXME XXX TODO
syn match OutlawKeyword /\%(NOTE\|SEE\|SEE ALSO\):/ contains=@NoSpell
syn match OutlawLink /\S\+:\/\/\S\+/ contains=@NoSpell
syn match OutlawPath /\%(\s\+\zs\.\=\/\f\+\)\|\%(\f\+\.\%(outl\%(aw\)\=\|txt\)\)\>/ contains=@NoSpell
syn match OutlawCode /^\s*|\zs.*/ contains=@NoSpell
syn region OutlawVerb matchgroup=OutlawVerbDelim start="`" end="`" keepend contains=@NoSpell concealends
syn match OutlawQuote /^\s*>.*/ contains=OutlawLink,OutlawPath,OutlawVerb
syn match OutlawTag /@\%(\k\|\f\)\+\%((.\{-})\)\=/ contains=OutlawTagValue
syn region OutlawTagValue matchgroup=OutlawDelim start="(" end=")" contained
hi def link OutlawKeyword Todo
hi def link OutlawLink Underlined
hi def link OutlawCode CursorLineNr
hi def link OutlawDelim Delimiter
hi def link OutlawVerb Identifier
hi def link OutlawVerbDelim Delimiter
hi def link OutlawPath String
hi def link OutlawQuote Comment
hi def link OutlawTag Tag
hi def link OutlawTagValue Constant

let s:num = get(b:, 'outlaw_levels', get(g:, 'outlaw_levels',
      \ ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X']))
let s:mark = substitute(get(b:, 'outlaw_topic_mark', get(g:, 'outlaw_topic_mark', '\(=== \|\[x\] \|\[ \] \|\[-\] \)')), '\\ze\|\\zs', '', 'g')
let s:hg = get(b:, 'outlaw_highlight_groups', get(g:, 'outlaw_highlight_groups',
      \ ['Statement', 'Identifier', 'Constant', 'PreProc']))
let s:tag = get(b:, 'outlaw_fenced_tag', get(g:, 'outlaw_fenced_tag', '\~\~\~'))

let s:indent = get(g:, 'outlaw_indent', shiftwidth())
for i in range(0, len(s:num) - 1)
  execute 'syn match OutlawHead'.s:num[i] '/\m\%'.(1 + i * s:indent).'v'.s:mark.'.*$/ contains=outlawKeyword,OutlawPath,OutlawLink,OutlawTag,OutlawVerb'
  execute 'hi def link OutlawHead'.s:num[i] s:hg[i % len(s:hg)]
endfor

" Embedded syntaxes
for ft in get(b:, 'outlaw_fenced_filetypes', get(g:, 'outlaw_fenced_filetypes', []))
  execute 'syn include @Outlaw'.ft 'syntax/'.ft.'.vim'
  unlet b:current_syntax
  execute 'syn region Outlaw'.ft 'matchgroup=Conceal start="'.s:tag.ft.'" end="'.s:tag.'" concealends keepend contains=@Outlaw'.ft
endfor

syn match Conceal '^vim: .*' conceal

unlet s:num s:mark s:hg s:indent

let b:current_syntax = "outlaw"
