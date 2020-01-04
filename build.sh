#!/bin/sh

set -e

source env.sh

jhbuild bootstrap-gtk-osx
jhbuild build meta-gtk-osx-bootstrap
jhbuild build gpodder
