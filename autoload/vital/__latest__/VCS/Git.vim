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
  let s:Dict = s:V.import('Data.Dict')
  let s:Prelude = s:V.import('Prelude')
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
function! s:_opts2args(opts, defaults) abort " {{{
  let args = []
  for [key, default] in items(a:defaults)
    if has_key(a:opts, key)
      let val = get(a:opts, key)
      if s:Prelude.is_number(default) && s:Prelude.is_number(val) && val
        if strlen(key) == 1
          call add(args, printf('-%s', key))
        else
          call add(args, printf('--%s', substitute(key, '_', '-', 'g')))
        endif
      elseif s:Prelude.is_string(default) && default =~# '\v^=' && default !=# printf('=%s', val)
        if strlen(key) == 1
          call add(args, printf('-%s%s', key, val))
        else
          call add(args, printf('--%s=%s', substitute(key, '_', '-', 'g'), val))
        endif
      elseif s:Prelude.is_string(default) && default !=# val
        if strlen(key) == 1
          call add(args, printf('-%s', key))
        else
          call add(args, printf('--%s', substitute(key, '_', '-', 'g')))
        endif
        call add(args, val)
      endif
      unlet val
    endif
    unlet default
  endfor
  return args
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
  let options = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let opts = s:Dict.omit(options, ['no_cache'])
  let name = printf('status_%s', string(opts))
  let result = self._get_cache(name)
  if !options.no_cache && !empty(result)
    return result
  endif
  let result = s:Misc.get_parsed_status(opts)
  return self._set_cache(name, result)
endfunction " }}}
function! s:git.get_parsed_commit(...) abort " {{{
  let options = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let opts = s:Dict.omit(options, ['no_cache'])
  let name = printf('commit_%s', string(opts))
  let result = self._get_cache(name)
  if !options.no_cache && !empty(result)
    return result
  endif
  let result = s:Misc.get_parsed_commit(opts)
  return self._set_cache(name, result)
endfunction " }}}
function! s:git.get_parsed_config(...) abort " {{{
  let options = self._get_call_opts(extend({
        \ 'no_cache': 0,
        \}, get(a:000, 0, {})))
  let opts = s:Dict.omit(options, ['no_cache'])
  let name = printf('config_%s', string(opts))
  let result = self._get_cache(name)
  if !options.no_cache && !empty(result)
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
        \ 'exclude_last_commitmsg': 0,
        \}, get(a:000, 0, {}))
  let meta = self._get_cache('meta')
  if !empty(meta)
    return meta
  endif
  let meta = {}
  let meta.current_branch = s:Core.get_current_branch(self.repository)
  let meta.cached_commitmsg = s:Core.get_cached_commitmsg(self.repository)
  if !opts.exclude_repository_config
    let meta.repository_config = s:Core.get_config(self.repository)
    let meta.current_branch_remote = s:Core.get_branch_remote(meta.repository_config, meta.current_branch)
    let meta.current_branch_merge = s:Core.get_branch_merge(meta.repository_config, meta.current_branch)
    let meta.current_remote_url = s:Core.get_remote_url(meta.repository_config, meta.current_branch_remote)
    let meta.comment_char = s:Core.get_comment_char(meta.repository_config)
  endif
  if !opts.exclude_commits_ahead_of_remote
    let meta.commits_ahead_of_remote = s:Misc.count_commits_ahead_of_remote(self._get_call_opts())
  endif
  if !opts.exclude_commits_behind_remote
    let meta.commits_behind_remote = s:Misc.count_commits_behind_remote(self._get_call_opts())
  endif
  if !opts.exclude_last_commitmsg
    let meta.last_commitmsg = s:Misc.get_last_commitmsg(self._get_call_opts())
  endif
  return self._set_cache('meta', meta)
endfunction " }}}
function! s:git.get_current_branch() abort " {{{
  let meta = self.get_meta()
  return meta.current_branch
endfunction " }}}
function! s:git.get_cached_commitmsg() abort " {{{
  let meta = self.get_meta()
  return meta.cached_commitmsg
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
function! s:git.get_comment_char() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'comment_char', '#')
endfunction " }}}
function! s:git.get_commits_ahead_of_remote() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'commits_ahead_of_remote', -1)
endfunction " }}}
function! s:git.get_commits_behind_remote() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'commits_behind_remote', -1)
endfunction " }}}
function! s:git.get_last_commitmsg() abort " {{{
  let meta = self.get_meta()
  return get(meta, 'last_commitmsg', [])
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

