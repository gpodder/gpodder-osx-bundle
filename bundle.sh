#!/bin/sh

set -e

source env.sh

echo compiling native launcher...
echo 'gcc -L$PREFIX/lib `python3-config --cflags --ldflags --embed` -o $PREFIX/bin/gpodder-launcher misc/bundle/launcher.c'| jhbuild shell

echo creating app...
jhbuild run gtk-mac-bundler misc/bundle/gpodder.bundle

echo post-processing...
APP="$QL_OSXBUNDLE_BUNDLE_DEST/gPodder.app"
APP_PREFIX="$APP"/Contents/Resources
JHBUILD_PREFIX="$HOME/gtk/inst"
mydir=`pwd`

# change case of gPodder.app
mv "$QL_OSXBUNDLE_BUNDLE_DEST/gpodder.app" "$QL_OSXBUNDLE_BUNDLE_DEST/app.app"
mv "$QL_OSXBUNDLE_BUNDLE_DEST/app.app" "$APP"



# kill some useless files
rm -Rf "$APP_PREFIX"/lib/python3.8/test
rm -Rf "$APP_PREFIX"/lib/python3.8/unittest
rm -Rvf "$APP_PREFIX"/lib/python3.8/*/test
rm -f "$APP_PREFIX"/lib/python3.8/config/libpython3.8.a
find "$APP_PREFIX"/lib/python3.8 -name '*.pyc' -delete
find "$APP_PREFIX"/lib/python3.8 -name '*.pyo' -delete

echo checking for dynamic linking consistency : nothing should reference gtk/inst
find "$APP_PREFIX" -name '*.so' -and -print -and  -exec sh -c 'otool -L $1 | grep /gtk/inst' '{}' '{}' ';'

# make openssl option dir
mkdir -p "$APP_PREFIX/etc/openssl"


# list the provenance of every file in the bundle
$mydir/misc/provenance.pl "$JHBUILD_PREFIX" "$APP" > "$QL_OSXBUNDLE_BUNDLE_DEST"/gPodder.contents

