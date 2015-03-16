"******************************************************************************
" Git repository finder which use file based cache system to improve response
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

let s:_config = {}
let s:_config.cache_dir = expand('~/.cache/vital/vcs/git/finder')

function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:Path    = a:V.import('System.Filepath')
  let s:Cache   = a:V.import('System.Cache.File')
  let s:Core    = a:V.import('VCS.Git.Core')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'System.Filepath',
        \ 'System.Cache.File',
        \ 'VCS.Git.Core',
        \]
endfunction " }}}

function! s:_get_cache() " {{{
  if !exists('s:_cache') || s:_cache.cache_dir !=# s:_config.cache_dir
    let s:_cache = s:Cache.new(s:_config.cache_dir)
  endif
  return s:_cache
endfunction " }}}

function! s:config(...) " {{{
  let config = get(a:000, 0, {})
  let s:_config = extend(s:_config, config)
  return s:_config
endfunction " }}}
function! s:find(path) " {{{
  let cache = s:_get_cache()
  let abspath = s:Prelude.path2directory(fnamemodify(a:path, ':p'))
  let metainfo = cache.get(abspath, {})
  if !empty(metainfo) && metainfo.path == abspath
    if strlen(metainfo.worktree)
      return { 'worktree': metainfo.worktree, 'repository': metainfo.repository }
    else
      return {}
    endif
  endif
  
  let worktree = s:Core.find_worktree(abspath)
  let repository = strlen(worktree) ? s:Core.find_repository(worktree) : ''
  let metainfo = {
        \ 'path': abspath,
        \ 'worktree': worktree,
        \ 'repository': repository,
        \}
  call cache.set(abspath, metainfo)
  if strlen(metainfo.worktree)
    return { 'worktree': metainfo.worktree, 'repository': metainfo.repository }
  else
    return {}
  endif
endfunction " }}}
function! s:gc(...) " {{{
  let opts = extend({
        \ 'verbose': 1,
        \}, get(a:000, 0, {}))
  let cache = s:_get_cache()
  let files = glob(s:Path.join(cache.cache_dir, '*'), 0, 1)
  let n = len(files)
  let c = 1
  for file in files
    let metainfo = cache.get(file)
    if isdirectory(metainfo.path)
      let metainfo.worktree = s:Core.find_worktree(metainfo.path)
      let metainfo.repository = s:Core.find_repository(metainfo.worktree)
      if opts.verbose
        redraw
        echomsg printf("%d/%d: '%s' is a %s",
              \ c, n, metainfo.path,
              \ strlen(metainfo.worktree) ? 'worktree' : 'not worktree',
              \)
      endif
      call cache.set(file, metainfo)
    else
      " missing path
      call cache.remove(file)
      if opts.verbose
        redraw
        echomsg printf("%d/%d: '%s' is missing",
              \ c, n, metainfo.path,
              \)
      endif
    endif
    let c += 1
  endfor
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttabb et ai textwidth=0 fdm=marker
