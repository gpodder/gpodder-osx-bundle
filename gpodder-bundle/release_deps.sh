#!/bin/bash -x

usage="Usage: $0 /path/to/gPodder.app version_buildnumber"

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

me=$(readlink -e "$0")
mydir=$(dirname "$me")

resources="$app"/Contents/Resources

# remove gPodder specific contents
rm -Rf "${resources:?}"/bin/*
rm -Rf "$resources"/lib/python2.7/site-packages/gpodder
rm -Rf "$resources"/share/gpodder
rm     "$resources"/share/icons/hicolor/scalable/apps/gpodder.svg
find   "$resources"/share/locale -name gpodder.mo -delete
rm     "$resources"/gPodder.icns
rm     "$app"/Contents/Info.plist

# list the provenance of every file in the bundle
"$mydir"/provenance.pl "$app" > "$contents"

# release the thing
"$mydir"/release.sh "$app" "$version_buildnumber".deps
