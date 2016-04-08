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
        \ : (
          \ getline(v:lnum) =~# '\v^\s*$'
          \ ? '='
          \ : 20
          \ )
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold()
setlocal foldtext=getline(v:foldstart)=~#'\\m^\\s*'.b:outlaw_header_mark?substitute(getline(v:foldstart),'\\t',repeat('\ ',&l:shiftwidth),'g'):b:outlaw_folded_text
" Full display with collapsed notes by default:
setlocal foldlevel=19
nnoremap <buffer> <silent> <leader>n :set foldlevel=19<cr>

fun! s:outlaw_prev(linenr)
  return search('^\s*'.b:outlaw_header_mark, 'bsW')
endf

fun! s:outlaw_next(linenr)
  return search('^\s*'.b:outlaw_header_mark, 'sW')
endf

fun! s:outlaw_up(linenr, dir)
  if !OutlawIsTopic(a:linenr)
    let l:l = s:outlaw_prev(a:linenr)
  else
    let l:l = a:linenr
  endif
  let l:ind = foldlevel(l:l) - 2
  if l:ind < 0
    return
  endif
  let l:tab = &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
  return search('^\(' . l:tab . '\)\{,' . l:ind . '}' . b:outlaw_header_mark, a:dir.'sW')
endf

fun! s:outlaw_brother(linenr, dir)
  if !OutlawIsTopic(a:linenr)
    let l:l = s:outlaw_prev(a:linenr)
  else
    let l:l = a:linenr
  endif
  let l:ind = foldlevel(l:l) - 1
  let l:tab = &l:expandtab ? repeat(' ', &l:shiftwidth) : '\t'
  let l:lim = search('^' . repeat(l:tab, l:ind-1) . b:outlaw_header_mark, a:dir.'nW')
  call search('^' . repeat(l:tab, l:ind) . b:outlaw_header_mark, a:dir.'sW', l:lim)
endf

nnoremap <silent> <plug>OutlawPrev :<c-u>call <sid>outlaw_prev('.')<cr>
nnoremap <silent> <plug>OutlawNext :<c-u>call <sid>outlaw_next('.')<cr>
nnoremap <silent> <plug>OutlawParent :<c-u>call <sid>outlaw_up('.', 'b')<cr>
nnoremap <silent> <plug>OutlawUncle :<c-u>call <sid>outlaw_up('.', '')<cr>
nnoremap <silent> <plug>OutlawPrevBrother :<c-u> call <sid>outlaw_brother('.', 'b')<cr>
nnoremap <silent> <plug>OutlawNextBrother :<c-u> call <sid>outlaw_brother('.', '')<cr>

