"******************************************************************************
" Git status (--short) parser
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
"
" (C) 2015, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

" Vital ======================================================================
let s:const = {}
" status symbols
" ref: http://git-scm.com/docs/git-status
let s:const.symbols = {
      \ ' ': 'unmodified',
      \ 'M': 'modified',
      \ 'A': 'added',
      \ 'D': 'deleted',
      \ 'R': 'renamed',
      \ 'C': 'copied',
      \ 'U': 'updated but unmerged',
      \ '?': 'untracked',
      \ '!': 'ignored',
      \}
" a regex which much the following expressions
"   XY PATH
"   XY "P A T H"
"   XY PATH1 -> PATH2
"   XY "P A T H 1" -> "P A T H 2"
" ref: http://git-scm.com/docs/git-status
let s:const.status_pattern = '\v^(.)(.)\s("[^"]+"|[^ ]+)%(\s-\>\s("[^"]+"|[^ ]+)|)$'

function! s:_vital_loaded(V) dict abort
  " define constant variables
  call extend(self, s:const)
endfunction


function! s:parse_record(line, ...) abort
  let opts = extend({
        \ 'translate_symbol': 0,
        \}, get(a:000, 0, {}))
  let m = matchlist(a:line, s:const.status_pattern)
  let result = {}
  if len(m) > 5 && m[4] !=# ''
    " 'XY PATH1 -> PATH2' pattern
    let result.index = m[1]
    let result.worktree = m[2]
    let result.path = m[3]
    let result.path2 = m[4]
    let result.record = a:line
  elseif len(m) > 4 && m[3] !=# ''
    " 'XY PATH' pattern
    let result.index = m[1]
    let result.worktree = m[2]
    let result.path = m[3]
    let result.record = a:line
  else
    throw 'vital: VCS.Git.StatusParser: Parsing a record failed: ' . a:line
  endif
  " translate symbol
  if opts.translate_symbol
    let result.index = get(s:const.symbols, result.index, result.index)
    let result.worktree = get(s:const.symbols, result.worktree, result.worktree)
  endif
  return result
endfunction

function! s:parse(status, ...) abort
  let opts = extend({
        \ 'translate_symbol': 0,
        \}, get(a:000, 0, {}))
  let obj = {}
  for line in split(a:status, '\v%(\r?\n)+')
    let result = s:parse_record(line, opts)
    let obj[result.path] = result
  endfor
  return obj
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
