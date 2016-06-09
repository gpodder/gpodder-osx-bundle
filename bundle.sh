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
mv "$APP"/Contents/MacOS/{gPodder,_launcher}
(cd "$APP"/Contents/MacOS/ && ln -s _launcher gpodder)
(cd "$APP"/Contents/MacOS/ && ln -s _launcher gpodder-migrate2tres)
(cd "$APP"/Contents/MacOS/ && ln -s _launcher run)

# Set the version and copyright automatically (before removing *.pyc)
"$APP"/Contents/MacOS/run "$mydir/misc/fixup_info.py" "$APP"/Contents/Info.plist

# kill some useless files
rm -Rf "$APP_PREFIX"/lib/python2.7/test
rm -Rf "$APP_PREFIX"/lib/python2.7/unittest
rm -Rvf "$APP_PREFIX"/lib/python2.7/*/test
rm -f "$APP_PREFIX"/lib/python2.7/config/libpython2.7.a
find "$APP_PREFIX"/lib/python2.7 -name '*.pyc' -delete
find "$APP_PREFIX"/lib/python2.7 -name '*.pyo' -delete
rm -f "$APP"/Contents/MacOS/gPodder-bin
rm -Rf "$APP_PREFIX"/share/gpodder/ui/qml
rm -Rf "$APP_PREFIX"/lib/python2.7/site-packages/gpodder/{qmlui,webui}

# replace copy with symlink
# rm "$APP_PREFIX"/lib/libicudata.55.dylib
# ln -s libicudata.55.1.dylib "$APP_PREFIX"/lib/libicudata.55.dylib

# remove the check for DISPLAY variable since it's not used AND it's not
# available on Mavericks (see bug #1855)
(cd "$APP_PREFIX" && patch -p0 < "$mydir/modulesets/patches/dont_check_display.patch")

# Command-XX shortcuts in gPodder menus 
/usr/bin/xsltproc -o gpodder.ui.tmp $mydir/misc/adjust-modifiers.xsl "$APP_PREFIX"/share/gpodder/ui/gtk/gpodder.ui
mv gpodder.ui.tmp "$APP_PREFIX"/share/gpodder/ui/gtk/gpodder.ui

# localization of Quit and other menu items controlled by gtk-mac-integration
cp -R "$JHBUILD_PREFIX"/share/strings/*.lproj "$APP_PREFIX"

# check for dynamic linking consistency : nothing should reference gtk/inst
find "$APP_PREFIX" -name '*.so' -and -print -and  -exec sh -c 'otool -L $1 | grep /gtk/inst' '{}' '{}' ';'

# copy macports certs.pem (only temporary fix)
mkdir -p "$APP_PREFIX/etc/openssl/"
cp /opt/local/etc/openssl/cert.pem "$APP_PREFIX/etc/openssl/"


# list the provenance of every file in the bundle
$mydir/misc/provenance.pl "$JHBUILD_PREFIX" "$APP" > "$QL_OSXBUNDLE_BUNDLE_DEST"/gPodder.contents

