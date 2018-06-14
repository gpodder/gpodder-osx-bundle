#!/bin/sh

bundle=$(cd "$(dirname "$(dirname "$(dirname "$0")")")"; pwd)
bundle_contents="$bundle"/Contents
bundle_res="$bundle_contents"/Resources
bundle_lib="$bundle_res"/lib
bundle_bin="$bundle_res"/bin
bundle_data="$bundle_res"/share
bundle_etc="$bundle_res"/etc

export DYLD_LIBRARY_PATH="$bundle_lib"

export XDG_CONFIG_DIRS="$bundle_etc"
export XDG_DATA_DIRS="$bundle_data"

export CHARSETALIASDIR="$bundle_lib"

export GTK_DATA_PREFIX="$bundle_res"
export GTK_EXE_PREFIX="$bundle_res"
export GTK_PATH="$bundle_res"

export GTK_IM_MODULE_FILE="$bundle_etc/gtk-3.0/gtk.immodules"
export GDK_PIXBUF_MODULE_FILE="$bundle_lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"

# gobject-introspection
export GI_TYPELIB_PATH="$bundle_lib/girepository-1.0"

# Pango wants these 2 otherwise it displays square boxes instead of letters
export PANGO_SYSCONFDIR="$bundle_etc"
export PANGO_LIBDIR="$bundle_lib"

# Strip out the argument added by the OS.
if /bin/expr "x$1" : '^x-psn_' > /dev/null; then
    shift 1
fi

#Set $PYTHON to point inside the bundle
export PYTHON="$bundle_contents/MacOS/python3"
export PYTHONHOME="$bundle_res"


# select target based on our basename
APP=$(basename "$0")
if [ "$APP" == "run" ]; then
    "$PYTHON" "$@"
elif  [ "$APP" == "gst-plugin-scanner" ]; then
    # Starting with 10.11 OSX will no longer pass DYLD_LIBRARY_PATH
    # to child processes. To work around use this launcher for the
    # GStreamer plugin scanner helper
    "$bundle_res/libexec/gstreamer-1.0/gst-plugin-scanner" "$@"
else

	# Gen cert.pem
	# don't inadvertently create the new gPodder home,
	# it would be prefered to the old one
	if [ -e "$GPODDER_HOME" ] ; then
		gphome=$GPODDER_HOME
	elif [ -e ~/Library/Application\ Support/gPodder ] ; then
		gphome=~/Library/Application\ Support/gPodder
	elif [ -e ~/gPodder ] ; then
		gphome=~/gPodder
	else
		gphome=~/Library/Application\ Support/gPodder
	fi
	mkdir -p "$gphome/openssl"
	# generate cert.extracted.pem
	cert_gen=$gphome/openssl/cert.extracted.pem
	cert_pem=$gphome/openssl/cert.pem
	if test ! -f "$cert_gen" || /usr/bin/find "$cert_gen" -mtime +7 | /usr/bin/egrep -q .; then
		echo "(Re)generating" "$cert_pem"
		openssl=$bundle_bin/openssl
		make_cert_pem=$bundle_bin/make_cert_pem.py
		"$PYTHON" "$make_cert_pem" "$openssl" "$cert_gen"
	else
		echo "No regenerating $cert_gen: it's fresh enough"
	fi
	# and link to it by default. Users may want to point cert.pem to MacPorts
	# /opt/local/etc/openssl/cert.pem, for instance.
	if test ! -e "$cert_pem" ; then
		ln -s "$(basename "$cert_gen")" "$cert_pem"
	fi
	#Set path to CA files
	export SSL_CERT_FILE=$cert_pem

    "$PYTHON" "$bundle_contents/Resources/bin/$APP" "$@"
fi
