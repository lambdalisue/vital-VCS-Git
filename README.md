vital-VCS-Git [![Build Status](https://travis-ci.org/lambdalisue/vital-VCS-Git.svg)](https://travis-ci.org/lambdalisue/vital-VCS-Git)
==============================================================================

A fundamental git manipulation library.

- Version:  0.1.0
- Author:   Alisue <lambdalisue@hashnote.net>
- Support:  Vim 7.3 and above (See [travis-ci](https://travis-ci.org/lambdalisue/vital-VCS-Git))


INTRODUCTIONS
==============================================================================
*Vital.VCS.Git* is a fundemental Git manipulation library powerd by vital.vim.
It provide the following features.

1. Find git repository recursively from a specified path
2. Parse Git repository config (.git/config)
2. Parse Git config (git config --list)
3. Parse Git status (git status --porcelain)
4. Parse Git commit status (git commit --dry-run --porcelain)
5. Fetch Git meta information (e.g. current branch name)
6. Execute Git command

The library try to NOT use Git command as much as possible and try to cache
result as much as possible to improve the speed. With this strategy, the
response speed would 100 times faster than executing Git command everytime.

General vim plugin developer do not need to know but if you want to manipulate
Git in low level, the following submodules would help you.

- Vital.VCS.Git.Core - A core function module of Git manipulation
- Vital.VCS.Git.Misc - A misc function module of Git manipulation
- Vital.VCS.Git.Finder - A fast git repository finder
- Vital.VCS.Git.ConfigParser - A Git config parser
- Vital.VCS.Git.StatusParser - A Git status parser

All modules above provide a low level API and do not cache any results,
contrusting to Vital.VCS.Git which try to cache things per each Git
repository.

Benchmark: https://gist.github.com/lambdalisue/c73ad37a33b8242fba13

This library is strongly inspired by [vim-vcs](https://github.com/thinca/vim-vcs)
and several mechanisms (especially finding a git repository) is taken from that.


INSTALL
==============================================================================

The following external vital modules are required to bundle Vital.VCS.Git.

- vital-System-Cache-Unified
  https://github.com/lambdalisue/vital-System-Cache-Unified

Note that the external vital modules above are required only when you want to
bundle Vital.VCS.Git into your plugin. After you bundle it, the modules are
no longer required, mean that your plugin users do not required to install the
modules.

To install it and requirements, use neobundle.vim (or other vim plugin
managers) like:

```vim
NeoBundle 'lambdalisue/vital-System-Cache-Unified'
NeoBundle 'lambdalisue/vital-VCS-Git'
```

USAGE
==============================================================================

First of all, call `Vital.VCS.Git.new()` or `Vital.VCS.Git.find()` to create
a Git instance. The instance will cached per each Git working tree.

```vim

let s:G = s:V.import('VCS.Git')
" find a git working tree and repository to create a Git instance
let git = s:G.find(expand('%'))
```

Then you can get meta information of the repository with
`Vital.VCS.Git-instance.get_meta()`

```vim
let meta = git.get_meta()
" echo current branch
echo meta.current_branch
" echo remote branch of current branch
echo meta.current_remote_branch
```

To call a git command, check `Vital.VCS.Git-git-commands` to find if the command
is already exists or call `Vital.VCS.Git-instance.exec()`.

```vim
" add is already prepared
call git.add({'force': 1}, ['file1.txt', 'file2.txt'])
" rev-parse is not
call git.exec(['rev-parse', '--is-inside-work-tree'])
```

To bundle `Vital.VCS.Git` into your plugin, call `Vitalize` as

```vim
:Vitalize --name=your_plugin_name . +VCS.Git
```

It will automatically bundle `Vital.VCS.Git` and required vital modules to
your plugin.


LICENSE
==============================================================================

MIT license

    Copyright (c) 2014 Alisue, hashnote.net

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files
    (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
