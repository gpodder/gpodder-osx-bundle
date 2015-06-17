#!/bin/sh

set -e

usage="Usage: $0 /path/to/gPodder.app version_buildnumber"

if [ -z "$1" ] ; then
	echo $usage
	exit -1
elif [ ! -d "$1" ] ; then
	echo $usage
	echo "$1 doesn't exist or is not a directory (give me /path/to/Quodlibet.app)"
else
	app=$1
	shift
fi

if [ -z "$1" ] ; then
	echo $usage
	exit -1
else
	version=$1
	shift
fi

d=$(dirname "$app")
zip=$(basename "${app%.app}-$version.zip")
contents=$(basename "${app%.app}.contents")
cd "$d"
if [ -f "$zip" ] ; then
	echo "$d/$zip already exists!"
	exit -1
fi
echo "Creating $d/$zip..."
zip -rq "$zip" $(basename "$app") "$contents"

echo "Checksumming..."
shasum -a256 "$zip" > "$zip.sha256"
md5 "$zip" > "$zip.md5"

echo "Done"
