#!/bin/bash

# projectsetup
#
# Automate building a project and its dependencies based on a recipe file.
# See README.md for details.

# (c) Copyright 2013 Rowan Thorpe
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION=0.1
# keep the "set -e", we rely on it in many places
set -e

# parse args/opts
_scriptname=`basename "$0" .sh`
_self_contained=0
while test -n "$1"; do
	case "$1" in
	--help|--usage|-h)
		cat <<EOH >&2
Usage: ${_scriptname} [OPTIONS] "projectname"

Automates building a project and its dependencies based on a recipe file.

OPTIONS

  --self-contained|-s: *EXPERIMENTAL*
                       Use virtualenvwrapper to work in (and install everything
                       into) a self-contained directory. The virtualenv
                       directory will have the same name as the projectname.
  --help|--usage|-h:   This message.

See README.md for details

COPYRIGHT

 projectsetup v$VERSION

 Copyright (C) 2013  Rowan Thorpe.
 This is free software; see the source for copying conditions.
 There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
 PARTICULAR PURPOSE.

Report bugs to <rowan@rowanthorpe.com>
EOH
		exit 0
		;;
	--self-contained|-s)
		_self_contained=1
		shift
		;;
	--)
		shift
		break
		;;
	-*)
		printf %s\\n "${_scriptname}: Unknown option \"$1\"" >&2
		;;
	*)
		break
		;;
	esac
done
test -n "$1"

# get the recipe contents
_input_contents="$(cat "${_scriptname}_${1}.txt")"

# setup global stuff
if test 1 = "$_self_contained"; then
	type -p mkvirtualenv || . /etc/bash_completion.d/virtualenvwrapper
	_env_exists=0
	for _env in `lsvirtualenv -b`; do if test "$_env" = "$1"; then _env_exists=1; fi; done
	## TODO: Maybe write virtualenvwrapper clone scripts:
	##       (A) in POSIX shell, (B) to be "set -e" friendly
	if test "$_env_exists" = 1; then
		set +e; workon "$1"; set -e
	else
		set +e; mkvirtualenv --system-site-packages "$1"; set -e
	fi
	unset _env_exists
	set +e; cdvirtualenv; set -e
	export LIBRARY_PATH="${VIRTUAL_ENV}/lib"
	export C_INCLUDE_PATH="${VIRTUAL_ENV}/include"
	_root_dir="$VIRTUAL_ENV"
	export _root_dir
	printf %s\\n "Setting up self-contained project in \"$VIRTUAL_ENV\"" >&2
else
	_root_dir=/usr/local
	export _root_dir
	cd "${_root_dir}/src"
	printf %s\\n "Setting up non-self-contained project in \"$_root_dir\"" >&2
fi

# setup up local stuff
start_dir="$(readlink -e -n .)"
_builddir="${_scriptname}_builddir"
test -d "$_builddir" || mkdir "$_builddir"
trap 'cd "$start_dir"; test 0 = "$_self_contained" || deactivate; exit' EXIT
cd "$_builddir"
_get_func=
_compile_func=
_app=
_extra_get_info=
_pre_get_eval=
_post_get_eval=
_pre_compile_eval=
_post_compile_eval=

# setup list of possible get, build and install functions here
## reference them in the recipe file, and don't use absolute paths in case this is
## running as "self-contained" (under virtualenv)
_cvs() { cvs -z3 -d "$_extra_get_info" co "$_app"; }
_gh() { git clone "https://github.com/${_extra_get_info}/${_app}.git"; }
_gc() { hg clone "https://code.google.com/${_app:0:1}/$_app"; }
_lp() { bzr branch "lp:$_app"; }
_ghdl() {
	_author=${_extra_get_info%% *}
	_version=${_extra_get_info#* }
	wget "https://github.com/downloads/${_author}/${_app}/${_app}-${_version}.tar.gz"
	tar zxf ${_app}-${_version}.tar.gz
	mv ${_app}-$_version $_app
}
_m() { make; }
_cm() { test -x configure || chmod +x configure; ./configure --prefix="$_root_dir"; _m; }
_acm() { test -x autogen.sh || chmod +x autogen.sh; ./autogen.sh; _cm; }
_pysub() { python setup.py build; }
_i() { make install; }
_pysui() { python setup.py install --prefix="$_root_dir"; }

# setup main program functions
_get_wrap() {
	if ! test -e "${_app}.DONE_GET"; then
		if test -e "$_app"; then
			if test -d "$_app"; then
				rm -fR "$_app"
			else
				echo "** _app directory name already exists and is not a directory! **"
				false
			fi
		fi
		test -z "$_pre_get_eval" || eval "$_pre_get_eval"
		"$_get_func"
		test -z "$_post_get_eval" || eval "$_post_get_eval"
		touch "${_app}.DONE_GET"
	fi
}
_compile_wrap() {
	if ! test -e "${_app}.DONE_COMPILE"; then
		cd "$_app"
		test -z "$_pre_compile_eval" || eval "$_pre_compile_eval"
		"$_compile_func"
		test -z "$_post_compile_eval" || eval "$_post_compile_eval"
		cd ..
		touch "${_app}.DONE_COMPILE"
	fi
}
_install_wrap() {
	if ! test -e "${_app}.DONE_INSTALL"; then
		cd "$_app"
		test -z "$_pre_compile_eval" || eval "$_pre_compile_eval"
		"$_install_func"
		test -z "$_post_compile_eval" || eval "$_post_compile_eval"
		cd ..
		touch "${_app}.DONE_INSTALL"
	fi
}
_proc_app() {
	_get_wrap
	_compile_wrap
	_install_wrap
}

# process the recipe
echo "$_input_contents" | \
{
	while true; do
		_arg_num=1
		_get_func=
		_compile_func=
		_app=
		_extra_get_info=
		_pre_get_eval=
		_post_get_eval=
		_pre_compile_eval=
		_post_compile_eval=
		_pre_install_eval=
		_post_install_eval=
		echo "****"
		while true; do
			if ! read _ln; then
				test -z "$_app" || _proc_app
				break 2
			fi
			if test "$_ln" = "**"; then
				_arg_num=`expr $_arg_num + 1`
				continue
			fi
			if test "$_ln" = "===="; then
				test -z "$_app" || _proc_app
				break
			fi
			if test "${_ln:0:1}" = "#"; then
				continue
			fi
			case "$_arg_num" in
				1)  _app="$_ln"; echo "** _app=$_app";;
				2)  _get_func="$_ln"; echo "** _get_func=$_get_func";;
				3)  _compile_func="$_ln"; echo "** _compile_func=$_compile_func";;
				4)  _install_func="$_ln"; echo "** _install_func=$_install_func";;
				5)  _extra_get_info="$_ln"; echo "** _extra_get_info=$_extra_get_info";;
				6)  _pre_get_eval="$_ln"; echo "** _pre_get_eval=$_pre_get_eval";;
				7)  _post_get_eval="$_ln"; echo "** _post_get_eval=$_post_get_eval";;
				8)  _pre_compile_eval="$_ln"; echo "** _pre_compile_eval=$_pre_compile_eval";;
				9)  _post_compile_eval="$_ln"; echo "** _post_compile_eval=$_post_compile_eval";;
				10) _pre_install_eval="$_ln"; echo "** _pre_install_eval=$_pre_install_eval";;
				11) _post_install_eval="$_ln"; echo "** _post_install_eval=$_post_install_eval";;
				*) false;;
			esac
			_arg_num=`expr $_arg_num + 1`
		done
	done
}
