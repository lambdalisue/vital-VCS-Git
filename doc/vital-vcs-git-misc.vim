*vital-vcs-git-misc.txt*	A misc functions of Git manipulation

Version: 0.1.0
Author:  Alisue <lambdalisue@hashnote.net>	*Vital.VCS.Git.Misc-author*
Support: Vim 7.3 and above
License: MIT license  {{{
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
}}}


==============================================================================
CONTENTS				*Vital.VCS.Git.Misc-contents*

Introduction		|Vital.VCS.Git.Misc-introduction|
Functions		|Vital.VCS.Git.Misc-functions|


==============================================================================
INTRODUCTION				*Vital.VCS.Git.Misc-introduction*

*Vital.VCS.Git.Misc* is a misc function module of |Vital.VCS.Git|.
The module should not be used directly while |Vital.VCS.Git| provide more
user friendly and efficient APIs.

==============================================================================
FUNCTIONS				*Vital.VCS.Git.Misc-functions*

get_parsed_status([{opts}])		*Vital.VCS.Git.Misc.get_parsed_status()*

	Get |Vital.VCS.Git.StatusParser| parsed current working tree status.
	The {opts} are passed to |Vital.VCS.Git.Core.exec()| and the following
	options are available in {opts}.
	See 'git status --help' for means of indivisual options.

	- branch
	- untracked_files
	- ignore_submodules
	- ignored
	- z

get_parsed_commit([{opts}])		*Vital.VCS.Git.Misc.get_parsed_commit()*

	Get |Vital.VCS.Git.StatusParser| parsed current working tree status
	for commit.
	The {opts} are passed to |Vital.VCS.Git.Core.exec()| and the following
	options are available in {opts}.
	See 'git commit --help' for means of indivisual options.
	
	- all
	- patch
	- reuse_message
	- reedit_message
	- fixup
	- squash
	- reset_author
	- short
	- z
	- file
	- author
	- date
	- message
	- template
	- signoff
	- no_verify
	- allow_empty
	- allow_empty_message
	- cleanup
	- edit
	- amend
	- include
	- only
	- untracked_files
	- verbose
	- quiet
	- status
	- no_status


get_parsed_config([{opts}])		*Vital.VCS.Git.Misc.get_config_status()*

	Get |Vital.VCS.Git.ConfigParser| parsed Git config (note this is not a
	repository config).
	The {opts} are passed to |Vital.VCS.Git.Core.exec()| and the following
	options are available in {opts}.
	See 'git config --help' for means of indivisual options.

	- local
	- global
	- system
	- file
	- blob
	- bool
	- int
	- bool_or_int
	- path
	- includes

get_meta({repository}[, {opts}])	*Vital.VCS.Git.Misc.get_meta()*

	Return a dictionary which contains meta informations.
	If { 'exclude_repository_config': 1 } is specified to {opts}, all meta
	informations related to repository config will be truncated.
	The following meta informations are included:

	'head'
	A value returnd from |Vital.System.Core.get_head()|

	'fetch_head'
	A value returnd from |Vital.System.Core.get_fetch_head()|

	'orig_head'
	A value returnd from |Vital.System.Core.get_orig_head()|

	'merge_head'
	A value returnd from |Vital.System.Core.get_merge_head()|

	'merge_mode'
	A value returnd from |Vital.System.Core.get_merge_mode()|

	'commit_editmsg'
	A value returnd from |Vital.System.Core.get_commit_editmsg()|

	'merge_msg'
	A value returnd from |Vital.System.Core.get_merge_msg()|

	'current_branch'
	A current branch name.

	'repository_config'
	A value returnd from |Vital.System.Core.get_repository_config()|.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'current_branch_remote'
	A value returnd from |Vital.System.Core.get_branch_remote()| of
	current branch.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'current_branch_merge'
	A value returnd from |Vital.System.Core.get_branch_merge()| of
	current branch.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'current_remote_fetch'
	A value returnd from |Vital.System.Core.get_remote_fetch()| of
	current branch remote.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'current_remote_url'
	A value returnd from |Vital.System.Core.get_remote_url()| of
	current branch remote.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'comment_char'
	A value returnd from |Vital.System.Core.get_comment_char()|.
	The entry would not exist if 'exclude_repository_config' option is
	specified.

	'current_remote_branch'
	A remote branch which the current branch connected.

			*Vital.VCS.Git.Misc.get_last_commitmsg()*
get_last_commitmsg([{opts}])

	Return a last commit message. Generally it is equal to
	'commit_editmsg' attribute of a return dictionary from
	|Vital.VCS.Git.Misc.get_meta()| but this is more acculate.

			*Vital.VCS.Git.Misc.count_commits_ahead_of_remote()*
count_commits_ahead_of_remote([{opts}])

	Get commit logs which ahead of remote and return the total number of
	these commmits.
	The {opts} are passed to |Vital.VCS.Git.Core.exec()|.

			*Vital.VCS.Git.Misc.count_commits_behind_remote()*
count_commits_behind_remote([{opts}])

	Get commit logs which behind remote and return the total number of
	these commmits.
	The {opts} are passed to |Vital.VCS.Git.Core.exec()|.


==============================================================================
vim:tw=78:fo=tcq2mM:ts=8:ft=help:norl
