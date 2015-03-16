"******************************************************************************
" Core functions of Git manipulation.
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
let s:_config = {}
let s:_config.executable = 'git'
let s:_config.arguments = ['-c', 'color.ui=false']

function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:Process = a:V.import('Process')
  let s:List    = a:V.import('Data.List')
  let s:Path    = a:V.import('System.Filepath')
  let s:INI     = a:V.import('Text.INI')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'Process',
        \ 'Data.List',
        \ 'System.Filepath',
        \ 'Text.INI',
        \]
endfunction " }}}
function! s:_fnamemodify(path, mods) " {{{
  let path = a:path !=# '' ? fnamemodify(a:path, a:mods) : ''
  return s:Path.remove_last_separator(path)
endfunction " }}}

function! s:config(...) " {{{
  let config = get(a:000, 0, {})
  let s:_config = extend(s:_config, config)
  return s:_config
endfunction " }}}

" Repository
function! s:find_worktree(path) " {{{
  let path = s:Prelude.path2directory(a:path)
  let d = s:_fnamemodify(finddir('.git', path . ';'), ':p:h')
  let f = s:_fnamemodify(findfile('.git', path . ';'), ':p')
  " inside '.git' directory is not a working directory
  let d = path =~# printf('\v^%s', d) ? '' : d
  " use deepest dotgit found
  let dotgit = strlen(d) >= strlen(f) ? d : f
  return strlen(dotgit) ? s:_fnamemodify(dotgit, ':h') : ''
endfunction " }}}
function! s:find_repository(worktree) " {{{
  let dotgit = s:Path.join([a:worktree, '.git'])
  if isdirectory(dotgit)
    return dotgit
  elseif filereadable(dotgit)
    " in case if the found '.git' is a file which was created via
    " '--separate-git-dir' option
    let lines = readfile(dotgit)
    if !empty(lines)
      let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
      let is_abs = s:Path.is_absolute(gitdir)
      return s:_fnamemodify((is_abs ? gitdir : dotgit[:-5] . gitdir), ':p:h')
    endif
  endif
  return ''
endfunction " }}}

function! s:get_relative_path(worktree, path) " {{{
  if !s:Path.is_absolute(a:path)
    return a:path
  endif
  let prefix = a:worktree . s:Path.separator()
  return substitute(a:path, prefix, '', '')
endfunction " }}}
function! s:get_absolute_path(worktree, path) " {{{
  if !s:Path.is_relative(a:path)
    return a:path
  endif
  return s:Path.join([a:worktree, a:path])
endfunction " }}}

" Meta (without using 'git rev-parse'. read '.git/*' directory)
function! s:get_index_updated_time(repository) " {{{
  return getftime(s:Path.join(a:repository, 'index'))
endfunction " }}}
function! s:get_current_branch(repository) " {{{
  let filename = s:Path.join(a:repository, 'HEAD')
  if !filereadable(filename)
    return ''
  endif
  let lines = readfile(filename)
  if empty(lines)
    return ''
  elseif lines[0] =~? 'refs/heads/'
    return matchstr(lines[0], 'refs/heads/\zs.\+$')
  else
    return lines[0][: 6]
  endif
endfunction " }}}
function! s:get_last_commit_hashref(repository) " {{{
  let filename = s:Path.join(a:repository, 'ORIG_HEAD')
  if !filereadable(filename)
    return ''
  endif
  let lines = readfile(filename)
  if empty(lines)
    return ''
  else
    return lines[0]
  endif
endfunction " }}}
function! s:get_last_commit_message(repository) " {{{
  let filename = s:Path.join(a:repository, 'COMMIT_MSG')
  if !filereadable(filename)
    return []
  endif
  return readfile(filename)
endfunction " }}}
function! s:get_last_merge_message(repository) " {{{
  let filename = s:Path.join(a:repository, 'MERGE_MSG')
  if !filereadable(filename)
    return []
  endif
  return readfile(filename)
endfunction " }}}

" Config (without using 'git config'. read '.git/config' directly)
function! s:get_config(repository) " {{{
  let filename = s:Path.join(a:repository, 'config')
  if !filereadable(filename)
    return {}
  endif
  return s:INI.parse_file(filename)
endfunction " }}}
function! s:get_branch_remote(config, local_branch) " {{{
  " a name of remote which the {local_branch} connect
  let section = get(a:config, printf('branch "%s"', a:local_branch), {})
  if empty(section)
    return ''
  endif
  return get(section, 'remote', '')
endfunction " }}}
function! s:get_branch_merge(config, local_branch, ...) " {{{
  " a branch name of remote which {local_branch} connect
  let truncate = get(a:000, 0, 0)
  let section = get(a:config, printf('branch "%s"', a:local_branch), {})
  if empty(section)
    return ''
  endif
  let merge = get(section, 'merge', '')
  return truncate ? substitute(merge, '\v^refs/heads/', '', '') : merge
endfunction " }}}
function! s:get_remote_url(config, remote) " {{{
  " a url of {remote}
  let section = get(a:config, printf('remote "%s"', a:remote), {})
  if empty(section)
    return ''
  endif
  return get(section, 'url', '')
endfunction " }}}

" Execution
function! s:system(args, ...) " {{{
  let args = s:List.flatten(a:args)
  let opts = extend({
        \ 'stdin': '',
        \ 'timeout': 0,
        \ 'cwd': '',
        \}, get(a:000, 0, {}))
  let original_opts = deepcopy(opts)
  " prevent E677
  if strlen(opts.stdin)
    let opts.input = opts.stdin
  endif
  let saved_cwd = ''
  if opts.cwd !=# ''
    let saved_cwd = fnamemodify(getcwd(), ':p')
    let cwd = s:Prelude.path2directory(opts.cwd)
    silent execute 'lcd ' fnameescape(cwd)
  endif
  try
    let stdout = s:Process.system(args, opts)
  finally
    if saved_cwd !=# ''
      silent execute 'lcd ' fnameescape(saved_cwd)
    endif
  endtry
  " remove trailing newline
  let stdout = substitute(stdout, '\v%(\r?\n)$', '', '')
  let status = s:Process.get_last_status()
  return { 'stdout': stdout, 'status': status, 'args': args, 'opts': original_opts }
endfunction " }}}
function! s:exec(args, ...) " {{{
  let args = [s:_config.executable, s:_config.arguments, a:args]
  let opts = get(a:000, 0, {})
  return s:system(args, opts)
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker

