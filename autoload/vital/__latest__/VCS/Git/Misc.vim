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
  let opts = get(a:000, 0, {})
  let result = s:Core.exec(['status', '--porcelain'], opts)
  if result.status != 0
    return {}
  endif
  return s:StatusParser.parse(result.stdout)
endfunction " }}}
function! s:get_parsed_config(...) " {{{
  let opts = extend({ 'scope': '' }, get(a:000, 0, {}))
  if opts.scope ==# ''
    let result = s:Core.exec(['config', '-l'], opts)
  elseif opts.scope == 'local'
    let result = s:Core.exec(['config', '-l', '--local'], opts)
  elseif opts.scope == 'global'
    let result = s:Core.exec(['config', '-l', '--global'], opts)
  elseif opts.scope == 'system'
    let result = s:Core.exec(['config', '-l', '--system'], opts)
  else
    throw printf('VCS.Git.Misc: unknown scope "%s" is specified.', opts.scope)
  endif
  if result.status != 0
    return {}
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttabb et ai textwidth=0 fdm=marker
