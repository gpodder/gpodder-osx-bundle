#!/bin/bash

usage="Usage: $0 /path/to/gPodder.app version_buildnumber"

source env.sh
JHBUILD_PREFIX="$HOME/gtk/inst"
mydir=`pwd`


if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
elif [ ! -d "$1" ] ; then
	echo "$usage"
	echo "$1 doesn't exist or is not a directory (give me /path/to/gPodder.app)"
else
	app="$1"
	shift
fi

if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
else
	version_buildnumber="$1"
	shift
fi

contents="${app%.app}.contents"

resources="$app"/Contents/Resources

# remove gPodder specific contents
rm     "${resources:?}"/bin/gpo*
rm -Rf "$resources"/lib/python3.6/site-packages/gpodder
rm -Rf "$resources"/share/gpodder
rm     "$resources"/share/icons/hicolor/scalable/apps/gpodder.svg
find   "$resources"/share/locale -name gpodder.mo -delete
rm     "$resources"/gPodder.icns
rm     "$app"/Contents/Info.plist

# list the provenance of every file in the bundle
"$mydir"/misc/provenance.pl "$JHBUILD_PREFIX" "$app" > "$contents"

# release the thing
"$mydir"/release.sh "$app" "$version_buildnumber".deps
