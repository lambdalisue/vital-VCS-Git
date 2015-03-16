"******************************************************************************
" To get meta information of a Git repository
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
  let s:Path = a:V.import('System.Filepath')
  let s:Core = a:V.import('VCS.Git.Core')
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'System.Filepath',
        \ 'VCS.Git.Core',
        \]
endfunction " }}}

function! s:get_current_branch(repository) " {{{
  let HEAD = s:Path.join(a:repository, 'HEAD')
  if !filereadable(HEAD)
    return ''
  endif
  let lines = readfile(HEAD)
  if empty(lines)
    return ''
  elseif lines[0] =~? 'refs/heads/'
    return matchstr(lines[0], 'refs/heads/\zs.\+$')
  else
    return lines[0][: 6]
  endif
endfunction " }}}


function! s:new(worktree) " {{{
  let meta = extend({
        \ 'worktree': a:worktree,
        \ 'repository': s:Core.find_repository(a:worktree),
        \}, deepcopy(s:meta))
  return meta
endfunction " }}}


" Repository
function! s:find_worktree(path) " {{{
  let path = s:Prelude.path2directory(a:path)
  let d = s:_fnamemodify(finddir('.git', path . ';'), ':p:h')
  let f = s:_fnamemodify(findfile('.git', path . ';'), ':p')
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
function! s:find_meta(path) " {{{
  let worktree = s:find_worktree(a:path)
  if strlen(worktree)
    return {
          \ 'worktree': worktree,
          \ 'repository': s:find_repository(worktree),
          \}
  else
    return {}
  endif
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

