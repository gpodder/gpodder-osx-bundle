#!/bin/sh

set -e

source env.sh

jhbuild bootstrap
jhbuild build openssl
jhbuild build python3
jhbuild build meta-gtk-osx-bootstrap
jhbuild build gpodder
