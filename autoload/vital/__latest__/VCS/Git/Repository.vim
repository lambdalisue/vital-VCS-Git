"******************************************************************************
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
  let s:C = a:V.import('System.Cache.Simple')
  let s:U = a:V.import('VCS.Git.Utils')
  let s:R = a:V.import('VCS.Git.Parser')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'System.Filepath',
        \ 'System.Cache.Simple',
        \ 'VCS.Git.Utils',
        \ 'VCS.Git.Parser']
endfunction

function! s:new(path) abort
endfunction

let s:repository = {}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
