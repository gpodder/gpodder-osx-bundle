#!/bin/sh

set -e

source env.sh

# to allow bootstrapping again, try to delete everything first
rm -Rf "_jhbuild"
rm -Rf "_bundler"
rm -Rf "$HOME/.local"
rm -f "$HOME/.jhbuildrc"
rm -f "$HOME/.jhbuildrc-custom"

# https://git.gnome.org/browse/gtk-osx/tree/jhbuild-revision
JHBUILD_REVISION="7c8d34736c3804"

mkdir -p "$HOME"
git clone git://git.gnome.org/jhbuild _jhbuild
(cd _jhbuild && git checkout "$JHBUILD_REVISION" && ./autogen.sh && make -f Makefile.plain DISABLE_GETTEXT=1 install >/dev/null)
ln misc/gtk-osx-jhbuildrc "$HOME/.jhbuildrc"
ln misc/jhbuildrc-custom "$HOME/.jhbuildrc-custom"
git clone git://git.gnome.org/gtk-mac-bundler _bundler
(cd _bundler && make install)
