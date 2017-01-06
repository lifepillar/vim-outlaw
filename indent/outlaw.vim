" Author: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

let b:undo_indent = "setl indentexpr< indentkeys<"

setlocal indentexpr=OutlawIndent()
setlocal indentkeys=

if exists("*OutlawIndent")
  finish
endif

let s:keepcpo= &cpo
set cpo&vim

fun! OutlawIndent()
  " Here we exploit the fact that the fold level is not updated
  " immediately when computing the new indentation, so foldlevel()
  " allows us to infer the original indentation of a previous line.
  if OutlawIsTopicLine(v:lnum)
    " Search for the first topic with a fold level (not indentation!) less
    " than the fold level of the current topic (if any).
    let l:prev = OutlawTopicJump('bWz')
    while l:prev > 1 && foldlevel(l:prev) >= foldlevel(v:lnum)
      let l:prev = OutlawTopicJump('bWz')
    endwhile
    return foldlevel(l:prev) ==# 0
          \ ? 0
          \ : (foldlevel(l:prev) < foldlevel(v:lnum) ? indent(l:prev) + shiftwidth() : -1)
  endif
  return -1
endf

let &cpo = s:keepcpo
unlet s:keepcpo
