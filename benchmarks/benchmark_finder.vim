let s:V = vital#of('vital')
let s:G = s:V.import('VCS.Git.Core')
let s:F = s:V.import('VCS.Git.Finder')
 
function! s:test1(path, dummy)
  let c = 1
  let args = ['rev-parse', '--is-inside-work-tree']
  let start = reltime()
  while c < 100
    let result = s:G.exec(args, { 'cwd': a:path })
    if result.status || result.stdout !~# 'true'
      throw "Fail"
    endif
    let c += 1
  endwhile
  echomsg reltimestr(reltime(start))
endfunction

function! s:test2(path, cache)
  let c = 1
  let f = s:F.new(a:cache)
  let start = reltime()
  while c < 100
    if empty(f.find(a:path))
      throw "Fail"
    endif
    let c += 1
  endwhile
  echomsg reltimestr(reltime(start))
endfunction
 
function! Test(n, msg, cache)
  echomsg ""
  echomsg "Test" . string(a:n) . ": " . a:msg
  echomsg "=================================================================="
  let c = 1
  while c < 10
    call s:test{a:n}(expand("<sfile>"), a:cache)
    let c += 1
  endwhile
  echomsg "=================================================================="
endfunction
 
function! Tests()
  call Test(1, "Via git rev-parse --is-inside-work-tree", {})
  call Test(2, "Via VCS.Git.Finder (with dummy cache)", s:V.import('System.Cache.Dummy').new())
  call Test(2, "Via VCS.Git.Finder (with file cache)", s:V.import('System.Cache.File').new('.cache' ))
  call Test(2, "Via VCS.Git.Finder (with simple cache)", s:V.import('System.Cache.Memory').new())
endfunction

Messages maintainer: Bram Moolenaar <Bram@vim.org>
Test2: Via VCS.Git.Finder (with file cache)
==================================================================
Error detected while processing function Tests..Test..<SNR>109_test2..105..235..<SNR>195_readfile..<SNR>195__encode_name:
line    2:
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
E731: using Dictionary as a String
"benchmark_finder.vim" 49L, 1443C [w]

"benchmark_finder.vim" 49L, 1445C [w]

Test2: Via VCS.Git.Finder (with dummy cache)
==================================================================
  0.122227
  0.121106
  0.147738
  0.137061
  0.118685
  0.115667
  0.124747
  0.115976
  0.117777
==================================================================

Test2: Via VCS.Git.Finder (with file cache)
==================================================================
  0.046361
  0.042443
  0.043939
  0.040703
  0.043565-- VISUAL LINE ---- VISUAL LINE --
