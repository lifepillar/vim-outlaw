" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:undo_ftplugin = "setlocal comments< foldexpr< foldlevel< foldmethod< foldtext<"
                  \ . "| unlet b:outlaw_folded_text b:outlaw_topic_mark"

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= "|" . s:undo_ftplugin
else
  let b:undo_ftplugin = s:undo_ftplugin
endif

if !exists('b:outlaw_topic_mark')
  let b:outlaw_topic_mark = get(g:, 'outlaw_topic_mark', '\(=== \|\[x\ze\] \|\[ \ze\] \|\[-\ze\] \)')
endif

if !exists('b:outlaw_folded_text')
  let b:outlaw_folded_text = get(g:, 'outlaw_folded_text', '[…]')
endif

fun! OutlawFold(lnum)
  return getline(a:lnum) =~# '\m^\s*' . b:outlaw_topic_mark
        \ ? '>' . (1 + indent(a:lnum) / &l:shiftwidth)
        \ : (getline(a:lnum) =~# '\v^\s*$' ? '=' : 20)
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold(v:lnum)
setlocal foldtext=foldlevel(v:foldstart)<20?substitute(getline(v:foldstart),'\\t',repeat('\ ',&l:shiftwidth),'g'):b:outlaw_folded_text
setlocal foldlevel=19 " Full display with collapsed notes by default
setlocal comments=fb:*,fb:- " Lists

fun! s:tab()
  return &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
endf

fun! s:topic_search(flags) " Search for a topic line from the cursor's position
  return search('^\s*'.b:outlaw_topic_mark, a:flags)
endf

fun! OutlawTopicLine() " Return the line number where the current topic starts
  return s:topic_search('bcnW')
endf

fun! OutlawLevel() " Return the level of the current topic (top level is level 0)
  return foldlevel(OutlawTopicLine()) - 1
endf

fun! s:outlaw_up(dir) " Search for a topic at least one level up, in the given direction
  return search('^\('.s:tab().'\)\{,'.max([0,OutlawLevel()-1]).'}'.b:outlaw_topic_mark, a:dir.'esW')
endf

fun! s:outlaw_br(dir) " Search for a topic at the same level, in the given direction
  return search('^'.repeat(s:tab(),OutlawLevel()).b:outlaw_topic_mark, a:dir.'esW')
endf

fun! s:outlaw_add_sibling()
  call feedkeys("zco\<c-o>d0".matchstr(getline(OutlawTopicLine()), '^\s*'.substitute(b:outlaw_topic_mark,'\\ze','','g').'\s*'))
endf

nnoremap <script> <silent> <plug>OutlawPrevTopic   :<c-u>call <sid>topic_search('besW')<cr>zv
nnoremap <script> <silent> <plug>OutlawNextTopic   :<c-u>call <sid>topic_search('esW')<cr>zv
nnoremap <script> <silent> <plug>OutlawPrevSibling :<c-u>call <sid>outlaw_br('b')<cr>zv
nnoremap <script> <silent> <plug>OutlawNextSibling :<c-u>call <sid>outlaw_br('')<cr>zv
nnoremap <script> <silent> <plug>OutlawParent      :<c-u>call <sid>outlaw_up('b')<cr>zv
nnoremap <script> <silent> <plug>OutlawUncle       :<c-u>call <sid>outlaw_up('')<cr>zv
nnoremap <script> <silent> <plug>OutlawAddSibling  :<c-u>call <sid>outlaw_add_sibling()<cr>

if !hasmapto('<plug>OutlawPrevTopic', 'n')
  nmap <buffer> <up> <plug>OutlawPrevTopic
endif
if !hasmapto('<plug>OutlawNextTopic', 'n')
  nmap <buffer> <down> <plug>OutlawNextTopic
endif
if !hasmapto('<plug>OutlawPrevSibling', 'n')
  nmap <buffer> <c-k> <plug>OutlawPrevSibling
endif
if !hasmapto('<plug>OutlawNextSibling', 'n')
  nmap <buffer> <c-j> <plug>OutlawNextSibling
endif
if !hasmapto('<plug>OutlawParent', 'n')
  nmap <buffer> - <plug>OutlawParent
endif
if !hasmapto('<plug>OutlawUncle', 'n')
  nmap <buffer> + <plug>OutlawUncle
endif
if !hasmapto('<plug>OutlawAddSibling', 'n')
  nmap <buffer> <cr> <plug>OutlawAddSibling
endif

