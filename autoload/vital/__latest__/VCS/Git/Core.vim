"******************************************************************************
" Core functions of Git manipulation
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
let s:config = {}
let s:config.executable = 'git'
let s:config.arguments = ['-c', 'color.ui=false']

if !exists('s:const)
  let s:const = {}
  let s:const.git_commands = [
        \ 'init', 'add', 'rm', 'mv', 'status', 'commit', 'clean',
        \ 'log', 'diff', 'show',
        \ 'branch', 'checkout', 'merge', 'rebase', 'tag',
        \ 'clone', 'fetch', 'pull', 'push', 'remote',
        \ 'reset', 'rebase', 'bisect', 'grep', 'stash', 'prune',
        \ 'rev_parse', 'ls_tree', 'cat_file', 'archive', 'gc',
        \ 'fsck', 'config', 'help',
        \]
  lockvar s:const
endif

function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:Process = a:V.import('Process')
  let s:List = a:V.import('Data.List')
  let s:Path = a:V.import('System.Filepath')
  let self.config = s:config
  let self.const = s:const
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'Process',
        \ 'Data.List',
        \ 'System.Filepath',
        \]
endfunction " }}}
function! s:_fnamemodify(path, mods) " {{{
  let path = a:path !=# '' ? fnamemodify(a:path, a:mods) : ''
  return s:Path.remove_last_separator(path)
endfunction " }}}
function! s:_get_SID() abort " {{{
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\ze_get_SID$')
endfunction " }}}

" Repository
function! s:find_git(path) " {{{
  let path = s:Prelude.path2directory(a:path)
  let d = s:_fnamemodify(finddir('.git', path . ';'), ':p:h')
  let f = s:_fnamemodify(findfile('.git', path . ';'), ':p')
  " return deepest path found
  return strlen(d) >= strlen(f) ? d : f
endfunction " }}}
function! s:find_worktree(dotgit) " {{{
  return s:_fnamemodify(a:dotgit, ':h')
endfunction " }}}
function! s:find_repository(dotgit) " {{{
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

" Execution
function! s:system(args, ...) " {{{
  let args = s:List.flatten(a:args)
  let opts = extend({
        \ 'stdin': '',
        \ 'timeout': 0,
        \ 'cwd': '',
        \}, get(a:000, 0, {}))
  let saved_cwd = ''
  if opts.cwd !=# ''
    " getcwd() returns global cwd, fnamemodify('.', ':p') returns local cwd.
    let saved_cwd = fnamemodify('.', ':p')
    silent execute 'lcd ' fnameescape(expand(opts.cwd))
  endif

  let original_opts = deepcopy(opts)
  " prevent E677
  if strlen(opts.stdin)
    let opts.input = opts.stdin
  endif
  " remove invalid options for system() and execute the commands
  unlet opts.stdin
  unlet opts.cwd
  let stdout = s:Process.system(args, opts)
  " remove trailing newline
  let stdout = substitute(stdout, '\v%(\r?\n)$', '', '')
  let status = s:Process.get_last_status()
  if saved_cwd !=# ''
    silent execute 'lcd ' fnameescape(saved_cwd)
  endif
  return { 'stdout': stdout, 'status': status, 'args': args, 'opts': original_opts }
endfunction " }}}
function! s:exec(args, ...) " {{{
  let args = [s:config.executable, s:config.arguments, a:args]
  let opts = get(a:000, 0, {})
  return s:system(args, opts)
endfunction " }}}

" Define Git commands " {{{
function! s:_define_commands() " {{{
  let sid = s:_get_SID()
  for fname in s:const.git_commands
    " define function dynamically
    let name = substitute(fname, '_', '-', 'g')"
    let exec = join([
          \ printf("function! %s%s(args, ...)", sid, fname),
          \ "  let opts = get(a:000, 0, {})",
          \ printf("  return s:exec(['%s', a:args], opts)", name),
          \ "endfunction",
          \], "\n")
    execute exec
  endfor
endfunction " }}}
call s:_define_commands()
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker

