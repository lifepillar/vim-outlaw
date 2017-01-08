" Author: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:undo_ftplugin = "setlocal autoindent< comments< foldexpr< foldmethod< foldtext< formatoptions< preserveindent< shiftround<"
                  \ . "| unlet! b:outlaw_auto_close b:outlaw_note_fold_level b:outlaw_fold_prefix b:outlaw_folded_text"
                  \ . "| unlet! b:outlaw_embedded_syntax_tag b:outlaw_note_indent b:outlaw_topic_mark"

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . '|' : '') . s:undo_ftplugin

setlocal autoindent
setlocal comments=fb:*,fb:- " Lists
setlocal foldexpr=OutlawFold(v:lnum)
setlocal foldmethod=expr
setlocal foldtext=OutlawFoldedText()
setlocal formatoptions=tcroqnlj1
setlocal nopreserveindent
setlocal shiftround

let b:outlaw_auto_close      = get(b:, 'outlaw_auto_close',      get(g:, 'outlaw_auto_close',      1                                           ))
let b:outlaw_note_fold_level = get(b:, 'outlaw_note_fold_level', get(g:, 'outlaw_note_fold_level', '='                                         ))
let b:outlaw_fold_prefix     = get(b:, 'outlaw_fold_prefix',     get(g:, 'outlaw_fold_prefix',     '(+)\ '                                     ))
let b:outlaw_folded_text     = get(b:, 'outlaw_folded_text',     get(g:, 'outlaw_folded_text',     '[…]'                                       ))
let b:outlaw_note_indent     = get(b:, 'outlaw_note_indent',     get(g:, 'outlaw_note_indent',     1                                           ))
let b:outlaw_topic_mark      = get(b:, 'outlaw_topic_mark',      get(g:, 'outlaw_topic_mark',      '\%(=== \|\[x\ze\] \|\[ \ze\] \|\[-\ze\] \)'))

" Preflight the user's whitespace preferences
if !&smarttab && &l:softtabstop !=# shiftwidth()
  if &l:softtabstop > 0
    echomsg "[Outlaw] You should set 'softtabstop' to 0 or to the value of 'shiftwidth'."
  elseif &l:softtabstop ==# 0 && &l:tabstop !=# shiftwidth()
    echomsg "[Outlaw] You should set 'shiftwidth' to 0 or to the value of 'tabstop'."
  endif
endif

command! -buffer -bar -nargs=0 OutlawAlignNotes :silent call OutlawAlignAllNotes()

if !get(g:, 'no_outlaw_maps', get(g:, 'no_plugin_maps', 0))
  fun! s:map(mode, name, lhs, rhs)
    execute a:mode.'noremap <buffer> <sid>('.a:name.')' a:rhs
    execute a:mode.'noremap <buffer> <script> <plug>(Outlaw'.a:name.') <sid>('.a:name.')'
    if !hasmapto('<plug>(Outlaw'.a:name.')', a:mode)
      execute a:mode.'map <buffer> <silent>' a:lhs '<plug>(Outlaw'.a:name.')'
    endif
  endf

  call s:map('n', 'ThisFoldLevel',   'gl',      ":<c-u>let &l:fdl=OutlawLevel()<cr>")
  call s:map('n', 'BodyTextMode',    'gy',      ":<c-u>let b:outlaw_note_fold_level=b:outlaw_note_fold_level==20?'=':20<cr>zx")
  call s:map('n', 'PrevTopic',       '<up>',    ":<c-u>call OutlawAutoClose()<cr>:call OutlawTopicJump('besW')<cr>zv")
  call s:map('n', 'NextTopic',       '<down>',  ":<c-u>call OutlawAutoClose()<cr>:call OutlawTopicJump('esW')<cr>zv")
  call s:map('n', 'PrevSibling',     '<left>',  ":<c-u>call OutlawAutoClose()<cr>:call OutlawSibling('b')<cr>zv")
  call s:map('n', 'NextSibling',     '<right>', ":<c-u>call OutlawAutoClose()<cr>:call OutlawSibling('')<cr>zv")
  call s:map('v', 'MoveUp',          '<up>',    ":call OutlawMoveUp(v:count1)<cr>gv=:call OutlawAlignNote()<cr>gv")
  call s:map('v', 'MoveDown',        '<down>',  ":call OutlawMoveDown(v:count1)<cr>gv=:call OutlawAlignNote()<cr>gv")
  call s:map('v', 'MoveLeft',        '<left>',  "<zvgv")
  call s:map('v', 'MoveRight',       '<right>', ">zvgv")
  call s:map('n', 'Parent',          '-',       ":<c-u>call OutlawAutoClose()<cr>:call OutlawUp('b')<cr>zv")
  call s:map('n', 'Uncle',           '+',       ":<c-u>call OutlawAutoClose()<cr>:call OutlawUp('')<cr>zv")
  call s:map('n', 'AddSiblingBelow', '<cr>',    ":<c-u>call OutlawAddSibling(1)<cr>")
  call s:map('n', 'AddSiblingAbove', '<c-k>',   ":<c-u>call OutlawAddSibling(0)<cr>")
  call s:map('n', 'AddChild',        '<c-j>',   ":<c-u>call OutlawAddSibling(1)<cr><c-t><c-o>zv")
  call s:map('n', 'ToggleAutoClose', 'gA',      ":<c-u>call OutlawToggleAutoClose()<cr>")
endif

