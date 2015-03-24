"******************************************************************************
" A fundemental git manipulation library
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
"
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

" Vital ======================================================================
function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:SimpleCache = s:V.import('System.Cache.Simple')
  let s:Core = s:V.import('VCS.Git.Core')
  let s:Misc = s:V.import('VCS.Git.Misc')
  let s:Finder = s:V.import('VCS.Git.Finder')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'System.Cache.Simple',
        \ 'VCS.Git.Core',
        \ 'VCS.Git.Misc',
        \ 'VCS.Git.Finder',
        \]
endfunction " }}}

" Methods ====================================================================
function! s:new(worktree, repository, ...) " {{{
  let opts = extend({ 'no_cache': 0 }, get(a:000, 0, {}))
  if !exists('s:cache')
    let s:cache = s:SimpleCache.new()
  endif
  let git = s:cache.get(a:worktree, {})
  if !empty(git) && !opts.no_cache
    return git
  endif
  let git = extend(deepcopy(s:git), {
        \ 'worktree': a:worktree,
        \ 'repository': a:repository,
        \ 'cache': s:SimpleCache.new(),
        \})
  call s:cache.set(a:worktree, git)
  return git
endfunction " }}}
function! s:find(path) " {{{
  let found = s:Finder.find(a:path)
  if empty(found)
    return {}
  endif
  return s:new(found.worktree, found.repository)
endfunction " }}}

" Object =====================================================================
let s:git = {}
function! s:git._get_cache(name) abort " {{{
  let uptime = self.get_index_updated_time()
  let cached = self.cache.get(a:name, {})
  if !empty(cached) && (get(cached, 'actime', 0) >= uptime || uptime == -1)
    return cached
  endif
  return {}
endfunction " }}}
function! s:git._set_cache(name, obj) abort " {{{
  let uptime = self.get_index_updated_time()
  if uptime == -1
    let obj = deepcopy(a:obj)
  else
    let obj = extend({ 'actime': uptime }, a:obj)
  endif
  call self.cache.set(a:name, obj)
  return obj
endfunction " }}}
function! s:git._get_call_opts(...) abort " {{{
  return extend({
        \ 'cwd': self.worktree,
        \}, get(a:000, 0, {}))
endfunction " }}}
function! s:git.get_index_updated_time() abort " {{{
  return s:Core.get_index_updated_time(self.repository)
endfunction " }}}
function! s:git.get_parsed_status(...) abort " {{{
  let opts = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let name = printf('status_%s', string(opts))
  let result = self._get_cache(name)
  if !opts.no_cache && !empty(result)
    return result
  endif
  let result = s:Misc.get_parsed_status(opts)
  return self._set_cache(name, result)
endfunction " }}}
function! s:git.get_parsed_commit(...) abort " {{{
  let opts = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let name = printf('commit_%s', string(opts))
  let result = self._get_cache(name)
  if !opts.no_cache && !empty(result)
    return result
  endif
  let result = s:Misc.get_parsed_commit(opts)
  return self._set_cache(name, result)
endfunction " }}}
function! s:git.get_parsed_config(...) abort " {{{
  let opts = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let name = printf('config_%s', string(opts))
  let result = self._get_cache(name)
  if !opts.no_cache && !empty(result)
    return result
  endif
  let result = s:Misc.get_parsed_config(opts)
  return self._set_cache(name, result)
endfunction " }}}
function! s:git.get_meta(...) abort " {{{
  let opts = extend({
        \ 'exclude_repository_config': 0,
        \ 'exclude_commits_ahead_of_remote': 0,
        \ 'exclude_commits_behind_remote': 0,
        \}, get(a:000, 0, {}))
  let meta = self._get_cache('meta')
  if !empty(meta)
    return meta
  endif
  let meta = {}
  let meta.current_branch = s:Core.get_current_branch(self.repository)
  let meta.last_commit_hashref = s:Core.get_last_commit_hashref(self.repository)
  let meta.last_commit_message = s:Core.get_last_commit_message(self.repository)
  let meta.last_merge_message = s:Core.get_last_merge_message(self.repository)
  if !opts.exclude_repository_config
    let meta.repository_config = s:Core.get_config(self.repository)
    let meta.current_branch_remote = s:Core.get_branch_remote(meta.repository_config, meta.current_branch)
    let meta.current_branch_merge = s:Core.get_branch_merge(meta.repository_config, meta.current_branch)
    let meta.current_remote_url = s:Core.get_remote_url(meta.repository_config, meta.current_branch_remote)
  endif
  if !opts.exclude_commits_ahead_of_remote
    let meta.commits_ahead_of_remote = s:Misc.count_commits_ahead_of_remote(self._get_call_opts())
  endif
  if !opts.exclude_commits_behind_remote
    let meta.commits_behind_remote = s:Misc.count_commits_behind_remote(self._get_call_opts())
  endif
  return self._set_cache('meta', meta)
endfunction " }}}
function! s:git.get_current_branch() abort " {{{
  let meta = self.get_meta()
  return meta.current_branch
endfunction " }}}
function! s:git.get_last_commit_hashref() abort " {{{
  let meta = self.get_meta()
  return meta.last_commit_hashref
endfunction " }}}
function! s:git.get_last_commit_message() abort " {{{
  let meta = self.get_meta()
  return meta.last_commit_message
endfunction " }}}
function! s:git.get_last_merge_message() abort " {{{
  let meta = self.get_meta()
  return meta.last_merge_message
endfunction " }}}
function! s:git.get_repository_config() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'repository_config', '')
endfunction " }}}
function! s:git.get_current_branch_remote() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'current_branch_remote', '')
endfunction " }}}
function! s:git.get_current_branch_merge() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'current_branch_merge', '')
endfunction " }}}
function! s:git.get_current_remote_url() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'current_remote_url', '')
endfunction " }}}
function! s:git.get_commits_ahead_of_remote() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'commits_ahead_of_remote', -1)
endfunction " }}}
function! s:git.get_commits_behind_remote() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'commits_behind_remote', -1)
endfunction " }}}
function! s:git.get_relative_path(path) abort " {{{
  return s:Core.get_relative_path(self.worktree, a:path)
endfunction " }}}
function! s:git.get_absolute_path(path) abort " {{{
  return s:Core.get_absolute_path(self.worktree, a:path)
endfunction " }}}
function! s:git.exec(args, ...) abort " {{{
  let opts = extend(self._get_call_opts(), get(a:000, 0, {}))
  return s:Core.exec(a:args, opts)
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
