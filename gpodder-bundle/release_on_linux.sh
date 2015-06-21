#!/bin/bash

# directory where the generated app and zip will end in
workspace=/tmp

usage="Usage: $0 /path/to/gpodder-x.y.z_w.deps.zip /path/to/gPodder/checkout version buildnumber"

if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
elif [ ! -f "$1" ] ; then
	echo "$usage"
	echo
	echo "E: deps not found: $1 doesn't exist"
	echo "   get them from https://sourceforge.net/projects/gpodder/files/macosx/"
	exit -1
else
	deps="$1"
	shift
fi


if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
elif [ ! -d "$1"/.git ] ; then
	echo "$usage"
	echo
	echo "E: gPodder checkout not found: $1/.git doesn't exist"
	echo "   git clone https://github.com/gpodder/gpodder.git \"${1}\""
	exit -1
else
	checkout="$1"
	shift
fi

if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
else
	version="$1"
	shift
fi

if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
else
	build="$1"
	shift
fi

set -x

me=$(readlink -e "$0")
mydir=$(dirname "$me")

app="$workspace"/gPodder.app

resources="$app"/Contents/Resources

mkdir -p "$workspace"
rm -Rf "$app"
cd "$workspace"
unzip "$deps"

if [ ! -e "$app" ] ; then
	echo "E: unzipping deps didn't generate $app"
	exit -1
fi

cd "$checkout"
export GPODDER_INSTALL_UIS="cli gtk"
make install DESTDIR="$resources/" PREFIX=

find "$app" -name '*.pyc' -delete
find "$app" -name '*.pyo' -delete
rm -Rf "$resources"/lib/python2.7/site-packages/gpodder/webui
rm -Rf "$resources"/share/applications
rm -Rf "$resources"/share/dbus-1

# remove the check for DISPLAY variable since it's not used AND it's not
# available on Mavericks (see bug #1855)
(cd "$resources" && patch -p0 < "$mydir"/dont_check_display.patch)

# Command-XX shortcuts in gPodder menus 
/usr/bin/xsltproc -o gpodder.ui.tmp "$mydir"/adjust-modifiers.xsl "$resources"/share/gpodder/ui/gtk/gpodder.ui
mv gpodder.ui.tmp "$resources"/share/gpodder/ui/gtk/gpodder.ui

# Set the version and copyright automatically 
/usr/bin/xsltproc -o "$app"/Contents/Info.plist --stringparam version "$version"  "$mydir"/info-plist.xsl "$mydir"/Info-gpodder.plist

# Copy the latest icons
cp "$checkout"/tools/mac-osx/icon.icns "$resources"/gPodder.icns

# release the thing
"$mydir"/release.sh "$app" "${version}_${build}"