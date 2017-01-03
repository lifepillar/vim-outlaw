" Author:       Lifepillar
" Maintainer:   Lifepillar
" License:      This file is placed in the public domain.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

                  \ . "| unlet b:outlaw_folded_text b:outlaw_topic_mark"
let s:undo_ftplugin = "setlocal autoindent< comments< foldexpr< foldmethod< foldtext< formatoptions< preserveindent< shiftround<"

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
  return getline(a:lnum) =~# '\m^\s*'.b:outlaw_topic_mark ? '>'.(1+indent(a:lnum)/shiftwidth()) : b:outlaw_body_text_level
endf

setlocal foldmethod=expr
setlocal foldexpr=OutlawFold(v:lnum)
setlocal foldtext=foldlevel(v:foldstart)<20?substitute(getline(v:foldstart),'\\t',repeat('\ ',shiftwidth()),'g'):b:outlaw_folded_text
setlocal autoindent
setlocal comments=fb:*,fb:- " Lists
setlocal formatoptions=tcroqnlj1
setlocal nopreserveindent
setlocal shiftround

fun! s:tab()
  return &l:expandtab ? repeat(' ', shiftwidth()) : '\t'
endf

fun! s:topic_search(flags) " Search for a topic line from the cursor's position
  return search('^\s*'.b:outlaw_topic_mark, a:flags)
endf

fun! OutlawTopicStart() " Return the line number where the current topic starts
  return s:topic_search('bcnW')
endf

fun! OutlawNextTopic() " Return the line number where the next (sub)topic starts
  return s:topic_search('nW')
endf

fun! OutlawLevel() " Return the level of the current topic (top level is level 0)
  return foldlevel(OutlawTopicStart()) - 1
endf

fun! OutlawTopicTreeEnd() " Return the line number of the last line of the current subtree
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
  let l:line = a:dir ? OutlawTopicTreeEnd() : max([OutlawTopicStart() - 1, 0])
  call append(l:line, matchstr(getline(OutlawTopicStart()), '^\s*'.substitute(b:outlaw_topic_mark,'\\ze','','g').'\s*'))
  call cursor(l:line + 1, 1)
  call feedkeys('A', 'it')
endf

fun! s:close_fold()
  if get(b:, 'outlaw_auto_close', get(g:, 'outlaw_auto_close', 1)) && foldclosed('.') == -1
    foldclose
  endif
endf

fun! s:outlaw_toggle_auto_close()
  let b:outlaw_auto_close = 1 - get(b:, 'outlaw_auto_close', get(g:, 'outlaw_auto_close', 1))
  echomsg '[Outlaw] Auto close' (b:outlaw_auto_close ? 'on' : 'off')
endf

fun! s:outlaw_move_down() range
  call cursor(line("'>") + 1, 1)
  let l:target = OutlawNextTopic() - 1
  execute a:firstline.','.a:lastline.'move' (l:target > 0 ? l:target : line('$')).'<cr>'
endf

fun! s:outlaw_move_up() range
  call cursor(line("'<") - 1, 1)
  let l:target = OutlawTopicStart() - 1
  execute a:firstline.','.a:lastline.'move' (l:target < 0 ? 0 : l:target).'<cr>'
endf

fun! s:align_note() " Align the note at the cursor's position
  let l:start = OutlawTopicStart() + 1
  if indent(l:start) == 0 | return | endif " Do not touch flush-left notes
  let l:end = OutlawNextTopic() - 1
  if l:end < l:start | return | endif
  let l:shift = (indent(l:start - 1) + shiftwidth() - indent(l:start)) / shiftwidth()
  if l:shift == 0 | return | endif
  exe l:start.','.l:end.repeat(l:shift > 0 ? '>' : '<', abs(l:shift))
endf

fun! s:align_all_notes()
  let l:view = winsaveview()
  call cursor(1,1)
  while s:topic_search('W') " Advance to next topic
    call s:align_note()
  endwhile
  call winrestview(l:view)
endf

command! -bar -nargs=0 OutlawAlignNotes :call <sid>align_all_notes()

if !get(g:, 'outlaw_no_mappings', 0)
  fun! s:map(mode, name, lhs, rhs)
    exe a:mode.'noremap <sid>('.a:name.')' a:rhs
    exe a:mode.'noremap <script> <plug>(Outlaw'.a:name.') <sid>('.a:name.')'
    if !hasmapto('<plug>(Outlaw'.a:name.')', a:mode)
      exe a:mode.'map' a:lhs '<plug>(Outlaw'.a:name.')'
    endif
  endf

  call s:map('n', 'ThisFoldLevel',   'gl',      ":<c-u>let &l:fdl=OutlawLevel()<cr>")
  call s:map('n', 'BodyTextMode',    'gy',      ":<c-u>let b:outlaw_body_text_level=b:outlaw_body_text_level==20?'=':20<cr>zx")
  call s:map('n', 'PrevTopic',       '<up>',    ":<c-u>call <sid>close_fold()<cr>:call <sid>topic_search('besW')<cr>zv")
  call s:map('n', 'NextTopic',       '<down>',  ":<c-u>call <sid>close_fold()<cr>:call <sid>topic_search('esW')<cr>zv")
  call s:map('n', 'PrevSibling',     '<left>',  ":<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_br('b')<cr>zv")
  call s:map('n', 'NextSibling',     '<right>', ":<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_br('')<cr>zv")
  call s:map('v', 'MoveUp',          '<up>',    ":call <sid>outlaw_move_up()<cr>gv=:call <sid>align_note()<cr>gv")
  call s:map('v', 'MoveDown',        '<down>',  ":call <sid>outlaw_move_down()<cr>gv")
  call s:map('n', 'Parent',          '-',       ":<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_up('b')<cr>zv")
  call s:map('n', 'Uncle',           '+',       ":<c-u>call <sid>close_fold()<cr>:call <sid>outlaw_up('')<cr>zv")
  call s:map('n', 'AddSiblingBelow', '<cr>',    ":<c-u>call <sid>outlaw_add_sibling(1)<cr>")
  call s:map('n', 'AddSibglingAbove','<c-k>',   ":<c-u>call <sid>outlaw_add_sibling(0)<cr>")
  call s:map('n', 'AddChild',        '<c-j>',   ":<c-u>call <sid>outlaw_add_sibling(1)<cr><c-t><c-o>zv")
  call s:map('n', 'ToggleAutoClose', 'gA',      ":<c-u>call <sid>outlaw_toggle_auto_close()<cr>")
endif
