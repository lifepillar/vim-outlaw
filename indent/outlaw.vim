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

let g:shifts = []

fun! s:push(linenr, shift)
  call add(g:shifts, [a:linenr, a:shift])
endf

fun! s:pop()
  return remove(g:shifts, -1)
endf

fun! s:top()
  return get(g:shifts, -1, 0)
endf

fun! OutlawIndent()
  if v:lnum == 1
    return 0
  endif

  if getline(v:lnum) =~# '\m^\s*'.b:outlaw_topic_mark
    while !empty(g:shifts)
      call cursor(s:top()[0],1)
      if s:top()[1] < indent(v:lnum)
        let curr_indent = indent(s:top()[0]) + shiftwidth()
        call s:push(v:lnum, indent(v:lnum))
        return curr_indent
      endif
      call s:pop()
    endwhile

    let l:prev = max([1, search('^\s*'.b:outlaw_topic_mark, 'bnWz')])
    let l:offset = indent(v:lnum) - indent(l:prev)
    if l:offset > shiftwidth()
      let curr_indent = indent(l:prev) + shiftwidth()
      call s:push(v:lnum, indent(v:lnum))
      return curr_indent
    endif
  endif
  return -1
endf

let &cpo = s:keepcpo
unlet s:keepcpo

" vim:sw=2:fdm=marker
