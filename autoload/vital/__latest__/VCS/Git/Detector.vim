"******************************************************************************
" Git detector
"
" A fast Git repository detector which use pure vimscript only and does not
" execute any external process
"
" Ref:      https://gist.github.com/lambdalisue/4b6597c25bf20df2ff35
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
  let s:String       = a:V.import('Data.String')
  let s:Path         = a:V.import('System.Filepath')
  let s:Cache        = a:V.import('System.Cache')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'Data.String',
        \ 'System.Filepath',
        \]
endfunction " }}}

function! s:_fnamemodify(path, mods) " {{{
  let path = a:path !=# '' ? fnamemodify(a:path, a:mods) : ''
  return s:Path.remove_last_separator(path)
endfunction " }}}
function! s:_create_hash(path) abort " {{{
  if len(a:path) < 150
    let hash = substitute(substitute(
          \ a:path, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  else
    let hash = s:String.hash(a:path)
  endif
  return hash
endfunction " }}}
function! s:_find_git(path) " {{{
  let path = s:Prelude.path2directory(a:path)
  let d = s:_fnamemodify(finddir('.git', path . ';'), ':p:h')
  let f = s:_fnamemodify(findfile('.git', path . ';'), ':p')
  " return deepest path found
  return strlen(d) >= strlen(f) ? d : f
endfunction " }}}
function! s:_find_worktree(dotgit) " {{{
  return s:_fnamemodify(a:dotgit, ':h')
endfunction " }}}
function! s:_find_repository(dotgit) " {{{
  if isdirectory(a:dotgit)
    return a:dotgit
  elseif filereadable(a:dotgit)
    " in case if the found '.git' is a file which was created via
    " '--separate-git-dir' option
    let lines = readfile(a:dotgit)
    if !empty(lines)
      let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
      let is_abs = s:Path.is_absolute(gitdir)
      return s:_fnamemodify((is_abs ? gitdir : a:dotgit[:-5] . gitdir), ':p:h')
    endif
  endif
  return ''
endfunction " }}}

let s:detector = {}
function! s:detector._read_cache(filename) abort " {{{
  let cache_dir = self.cache_dir
  let contents = s:Cache.readfile(cache_dir, a:filename) 
  if empty(contents)
    let info = {}
  else
    sandbox let info = eval(contents[0])
  endif
  return info
endfunction " }}}
function! s:detector._write_cache(filename, info) abort " {{{
  let cache_dir = self.cache_dir
  call s:Cache.writefile(cache_dir, a:filename, [string(a:info)])
endfunction " }}}
function! s:detector._delete_cache(filename) abort " {{{
  let cache_dir = self.cache_dir
  call s:Cache.deletefile(cache_dir, a:filename)
endfunction " }}}
function! s:detector.gc(...) " {{{
  let opts = extend({ 'verbose': 1 }, get(a:000, 0, {}))
  let files = glob(s:Path.join(self.cache_dir, '*'), 0, 1)
  let n = len(files)
  let c = 0
  for file in files
    let hash = fnamemodify(file, ':t')
    let info = self._read_cache(hash)
    if isdirectory(info.path)
      let dotgit = s:_find_git(info.path)
      if strlen(dotgit)
        let info.is_inside_worktree = 1
        let info.worktree_path = s:_find_worktree_path(dotgit)
        let info.repository_path = s:_find_repository_path(dotgit)
        if opts.verbose
          redraw
          echomsg printf("%d/%d: '%s' is inside worktree (%s)", c, n, info.path, info.worktree_path)
        endif
      else
        let info.is_inside_worktree = 0
        let info.worktree_path = ''
        let info.repository_path = ''
        if opts.verbose
          redraw
          echomsg printf("%d/%d: '%s' is not inside worktree", c, n, info.path)
        endif
      endif
      call self._write_cache(hash, info)
    else
      if opts.verbose
        redraw
        echomsg printf("%d/%d: '%s' does not exist", c, n, info.path)
      endif
      call self._delete_cache(hash)
    endif
    let c += 1
  endfor
endfunction " }}}
function! s:detector.find(path, ...) " {{{
  let opts = extend({ 'use_cache': 1 }, get(a:000, 0, {}))
  let path = s:_fnamemodify(s:Prelude.path2directory(a:path), ':p')
  let hash = s:_create_hash(path)
  let info = self._read_cache(hash)
  if !empty(info) && opts.use_cache && info.path == path
    return info.is_inside_worktree ? info : {}
  endif
  " no cache is found.
  let dotgit = s:_find_git(path)
  if strlen(dotgit) == 0
    let info = {
          \ 'is_inside_worktree': 0,
          \ 'path': path,
          \ 'worktree_path': '',
          \ 'repository_path': '',
          \}
  else
    let info = {
          \ 'is_inside_worktree': 1,
          \ 'path': path,
          \ 'worktree_path': s:_find_worktree(dotgit),
          \ 'repository_path': s:_find_repository(dotgit),
          \}
  endif
  call self._write_cache(hash, info)
  return info.is_inside_worktree ? info : {}
endfunction " }}}

function! s:new(config) " {{{
  let detector = extend(deepcopy(s:detector), a:config)
  if !has_key(detector, 'cache_dir')
    throw 'VCS.Git.Detector: "cache_dir" is required in {config} dictionary'
  endif
  return detector
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttabb et ai textwidth=0 fdm=marker
