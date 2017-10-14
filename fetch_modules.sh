#!/bin/sh

source env.sh

git clone git://git.gnome.org/gtk-osx _gtk-osx
cp -R _gtk-osx/modulesets-stable/. modulesets/
cp _gtk-osx/jhbuildrc-gtk-osx misc/gtk-osx-jhbuildrc
(cd _gtk-osx/ && git log -1) > modulesets/upstream-ref
rm -Rf _gtk-osx
