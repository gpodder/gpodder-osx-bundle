#!/bin/sh

set -e

source env.sh

echo compiling native launcher...
echo 'gcc -L$PREFIX/lib `python-config --cflags --ldflags` -o $PREFIX/bin/gpodder-launcher misc/bundle/launcher.c'| jhbuild shell

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

# launcher scripts
mv "$APP"/Contents/MacOS/{gPodder,gpodder}
CMDS="gpo gpodder-migrate2tres run-python"
for cmd in ${CMDS}; do
    cp -a "$APP"/Contents/MacOS/{gpodder,$cmd}
    if [ -e "$QL_OSXBUNDLE_BUNDLE_DEST/$cmd" ]; then
        unlink "$QL_OSXBUNDLE_BUNDLE_DEST/$cmd"
    fi
    ln -s gPodder.app/Contents/MacOS/$cmd "$QL_OSXBUNDLE_BUNDLE_DEST/"
done

# Set the version and copyright automatically (before removing *.pyc)
"$APP"/Contents/MacOS/run-python "$mydir/misc/fixup_info.py" "$APP"/Contents/Info.plist

# kill some useless files
rm -Rf "$APP_PREFIX"/lib/python3.8/test
rm -Rf "$APP_PREFIX"/lib/python3.8/unittest
rm -Rvf "$APP_PREFIX"/lib/python3.8/*/test
rm -f "$APP_PREFIX"/lib/python3.8/config/libpython3.8.a
find "$APP_PREFIX"/lib/python3.8 -name '*.pyc' -delete
find "$APP_PREFIX"/lib/python3.8 -name '*.pyo' -delete

# remove the check for DISPLAY variable since it's not used AND it's not
# available on Mavericks (see bug #1855)
(cd "$APP_PREFIX" && patch -p0 < "$mydir/modulesets/patches/gpodder_dont_check_display.patch")

# Command-XX shortcuts in gPodder menus 
/usr/bin/xsltproc -o menus.ui.tmp "$mydir"/misc/adjust-modifiers.xsl "$APP_PREFIX"/share/gpodder/ui/gtk/menus.ui
mv menus.ui.tmp "$APP_PREFIX"/share/gpodder/ui/gtk/menus.ui

echo checking for dynamic linking consistency : nothing should reference gtk/inst
find "$APP_PREFIX" -name '*.so' -and -print -and  -exec sh -c 'otool -L $1 | grep /gtk/inst' '{}' '{}' ';'

# make openssl option dir
mkdir -p "$APP_PREFIX/etc/openssl"


# list the provenance of every file in the bundle
$mydir/misc/provenance.pl "$JHBUILD_PREFIX" "$APP" > "$QL_OSXBUNDLE_BUNDLE_DEST"/gPodder.contents

