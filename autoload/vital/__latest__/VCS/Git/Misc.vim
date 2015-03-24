"******************************************************************************
" Git misc
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:Prelude      = a:V.import('Prelude')
  let s:Core         = a:V.import('VCS.Git.Core')
  let s:StatusParser = a:V.import('VCS.Git.StatusParser')
  let s:ConfigParser = a:V.import('VCS.Git.ConfigParser')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'VCS.Git.Core',
        \ 'VCS.Git.StatusParser',
        \ 'VCS.Git.ConfigParser',
        \]
endfunction " }}}
function! s:_opts2args(opts, defaults) abort " {{{
  let args = []
  for [key, default] in items(a:defaults)
    if has_key(a:opts, key)
      let val = get(a:opts, key)
      if s:Prelude.is_number(default) && val
        call add(args, printf('--%s', substitute(key, '_', '-', 'g')))
      elseif s:Prelude.is_string(default) && strlen(val) && val !=# default
        call add(args, printf('--%s', substitute(key, '_', '-', 'g')))
        call add(args, string(val))
      endif
      unlet val
      unlet default
    endif
  endfor
  return args
endfunction " }}}

function! s:count_commits_ahead_of_remote(...) " {{{
  let opts = get(a:000, 0, {})
  let result = s:Core.exec(['log', '--oneline', '@{upstream}..'], opts)
  return result.status == 0 ? len(split(result.stdout, '\v%(\r?\n)')) : 0
endfunction " }}}
function! s:count_commits_behind_remote(...) " {{{
  let opts = get(a:000, 0, {})
  let result = s:Core.exec(['log', '--oneline', '..@{upstream}'], opts)
  return result.status == 0 ? len(split(result.stdout, '\v%(\r?\n)')) : 0
endfunction " }}}

function! s:get_parsed_status(...) " {{{
  let defs = {
        \ 'branch': 0,
        \ 'untracked_files': 'all',
        \ 'ignored': 0,
        \ 'ignore_submodules': 'all',
        \}
  let opts = extend(defs, get(a:000, 0, {}))
  let args = ['status', '--porcelain'] + s:_opts2args(opts, defs)
  let result = s:Core.exec(args, opts)
  if result.status != 0
    return result
  endif
  return s:StatusParser.parse(result.stdout, { 'fail_silently': 1 })
endfunction " }}}
function! s:get_parsed_commit(...) " {{{
  let defs = {
        \ 'file': '',
        \ 'author': '',
        \ 'date': '',
        \ 'message': '',
        \ 'reedit_message': '',
        \ 'reuse_message': '',
        \ 'fixup': '',
        \ 'squash': '',
        \ 'cleanup': '',
        \ 'gpg_sign': '',
        \ 'untracked_files': 'all',
        \ 'reset_author': 0,
        \ 'signoff': 0,
        \ 'all': 0,
        \ 'amend': 0,
        \ 'no_post_rewrite': 0,
        \}
  let opts = extend(defs, get(a:000, 0, {}))
  let args = ['commit', '--dry-run', '--porcelain'] + s:_opts2args(opts, defs)
  let result = s:Core.exec(args, opts)
  " Note:
  "   I'm not sure but apparently the exit status is 1
  if result.status != 1
    return result
  endif
  return s:StatusParser.parse(result.stdout, { 'fail_silently': 1 })
endfunction " }}}
function! s:get_parsed_config(...) " {{{
  let defs = {
        \ 'local': 0,
        \ 'global': 0,
        \ 'system': 0,
        \ 'file': '',
        \ 'blob': '',
        \ 'bool': 0,
        \ 'int': 0,
        \ 'bool_or_int': 0,
        \ 'path': 0,
        \ 'includes': 0,
        \}
  let opts = extend(defs, get(a:000, 0, {}))
  let args = ['config', '--list'] + s:_opts2args(opts, defs)
  let result = s:Core.exec(args, opts)
  if result.status != 0
    return result
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttabb et ai textwidth=0 fdm=marker
