" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:undo_ftplugin = "setlocal foldexpr< foldlevel< foldmethod< foldtext<"
      \ . "| unlet b:outlaw_folded_text b:outlaw_header_mark"

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= "|" . s:undo_ftplugin
else
  let b:undo_ftplugin = s:undo_ftplugin
endif

if !exists('b:outlaw_header_mark')
  let b:outlaw_header_mark = get(g:, 'outlaw_header_mark', '\(===\|\[x\]\|\[ \]\|\[-\]\)')
endif

if !exists('b:outlaw_folded_text')
  let b:outlaw_folded_text = get(g:, 'outlaw_folded_text', '[…]')
endif

fun! OutlawIsTopic(linenr) " True if linenr is a topic line, false if it is body text
  return getline(a:linenr) =~# '\m^\s*' . b:outlaw_header_mark
endf

fun! OutlawFold()
  return OutlawIsTopic(v:lnum) ? '>' . (1 + indent(v:lnum) / &l:shiftwidth) : (getline(v:lnum) =~# '\v^\s*$' ? '=' : 20)
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold()
setlocal foldtext=OutlawIsTopic(v:foldstart)?substitute(getline(v:foldstart),'\\t',repeat('\ ',&l:shiftwidth),'g'):b:outlaw_folded_text
setlocal foldlevel=19 " Full display with collapsed notes by default

fun! s:topic_search(flags) " Search for a topic line from the cursor's position
  return search('^\s*'.b:outlaw_header_mark, a:flags)
endf

fun! OutlawTopicLine() " Return the line number where the current topic starts
  return s:topic_search('bcnW')
endf

fun! OutlawLevel() " Return the level of the current topic (top level is level 0)
  return foldlevel(OutlawTopicLine()) - 1
endf

fun! OutlawTopicPrefix() " Return the prefix text of the current topic.
  return matchstr(getline(OutlawTopicLine()), '^\s*'.b:outlaw_header_mark.'\s*')
endf

fun! s:tab()
  return &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
endf

fun! s:outlaw_up(dir)
  return search('^\('.s:tab().'\)\{,'.max([0,OutlawLevel()-1]).'}'.b:outlaw_header_mark, a:dir.'sWz')
endf

fun! s:outlaw_br(linenr, dir)
  return search('^'.repeat(s:tab(),OutlawLevel()).b:outlaw_header_mark, a:dir.'Wz')
endf

fun! s:outlaw_add_brother(linenr)
  call feedkeys("zco\<c-o>d0".OutlawTopicPrefix(a:linenr))
endf

nnoremap <silent> <plug>OutlawPrevTopic   :<c-u>call <sid>topic_search('bsWz')<cr>^zv
nnoremap <silent> <plug>OutlawNextTopic   :<c-u>call <sid>topic_search('sWz')<cr>^zv
nnoremap <silent> <plug>OutlawParent      :<c-u>call <sid>outlaw_up('b')<cr>^zv
nnoremap <silent> <plug>OutlawUncle       :<c-u>call <sid>outlaw_up('')<cr>^zv
nnoremap <silent> <plug>OutlawPrevBrother :<c-u>call <sid>outlaw_br('.', 'b')<cr>^zv
nnoremap <silent> <plug>OutlawNextBrother :<c-u>call <sid>outlaw_br('.',  '')<cr>^zv
nnoremap <silent> <plug>OutlawAddBrother  :<c-u>call <sid>outlaw_add_brother('.')<cr>

" if !hasmapto('<plug>OutlawNext')
  nmap <buffer> <up>       <plug>OutlawPrevTopic
  nmap <buffer> <down>     <plug>OutlawNextTopic
  nmap <buffer> <leader>p  <plug>OutlawParent
  nmap <buffer> <leader>n  <plug>OutlawUncle
  nmap <buffer> <left>     <plug>OutlawPrevBrother
  nmap <buffer> <right>    <plug>OutlawNextBrother
  nmap <buffer> <c-a>      <plug>OutlawAddBrother
" endif

