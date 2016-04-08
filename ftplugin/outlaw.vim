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

fun! OutlawIsTopic(linenr)
  return getline(a:linenr) =~# '\m^\s*' . b:outlaw_header_mark
endf

fun! OutlawFold()
  return OutlawIsTopic(v:lnum)
        \ ? (
          \ OutlawIsTopic(v:lnum + 1) && indent(v:lnum + 1) < indent(v:lnum)
          \ ? indent(v:lnum) / &l:shiftwidth
          \ : '>' . (1 + indent(v:lnum) / &l:shiftwidth)
        \ )
        \ : (getline(v:lnum) =~# '\v^\s*$' ? '=' : 20)
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold()
setlocal foldtext=OutlawIsTopic(v:foldstart)?substitute(getline(v:foldstart),'\\t',repeat('\ ',&l:shiftwidth),'g'):b:outlaw_folded_text
setlocal foldlevel=19 " Full display with collapsed notes by default

fun! s:tab()
  return &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
endf

fun! s:outlaw_pn(linenr, dir)
  return search('^\s*'.b:outlaw_header_mark, a:dir.'sWz')
endf

fun! s:outlaw_up(linenr, dir)
  let [l:indent,l:mark] = (OutlawIsTopic(a:linenr) ? [foldlevel(a:linenr)-2,'s'] : [foldlevel(s:outlaw_pn(a:linenr,'b'))-2,''])
  if l:indent < 0 | return 0 | endif
  return search('^\('.s:tab().'\)\{,'.l:indent.'}'.b:outlaw_header_mark, a:dir.l:mark.'W')
endf

fun! s:outlaw_br(linenr, dir)
  let [l:indent,l:mark] = (OutlawIsTopic(a:linenr) ? [foldlevel(a:linenr)-1,'s'] : [foldlevel(s:outlaw_pn(a:linenr,'b'))-1,''])
  return search('^'.repeat(s:tab(),l:indent).b:outlaw_header_mark, a:dir.l:mark.'Wz', search('^'.repeat(s:tab(),l:indent-1).b:outlaw_header_mark, a:dir.'nWz'))
endf

nnoremap <silent> <plug>OutlawPrevTopic   :<c-u>call <sid>outlaw_pn('.', 'b')<cr>^zv
nnoremap <silent> <plug>OutlawNextTopic   :<c-u>call <sid>outlaw_pn('.',  '')<cr>^zv
nnoremap <silent> <plug>OutlawParent      :<c-u>call <sid>outlaw_up('.', 'b')<cr>^zv
nnoremap <silent> <plug>OutlawUncle       :<c-u>call <sid>outlaw_up('.',  '')<cr>^zv
nnoremap <silent> <plug>OutlawPrevBrother :<c-u>call <sid>outlaw_br('.', 'b')<cr>^zv
nnoremap <silent> <plug>OutlawNextBrother :<c-u>call <sid>outlaw_br('.',  '')<cr>^zv

