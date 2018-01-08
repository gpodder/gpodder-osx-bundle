#!/bin/sh

set -e

source env.sh

if [ "$1" == "--python3" ]; then
	export PYTHON=$HOME/jhbuild_prefix/bin/python3
	shift
fi
if [ -z "$1" ]; then
	jhbuild bootstrap
	jhbuild build openssl
	jhbuild build python3
	# itstool will not work with python3: libxml2 doesn't compile with python3
	jhbuild build itstool
	export PYTHON=$HOME/jhbuild_prefix/bin/python3
	jhbuild build meta-gtk-osx-bootstrap
	jhbuild build gpodder
else
	echo "jhbuild $@"
	jhbuild "$@"
fi
