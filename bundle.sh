#!/bin/sh

set -e

source env.sh

echo compiling native launcher...
echo 'clang -mmacosx-version-min=10.9 -framework Foundation -L$PREFIX/lib `python3-config --cflags --ldflags --embed` -o $PREFIX/bin/python-launcher misc/bundle/launcher.m'| jhbuild shell

echo creating app...
jhbuild run gtk-mac-bundler misc/bundle/pythonbase.bundle

echo post-processing...
APP="$QL_OSXBUNDLE_BUNDLE_DEST/pythonbase.app"
APP_PREFIX="$APP"/Contents/Resources
JHBUILD_PREFIX="$HOME/gtk/inst"
mydir=`pwd`


CMDS="run-pip run-python"
for cmd in ${CMDS}; do
    cp -a "$APP"/Contents/MacOS/{pythonbase,$cmd}
    if [ -e "$QL_OSXBUNDLE_BUNDLE_DEST/$cmd" ]; then
        unlink "$QL_OSXBUNDLE_BUNDLE_DEST/$cmd"
    fi
    ln -s $(basename "$APP")/Contents/MacOS/$cmd "$QL_OSXBUNDLE_BUNDLE_DEST/"
done

# kill some useless files
rm -Rf "$APP_PREFIX"/lib/python3.8/test
rm -Rf "$APP_PREFIX"/lib/python3.8/unittest
rm -Rvf "$APP_PREFIX"/lib/python3.8/*/test
rm -f "$APP_PREFIX"/lib/python3.8/config/libpython3.8.a
find "$APP_PREFIX"/lib/python3.8 -name '*.pyc' -delete
find "$APP_PREFIX"/lib/python3.8 -name '*.pyo' -delete

echo checking for dynamic linking consistency : nothing should reference gtk/inst
find "$APP_PREFIX" -name '*.so' -and -print -and  -exec sh -c 'otool -L $1 | grep /gtk/inst' '{}' '{}' ';'

# make openssl option dir to prevent looking into /etc
mkdir -p "$APP_PREFIX/etc/openssl"


# list the provenance of every file in the bundle
$mydir/misc/provenance.pl "$JHBUILD_PREFIX" "$APP" > "$QL_OSXBUNDLE_BUNDLE_DEST"/pythonbase.contents

