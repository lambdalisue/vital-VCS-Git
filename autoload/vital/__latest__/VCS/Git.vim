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
let s:config = {}
let s:config.executable = 'git'
let s:config.arguments = ['-c', 'color.ui=false']

function! s:_vital_loaded(V) dict abort " {{{
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:Process = a:V.import('Process')
  let s:List = a:V.import('Data.List')
  let s:Path = a:V.import('System.Filepath')
  let s:StatusParser = a:V.import('VCS.Git.StatusParser')
  let s:ConfigParser = a:V.import('VCS.Git.ConfigParser')

  let self.config = s:config
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'Process',
        \ 'Data.List',
        \ 'System.Filepath',
        \ 'VCS.Git.StatusParser',
        \ 'VCS.Git.ConfigParser',
        \]
endfunction " }}}


" Private ====================================================================
function! s:_ensure_dirname(path) abort " {{{
  let path = fnameescape(a:path)
  if isdirectory(path)
    return fnamemodify(path, ':p')
  else
    return fnamemodify(path, ':p:h')
  endif
endfunction " }}}


" Public =====================================================================
function! s:system(args, ...) " {{{
  let args = s:List.flatten(a:args)
  let opts = extend({
        \ 'stdin': '',
        \ 'timeout': 0,
        \ 'cwd': '',
        \}, get(a:000, 0, {}))
  let saved_cwd = ''
  if opts.cwd !=# ''
    let saved_cwd = getcwd()
    silent execute 'lcd ' fnameescape(expand(opts.cwd))
  endif
  if s:Process.has_vimproc()
    let stdout = s:Process.system(args, opts.stdin, opts.timeout)
  else
    let stdout = s:Process.system(args, opts.stdin)
  endif
  " remove trailing newline
  let stdout = substitute(stdout, '\v%(\r?\n)$', '', '')
  let status = s:Process.get_last_status()
  if saved_cwd !=# ''
    silent execute 'lcd ' fnameescape(saved_cwd)
  endif
  return { 'stdout': stdout, 'status': status }
endfunction " }}}
function! s:exec(args, ...) " {{{
  let args = [s:config.executable, s:config.arguments, a:args]
  let opts = extend({}, get(a:000, 0, {}))
  " ensure cwd is directory
  if has_key(opts, 'cwd')
    let opts.cwd = s:_ensure_dirname(opts.cwd)
  endif
  return s:system(args, opts)
endfunction " }}}
function! s:exec_bool(args, ...) " {{{
  let args = a:args
  let opts = get(a:000, 0, {})
  let result = s:exec(args, opts)
  return result.status == 0 && result.stdout ==# 'true'
endfunction " }}}
function! s:exec_path(args, ...) " {{{
  let args = a:args
  let opts = get(a:000, 0, {})
  let result = s:exec(args, opts)
  if result.status != 0
    return ''
  endif
  return s:Path.remove_last_separator(fnameescape(result.stdout))
endfunction " }}}
function! s:exec_line(args, ...) " {{{
  let args = a:args
  let opts = get(a:000, 0, {})
  let result = s:exec(args, opts)
  if result.status != 0
    return ''
  endif
  return result.stdout
endfunction " }}}

" detection
function! s:is_worktree(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  return s:exec_bool(['rev-parse', '--is-inside-work-tree'], opts)
endfunction " }}}

" path
function! s:get_repository_path(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  " --git-dir sometime does not return absolute path
  let result = s:exec_path(['rev-parse', '--git-dir'], opts)
  return s:Path.remove_last_separator(fnamemodify(result, ':p'))
endfunction " }}}
function! s:get_worktree_path(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  return s:exec_path(['rev-parse', '--show-toplevel'], opts)
endfunction " }}}
function! s:get_relative_path(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['rev-parse', '--show-prefix'], opts)
  if result.status != 0
    return ''
  endif
  if isdirectory(path)
    return s:Path.remove_last_separator(fnameescape(result.stdout))
  else
    return s:Path.remove_last_separator(s:Path.join(
          \ fnameescape(result.stdout),
          \ fnamemodify(fnameescape(path), ':t')
          \))
  endif
endfunction " }}}
function! s:get_absolute_path(...) " {{{
  let path = get(a:000, 0, '')
  let root = s:get_worktree_path(path)
  return s:Path.remove_last_separator(s:Path.join(root, fnameescape(path)))
endfunction " }}}

" info
function! s:get_branch_name(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  return s:exec_line(['rev-parse', '--abbrev-ref', 'HEAD'], opts)
endfunction " }}}
function! s:get_status(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['status', '--short'], opts)
  if result.status != 0
    return {}
  endif
  return s:StatusParser.parse(result.stdout)
endfunction " }}}
function! s:get_config(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['config', '-l'], opts)
  if result.status != 0
    return {}
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}
function! s:get_local_config(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['config', '--local', '-l'], opts)
  if result.status != 0
    return {}
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}
function! s:get_global_config(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['config', '--global', '-l'], opts)
  if result.status != 0
    return {}
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}
function! s:get_system_config(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  let result = s:exec(['config', '--global', '-l'], opts)
  if result.status != 0
    return {}
  endif
  return s:ConfigParser.parse(result.stdout)
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
