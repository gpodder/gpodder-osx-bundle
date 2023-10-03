#!/bin/sh

git clone https://gitlab.gnome.org/GNOME/gtk-osx.git _gtk-osx-modules
rsync -vrb --delete --exclude gpodder.modules --exclude patches/gpodder* _gtk-osx-modules/modulesets-stable/ modulesets/
rsync -vrb --delete _gtk-osx-modules/patches modulesets/
(cd _gtk-osx-modules/ && git log -1) > modulesets/upstream-ref
rm -Rf _gtk-osx-modules

# Disable check for brotli when building freetype
(cd modulesets && patch -p1 < ../github-brotli.patch)
