" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=OutlawIndent()
setlocal indentkeys=

let b:undo_indent = "setl indentexpr< indentkeys<"

if exists("*OutlawIndent")
  finish
endif

let s:keepcpo= &cpo
set cpo&vim

fun! OutlawIndent()
  " Here we exploit the fact that the fold level is not updated
  " immediately when computing the new indentation, so foldlevel()
  " allows us to infer the original indentation of a previous line.
  if getline(v:lnum) =~# '\m^\s*'.b:outlaw_topic_mark
    " Search for the first topic with a fold level less than the
    " fold level of the current topic (if any)
    let l:prev = v:lnum
    while l:prev > 1 && foldlevel(l:prev) >= foldlevel(v:lnum)
      let l:prev = max([1, search('^\s*'.b:outlaw_topic_mark, 'bWz')])
    endwhile
    return foldlevel(l:prev) < foldlevel(v:lnum) ? indent(l:prev) + shiftwidth() : 0
    endif
  endif
  return -1
endf

let &cpo = s:keepcpo
unlet s:keepcpo

" vim:sw=2:fdm=marker
