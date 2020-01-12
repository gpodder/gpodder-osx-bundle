#!/bin/sh

git clone https://gitlab.gnome.org/GNOME/gtk-osx.git _gtk-osx-modules
rsync -vrb --delete --exclude gpodder.modules --exclude patches/gpodder* _gtk-osx-modules/modulesets-stable/ modulesets/
(cd _gtk-osx-modules/ && git log -1) > modulesets/upstream-ref
rm -Rf _gtk-osx-modules
