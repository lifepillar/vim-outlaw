" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:undo_ftplugin = "setlocal autoindent< comments< foldexpr< foldmethod< foldtext< formatoptions< shiftround<"
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

if !exists("b:outlaw_body_text_level")
  let b:outlaw_body_text_level = get(g:, 'outlaw_body_text_level', '=')
endif

fun! OutlawFold(lnum)
  return getline(a:lnum) =~# '\m^\s*'.b:outlaw_topic_mark ? '>'.(1+indent(a:lnum)/&l:shiftwidth) : b:outlaw_body_text_level
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold(v:lnum)
setlocal foldtext=foldlevel(v:foldstart)<20?substitute(getline(v:foldstart),'\\t',repeat('\ ',&l:shiftwidth),'g'):b:outlaw_folded_text
setlocal autoindent
setlocal comments=fb:*,fb:- " Lists
setlocal formatoptions=tcroqnlj1
setlocal shiftround

fun! s:tab()
  return &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
endf

fun! s:topic_search(flags) " Search for a topic line from the cursor's position
  return search('^\s*'.b:outlaw_topic_mark, a:flags)
endf

fun! OutlawTopicStart() " Return the line number where the current topic starts
  return s:topic_search('bcnW')
endf

fun! OutlawLevel() " Return the level of the current topic (top level is level 0)
  return foldlevel(OutlawTopicStart()) - 1
endf

fun! OutlawTopicEnd() " Return the line number of the last line of the current topic
  let l:line = search('^\('.s:tab().'\)\{,'.max([0,OutlawLevel()]).'}'.b:outlaw_topic_mark, 'nW') - 1
  return l:line < 0 ? line('$') : l:line
endf

fun! s:outlaw_up(dir) " Search for a topic at least one level up, in the given direction
  return search('^\('.s:tab().'\)\{,'.max([0,OutlawLevel()-1]).'}'.b:outlaw_topic_mark, a:dir.'esW')
endf

fun! s:outlaw_br(dir) " Search for a topic at the same level, in the given direction
  return search('^'.repeat(s:tab(),OutlawLevel()).b:outlaw_topic_mark, a:dir.'esW')
endf

fun! s:outlaw_add_sibling(dir)
  call s:close_fold()
  if foldclosed('.') > -1
    call cursor(foldclosed('.'), 1)
  endif
  let l:line = a:dir ? OutlawTopicEnd() : max([OutlawTopicStart() - 1, 0])
  call append(l:line, matchstr(getline(OutlawTopicStart()), '^\s*'.substitute(b:outlaw_topic_mark,'\\ze','','g').'\s*'))
  call cursor(l:line + 1, 9999)
  call feedkeys('a','it')
endf

fun! s:close_fold()
  if get(b:, 'outlaw_auto_close', get(g:, 'outlaw_auto_close', 1))
    foldclose
  endif
endf

fun! s:outlaw_toggle_auto_close()
  let b:outlaw_auto_close = 1 - get(b:, 'outlaw_auto_close', get(g:, 'outlaw_auto_close', 1))
  echomsg '[Outlaw] Auto close' (b:outlaw_auto_close ? 'on' : 'off')
endf

nnoremap <script> <silent> <plug>OutlawThisFoldLevel :<c-u>let &l:fdl=OutlawLevel()<cr>
nnoremap <script> <silent> <plug>OutlawBodyTextMode  :<c-u>let b:outlaw_body_text_level=b:outlaw_body_text_level==20?'=':20<cr>zx
nnoremap <script> <silent> <plug>OutlawPrevTopic     :<c-u>call <sid>close_fold()<cr>:call <sid>topic_search('besW')<cr>zv
nnoremap <script> <silent> <plug>OutlawNextTopic     :<c-u>call <sid>close_fold()<cr>:call <sid>topic_search('esW')<cr>zv
nnoremap <script> <silent> <plug>OutlawPrevSibling   :<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_br('b')<cr>zv
nnoremap <script> <silent> <plug>OutlawNextSibling   :<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_br('')<cr>zv
nnoremap <script> <silent> <plug>OutlawParent        :<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_up('b')<cr>zv
nnoremap <script> <silent> <plug>OutlawUncle         :<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_up('')<cr>zv
nnoremap <script> <silent> <plug>OutlawAddSiblingBelow    :<c-u>call <sid>outlaw_add_sibling(1)<cr>
nnoremap <script> <silent> <plug>OutlawAddSiblingAbove    :<c-u>call <sid>outlaw_add_sibling(0)<cr>
nnoremap <script> <silent> <plug>OutlawToggleAutoClose    :<c-u>call <sid>outlaw_toggle_auto_close()<cr>

if !hasmapto('<plug>OutlawToggleAutoClose', 'n')
  nmap <buffer> gA <plug>OutlawToggleAutoClose
endif
if !hasmapto('<plug>OutlawThisFoldLevel', 'n')
  nmap <buffer> gl <plug>OutlawThisFoldLevel
endif
if !hasmapto('<plug>OutlawBodyTextMode', 'n')
  nmap <buffer> gy <plug>OutlawBodyTextMode
endif
if !hasmapto('<plug>OutlawPrevTopic', 'n')
  nmap <buffer> <up> <plug>OutlawPrevTopic
endif
if !hasmapto('<plug>OutlawNextTopic', 'n')
  nmap <buffer> <down> <plug>OutlawNextTopic
endif
if !hasmapto('<plug>OutlawPrevSibling', 'n')
  nmap <buffer> <left> <plug>OutlawPrevSibling
endif
if !hasmapto('<plug>OutlawNextSibling', 'n')
  nmap <buffer> <right> <plug>OutlawNextSibling
endif
if !hasmapto('<plug>OutlawParent', 'n')
  nmap <buffer> - <plug>OutlawParent
endif
if !hasmapto('<plug>OutlawUncle', 'n')
  nmap <buffer> + <plug>OutlawUncle
endif
if !hasmapto('<plug>OutlawAddSiblingBelow', 'n')
  nmap <buffer> <cr> <plug>OutlawAddSiblingBelow
endif
if !hasmapto('<plug>OutlawAddSiblingAbove', 'n')
  nmap <buffer> <c-j> <plug>OutlawAddSiblingAbove
endif
