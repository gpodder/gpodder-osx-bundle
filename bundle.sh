#!/bin/sh

set -e

source env.sh

jhbuild run gtk-mac-bundler misc/bundle/gpodder.bundle

APP="$QL_OSXBUNDLE_BUNDLE_DEST/gPodder.app"
APP_PREFIX="$APP"/Contents/Resources
JHBUILD_PREFIX="$HOME/jhbuild_prefix"
mydir=`pwd`

# change case of gPodder.app
mv "$QL_OSXBUNDLE_BUNDLE_DEST/gpodder.app" "$QL_OSXBUNDLE_BUNDLE_DEST/app.app"
mv "$QL_OSXBUNDLE_BUNDLE_DEST/app.app" "$APP"

# launcher scripts
mv "$APP"/Contents/MacOS/{gPodder,gpodder}
CMDS="gpo gpodder-migrate2tres run-python"
for cmd in ${CMDS}; do
	cp -a "$APP"/Contents/MacOS/{gpodder,$cmd}
	ln -s gPodder.app/Contents/MacOS/$cmd "$QL_OSXBUNDLE_BUNDLE_DEST/"
done

# Set the version and copyright automatically (before removing *.pyc)
"$APP"/Contents/MacOS/run-python "$mydir/misc/fixup_info.py" "$APP"/Contents/Info.plist

# kill some useless files
rm -Rf "$APP_PREFIX"/lib/python3.6/test
rm -Rf "$APP_PREFIX"/lib/python3.6/unittest
rm -Rvf "$APP_PREFIX"/lib/python3.6/*/test
rm -f "$APP_PREFIX"/lib/python3.6/config/libpython3.6.a
find "$APP_PREFIX"/lib/python3.6 -name '*.pyc' -delete
find "$APP_PREFIX"/lib/python3.6 -name '*.pyo' -delete
rm -f "$APP"/Contents/MacOS/gPodder-bin
rm -Rf "$APP_PREFIX"/share/gpodder/ui/qml
rm -Rf "$APP_PREFIX"/lib/python3.6/site-packages/gpodder/{qmlui,webui}

# replace copy with symlink
# rm "$APP_PREFIX"/lib/libicudata.55.dylib
# ln -s libicudata.55.1.dylib "$APP_PREFIX"/lib/libicudata.55.dylib

# remove the check for DISPLAY variable since it's not used AND it's not
# available on Mavericks (see bug #1855)
(cd "$APP_PREFIX" && patch -p0 < "$mydir/modulesets/patches/dont_check_display.patch")

# Command-XX shortcuts in gPodder menus 
/usr/bin/xsltproc -o menus.ui.tmp "$mydir"/misc/adjust-modifiers.xsl "$APP_PREFIX"/share/gpodder/ui/gtk/menus.ui
mv menus.ui.tmp "$APP_PREFIX"/share/gpodder/ui/gtk/menus.ui

# check for dynamic linking consistency : nothing should reference gtk/inst
find "$APP_PREFIX" -name '*.so' -and -print -and  -exec sh -c 'otool -L $1 | grep /gtk/inst' '{}' '{}' ';'

# make openssl option dir
mkdir -p "$APP_PREFIX/etc/openssl"


# list the provenance of every file in the bundle
$mydir/misc/provenance.pl "$JHBUILD_PREFIX" "$APP" > "$QL_OSXBUNDLE_BUNDLE_DEST"/gPodder.contents

