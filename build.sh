#!/bin/sh

set -e

source env.sh

jhbuild bootstrap
jhbuild build openssl
jhbuild build python3
# itstool will not work with python3: libxml2 doesn't compile with python3
jhbuild build itstool
export PYTHON=$HOME/jhbuild_prefix/bin/python3
jhbuild build meta-gtk-osx-bootstrap
jhbuild build gpodder