function! s:git.add(options, ...) abort " {{{
  let defaults = {
        \ 'dry_run': 0,
        \ 'verbose': 0,
        \ 'force': 0,
        \ 'interactive': 0,
        \ 'patch': 0,
        \ 'edit': 0,
        \ 'update': 0,
        \ 'all': 0,
        \ 'intent_to_add': 0,
        \ 'refresh': 0,
        \ 'ignore_errors': 0,
        \ 'ignore_missing': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['add'], s:_opts2args(a:options, defaults))
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}
function! s:git.rm(options, ...) abort " {{{
  let defaults = {
        \ 'force': 0,
        \ 'dry_run': 0,
        \ 'r': 0,
        \ 'cached': 0,
        \ 'ignore_unmatch': 0,
        \ 'quiet': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['rm'], s:_opts2args(a:options, defaults))
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}
function! s:git.checkout(options, commit, ...) abort " {{{
  let defaults = {
        \ 'quiet': 0,
        \ 'force': 0,
        \ 'ours': 0,
        \ 'theirs': 0,
        \ 'b': '',
        \ 'B': '',
        \ 'track': 0,
        \ 'no_track': 0,
        \ 'l': 0,
        \ 'detach': 0,
        \ 'orphan': '',
        \ 'merge': 0,
        \ 'conflict': '=merge',
        \ 'patch': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['checkout'], s:_opts2args(a:options, defaults))
  if strlen(a:commit)
    call add(args, a:commit)
  endif
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}
function! s:git.status(options, ...) abort " {{{
  let defaults = {
        \ 'short': 0,
        \ 'branch': 0,
        \ 'porcelain': 0,
        \ 'untracked_files': '=all',
        \ 'ignore_submodules': '=all',
        \ 'ignored': 0,
        \ 'z': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['status'], s:_opts2args(a:options, defaults))
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}
function! s:git.commit(options, ...) abort " {{{
  let defaults = {
        \ 'all': 0,
        \ 'patch': 0,
        \ 'reuse_message': '=',
        \ 'reedit_message': '=',
        \ 'fixup': '=',
        \ 'squash': '=',
        \ 'reset_author': 0,
        \ 'short': 0,
        \ 'porcelain': 0,
        \ 'z': 0,
        \ 'file': '=',
        \ 'author': '=',
        \ 'date': '=',
        \ 'message': '=',
        \ 'template': '=',
        \ 'signoff': 0,
        \ 'no_verify': 0,
        \ 'allow_empty': 0,
        \ 'allow_empty_message': 0,
        \ 'cleanup': '=default',
        \ 'edit': 0,
        \ 'amend': 0,
        \ 'include': 0,
        \ 'only': 0,
        \ 'untracked_files': '=all',
        \ 'verbose': 0,
        \ 'quiet': 0,
        \ 'dry_run': 0,
        \ 'status': 0,
        \ 'no_status': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['commit'], s:_opts2args(a:options, defaults))
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}
function! s:git.diff(options, commit, ...) abort " {{{
  let defaults = {
        \ 'patch': 0,
        \ 'unified': '=',
        \ 'raw': 0,
        \ 'patch_with_raw': 0,
        \ 'minimal': 0,
        \ 'patience': 0,
        \ 'histogram': 0,
        \ 'stat': '=',
        \ 'numstat': 0,
        \ 'shortstat': 0,
        \ 'dirstat': '=',
        \ 'summary': 0,
        \ 'patch_with_stat': 0,
        \ 'z': 0,
        \ 'name_only': 0,
        \ 'name_status': 0,
        \ 'submodule': '=log',
        \ 'color': '=never',
        \ 'no_color': 0,
        \ 'word_diff': '=plain',
        \ 'word_diff_regex': '=',
        \ 'color_words': '=',
        \ 'no_renames': 0,
        \ 'check': 0,
        \ 'full_index': 0,
        \ 'binary': 0,
        \ 'abbrev': '=',
        \ 'break_rewrites': '=',
        \ 'find_renames': '=',
        \ 'find_copies': '=',
        \ 'find_copies_harder': 0,
        \ 'irreversible_delete': 0,
        \ 'l': '=',
        \ 'diff_filter': '=',
        \ 'S': '=',
        \ 'G': '=',
        \ 'pickaxe_all': 0,
        \ 'pickaxe_regex': 0,
        \ 'O': '=',
        \ 'R': 0,
        \ 'relative': '=',
        \ 'text': 0,
        \ 'ignore_space_at_eol': 0,
        \ 'ignore_space_change': 0,
        \ 'ignore_all_space': 0,
        \ 'inter_hunk_context': '=',
        \ 'function_context': 0,
        \ 'exit_code': 0,
        \ 'quiet': 0,
        \ 'ext_diff': 0,
        \ 'no_ext_diff': 0,
        \ 'textconv': 0,
        \ 'no_textconv': 0,
        \ 'ignore_submodules': '=all',
        \ 'src_prefix': '=',
        \ 'dst_prefix': '=',
        \ 'no_prefix': 0,
        \} 
  let opts = s:Dict.omit(a:options, keys(defaults))
  let args = extend(['diff'], s:_opts2args(a:options, defaults))
  if get(a:options, 'cached', 0)
    call add(args, '--cached')
  endif
  if strlen(a:commit) > 0
    call add(args, a:commit)
  endif
  let filenames = gita#util#listalize(get(a:000, 0, []))
  if len(filenames) > 0
    call add(args, ['--', filenames])
  endif
  return self.exec(args, opts)
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
