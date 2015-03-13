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

  let self.config = s:config
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return [
        \ 'Prelude',
        \ 'Process',
        \ 'Data.List',
        \ 'System.Filepath',
        \]
endfunction " }}}


function! s:system(args, ...) " {{{
  let args = s:List.flatten(a:args)
  let opts = extend({
        \ 'stdin': '',
        \ 'timeout': 0,
        \ 'cwd': '',
        \}, get(a:000, 0, {}))
  let saved_cwd = ''
  if opts.cwd !=# ''
    let saved_cwd = fnamemodify('.', ':p')
    silent execute 'lcd ' fnameescape(expand(opts.cwd))
  endif

  " prevent E677
  if strlen(opts.stdin)
    let opts.input = opts.stdin
  endif
  " remove invalid options for system()
  unlet opts.stdin
  unlet opts.cwd
  let stdout = s:Process.system(args, opts)
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
    let opts.cwd = s:Prelude.path2directory(opts.cwd)
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

" Fundemental Misc
function! s:detect(...) " {{{
  let path = get(a:000, 0, '')
  let opts = { 'cwd': path }
  return s:exec_bool(['rev-parse', '--is-inside-work-tree'], opts)
endfunction " }}}
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

" Basic Commands
function! s:init(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['init', options])
endfunction " }}}
function! s:add(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['add', options])
endfunction " }}}
function! s:rm(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['rm', options])
endfunction " }}}
function! s:mv(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['mv', options])
endfunction " }}}
function! s:status(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['status', options])
endfunction " }}}
function! s:commit(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['commit', options])
endfunction " }}}
function! s:clean(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['clean', options])
endfunction " }}}

" History Commands
function! s:log(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['log', options])
endfunction " }}}
function! s:diff(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['diff', options])
endfunction " }}}
function! s:show(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['show', options])
endfunction " }}}

" Branching Commands
function! s:branch(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['branch', options])
endfunction " }}}
function! s:checkout(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['checkout', options])
endfunction " }}}
function! s:merge(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['merge', options])
endfunction " }}}
function! s:rebase(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['rebase', options])
endfunction " }}}
function! s:tag(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['tag', options])
endfunction " }}}

" Remote Commands
function! s:clone(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['clone', options])
endfunction " }}}
function! s:fetch(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['fetch', options])
endfunction " }}}
function! s:pull(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['pull', options])
endfunction " }}}
function! s:push(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['push', options])
endfunction " }}}
function! s:remote(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['remote', options])
endfunction " }}}

" Advanced Commands
function! s:reset(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['reset', options])
endfunction " }}}
function! s:rebase(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['rebase', options])
endfunction " }}}
function! s:bisect(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['bisect', options])
endfunction " }}}
function! s:grep(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['grep', options])
endfunction " }}}
function! s:stash(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['stash', options])
endfunction " }}}
function! s:prune(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['prune', options])
endfunction " }}}

" Misc Commands
function! s:rev_parse(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['rev-parse', options])
endfunction " }}}
function! s:ls_tree(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['ls-tree', options])
endfunction " }}}
function! s:cat_file(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['cat-file', options])
endfunction " }}}
function! s:archive(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['archive', options])
endfunction " }}}
function! s:gc(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['gc', options])
endfunction " }}}
function! s:fsck(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['fsck', options])
endfunction " }}}
function! s:config(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['config', options])
endfunction " }}}
function! s:help(...) " {{{
  let options = get(a:000, 0, [])
  return s:exec(['help', options])
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
