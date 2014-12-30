"******************************************************************************
" A utility module of Vital.VCS.Git
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:P = a:V.import('System.Filepath')
endfunction
function! s:_vital_depends() abort
  return ['System.Filepath']
endfunction


function! s:abspath(base, ...)
  " abspath({base} [, {mods}])
  "
  "   Return an absolute path of {base}
  "
  "   {base}: A path string
  "   {mods}: A modification string of |fnamemodify| (optional)
  "
  " Origin: vim-vcs/autoload/vcs/type/git.vim
  " Author: thinca <thinca+vim@gmail.com>
  " License: Creative Commons Attribution 2.1 Japan License
  let mods = get(a:000, 0, ':p')
  let path = a:base !=# '' ? fnamemodify(escape(a:base, ' '), mods) : ''
  " make sure that the last separator of a directory path is removed
  return s:P.remove_last_separator(path)
endfunction

function! s:force_dirpath(path)
  " force_dirpath({path})
  "
  "   Return a directory absolute path of {path}. If the {path} points a file,
  "   it returns an absolute path of its parent directory.
  "
  "   {path}: A path string
  "
  if isdirectory(a:path)
    return s:abspath(a:path)
  else
    return s:abspath(a:path, ':p:h')
  endif
endfunction

function! s:find_git(path)
  " find_git({path})
  "
  "   Recursively find '.git' directory or file ('--separate-git-dir' option)
  "   from {path} and return an absolute path of that.
  "
  "   {path}: A path string
  "
  " Origin: vim-vcs/autoload/vcs/type/git.vim
  " Author: thinca <thinca+vim@gmail.com>
  " License: Creative Commons Attribution 2.1 Japan License
  let path = s:force_dirpath(a:path)
  let dir = s:abspath(finddir('.git', path . ';'), ':p:h')
  let file = s:abspath(findfile('.git', path . ';'), ':p')
  return len(dir) >= len(file) ? dir : file
endfunction

function! s:find_repository(path)
  " find_repository({path})
  "
  "   Recursively find '.git' directory or file ('--separate-git-dir' option)
  "   from {path} and return an absolute path of the repository directory.
  "
  "   {path}: A path string
  "
  " Origin: vim-vcs/autoload/vcs/type/git.vim
  " Author: thinca <thinca+vim@gmail.com>
  " License: Creative Commons Attribution 2.1 Japan License
  let dotgit = s:find_git(a:path)
  if isdirectory(dotgit)
    return dotgit
  elseif filereadable(dotgit)
    " in case if the found '.git' is a file which was created via
    " '--separate-git-dir' option
    let lines = readfile(dotgit)
    if !empty(lines)
      let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
      let is_abs = s:P.is_absolute(gitdir)
      return s:abspath((is_abs ? gitdir : dotgit[: -5] . gitdir), ':p:h')
    endif
  endif
  return ''
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