if exists("*OutlawTopicPattern")
  finish
endif

fun! OutlawTopicPattern()
  return substitute(b:outlaw_topic_mark, '\\ze\|\\zs', '', 'g')
endf

fun! OutlawIsTopicLine(line) " Is the given line a topic line?
  return getline(a:line) =~# '\m^\s*' . b:outlaw_topic_mark
endf

fun! OutlawFold(lnum)
  return OutlawIsTopicLine(a:lnum)
        \ ? '>' . (1 + indent(a:lnum) / shiftwidth())
        \ : b:outlaw_note_fold_level
endf

fun! OutlawFoldedText()
  return foldlevel(v:foldstart) < 20
        \ ? substitute(substitute(getline(v:foldstart), '\\t', repeat('\ ', shiftwidth()), 'g'),
        \                         OutlawTopicPattern(), b:outlaw_fold_prefix, '')
        \ : b:outlaw_folded_text
endf

fun! OutlawTopicJump(flags) " Search for a topic line from the cursor's position
  return search('^\s*' . b:outlaw_topic_mark, a:flags)
endf

fun! OutlawTopicLine() " Return the line number where the current topic starts
  return OutlawTopicJump('bcnW')
endf

fun! OutlawTopicColumn() " Return the column where the current topic starts
  return 1 + indent(OutlawTopicLine())
endf

fun! OutlawNextTopic() " Return the line number where the next (sub)topic starts
  return OutlawTopicJump('nW')
endf

fun! OutlawLevel() " Return the level of the current topic (top level is level 0)
  return foldlevel(OutlawTopicLine()) - 1
endf

fun! OutlawTopicTreeEnd() " Return the line number of the last line of the current subtree
  let l:line = search('\%>' . line('.') . 'l\%<' . (OutlawTopicColumn() + 1) . 'v' . OutlawTopicPattern(), 'nW') - 1
  return l:line < 0 ? line('$') : l:line
endf

fun! OutlawUp(dir) " Search for a topic at least one level up, in the given direction
  return search('\%(^\|\%<' . OutlawTopicColumn() . 'v\)' . b:outlaw_topic_mark, a:dir . 'esW')
endf

fun! OutlawSibling(dir) " Search for a topic at the same level, in the given direction
  return search('\%' . OutlawTopicColumn() . 'v' . b:outlaw_topic_mark, a:dir . 'esW')
endf

fun! OutlawAutoClose()
  if b:outlaw_auto_close && foldclosed('.') == -1 && foldlevel('.') > 0
    foldclose
  endif
endf

fun! OutlawToggleAutoClose()
  let b:outlaw_auto_close = 1 - b:outlaw_auto_close
  echo '[Outlaw] Auto close' (b:outlaw_auto_close ? 'on' : 'off')
endf

fun! OutlawAddSibling(dir)
  call OutlawAutoClose()
  if foldclosed('.') > -1
    call cursor(foldclosed('.'), 1)
  endif
  let l:line = a:dir ? OutlawTopicTreeEnd() : max([OutlawTopicLine() - 1, 0])
  call append(l:line, matchstr(getline(OutlawTopicLine()), '^\s*' . OutlawTopicPattern() . '\s*'))
  call cursor(l:line + 1, 1)
  call feedkeys('A', 'it')
endf

fun! OutlawMoveDown(count) range
  call cursor(line("'>"), 1)
  for i in range(1, a:count)
    call OutlawTopicJump('W')
    if foldclosedend('.') > - 1 " Ended up in a closed fold, skip it
      call cursor(foldclosedend('.'), 1)
    endif
  endfor
  let l:target = line('.')
  if !OutlawIsTopicLine(l:target + 1) " Skip note
    let l:target = OutlawTopicJump('W') - 1
    if l:target < 0 | let l:target = line('$') | endif
  endif
  execute a:firstline.','.a:lastline.'copy' l:target.'<cr>'
  '<,'>delete _
  execute (l:target - (a:lastline - a:firstline)).'mark <'
  execute l:target.'mark >'
endf

fun! OutlawMoveUp(count) range
  call cursor(line("'<"), 1)
  for i in range(1, a:count)
    call OutlawTopicJump('bW')
    if foldclosed('.') > - 1 " Ended up in a closed fold, skip it
      call cursor(foldclosed('.'), 1)
    endif
  endfor
  let l:target = line('.')
  execute a:firstline.','.a:lastline.'copy' (l:target - 1).'<cr>'
  '<,'>delete _
  execute l:target.'mark <'
  execute (l:target + a:lastline - a:firstline).'mark >'
endf

fun! OutlawAlignNote() " Align the note at the cursor's position
  let l:start = OutlawTopicLine() + 1
  if indent(l:start) <= 0 | return | endif " Do not touch flush-left notes
  let l:end = OutlawNextTopic() - 1
  if l:end == -1 | let l:end = line('$') | endif
  if l:end < l:start | return | endif
  let l:shift = (indent(l:start - 1) + b:outlaw_note_indent * shiftwidth() - indent(l:start)) / shiftwidth()
  if l:shift == 0 | return | endif
  execute l:start.','.l:end.repeat(l:shift > 0 ? '>' : '<', abs(l:shift))
endf

fun! OutlawAlignAllNotes()
  let l:view = winsaveview()
  call cursor(1,1)
  while OutlawTopicJump('ceWz') " Advance to next topic
    call OutlawAlignNote()
  endwhile
  call winrestview(l:view)
endf
