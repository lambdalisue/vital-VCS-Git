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

get_parsed_status([{opts}])		*Vital.VCS.Git.Misc.get_parsed_status()*

	Get |Vital.VCS.Git.StatusParser| parsed current working tree status.

get_parsed_config([{opts}, {scope}])	*Vital.VCS.Git.Misc.get_config_status()*

	Get |Vital.VCS.Git.ConfigParser| parsed Git config (note this is not a
	repository config). The {scope} indicate the config scope explained
	below.

	''
	Equivalent to '$ git config -l'

	'local'
	Equivalent to '$ git config -l --local'

	'global'
	Equivalent to '$ git config -l --global'

	'system'
	Equivalent to '$ git config -l --system'


==============================================================================
vim:tw=78:fo=tcq2mM:ts=8:ft=help:norl
