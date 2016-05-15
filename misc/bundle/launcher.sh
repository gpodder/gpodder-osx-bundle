#!/bin/sh

bundle="$(dirname "$(dirname "$(dirname "$0")")")"
bundle_contents="$bundle"/Contents
bundle_res="$bundle_contents"/Resources
bundle_lib="$bundle_res"/lib
bundle_bin="$bundle_res"/bin
bundle_data="$bundle_res"/share
bundle_etc="$bundle_res"/etc

export DYLD_LIBRARY_PATH="$bundle_lib"

export XDG_CONFIG_DIRS="$bundle_etc"/xdg
export XDG_DATA_DIRS="$bundle_data"
export GTK_DATA_PREFIX="$bundle_res"
export GTK_EXE_PREFIX="$bundle_res"
export GTK_PATH="$bundle_res"

export GTK2_RC_FILES="$bundle_etc/gtk-2.0/gtkrc"
export GTK_IM_MODULE_FILE="$bundle_etc/gtk-2.0/gtk.immodules"
export GDK_PIXBUF_MODULE_FILE="$bundle_lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"

# Pango wants these 2 otherwise it displays square boxes instead of letters
export PANGO_SYSCONFDIR="$bundle_etc"
export PANGO_LIBDIR="$bundle_lib"

# Strip out the argument added by the OS.
if /bin/expr "x$1" : '^x-psn_' > /dev/null; then
    shift 1
fi

#Set $PYTHON to point inside the bundle
export PYTHON="$bundle_contents/MacOS/python"
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
    "$PYTHON" "$bundle_contents/Resources/bin/$APP" "$@"
fi
