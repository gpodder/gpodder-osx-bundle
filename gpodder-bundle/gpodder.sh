#!/bin/sh

name=`basename "$0"`
tmp="$0"
tmp=`dirname "$tmp"`
tmp=`dirname "$tmp"`
bundle=`dirname "$tmp"`
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
export GDK_PIXBUF_MODULE_FILE="$bundle_etc/gtk-2.0/gdk-pixbuf.loaders"
export PANGO_RC_FILE="$bundle_etc/pango/pangorc"

#Set $PYTHON to point inside the bundle
export PYTHON="$bundle_contents/MacOS/python"
#Add the bundle's python modules
PYTHONPATH="$bundle_lib/python2.7:$PYTHONPATH"
PYTHONPATH="$bundle_lib/python2.7/site-packages:$PYTHONPATH"
#Add our program's modules to $PYTHONPATH. 
PYTHONPATH="$bundle_lib/python2.7/gtk-2.0:$PYTHONPATH"
export PYTHONPATH
echo "PYTHONPATH=$PYTHONPATH"
PYTHONHOME="$bundle_res"
export PYTHONHOME

# Strip out the argument added by the OS.
if /bin/expr "x$1" : "x-psn_.*" > /dev/null; then
    shift 1
fi

# use launchctl to load the session dbus if not already started by the session
if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
    if test ! -f $bundle_res/var/lib/dbus/machine-id ; then
        echo generating dbus machine id
        mkdir -p $bundle_res/var/lib/dbus
        $bundle_bin/dbus-uuidgen --ensure=$bundle_res/var/lib/dbus/machine-id
    fi
    plist="$bundle_res"/Library/LaunchAgents/org.freedesktop.dbus-session.plist
    daemon_path="$bundle_res"/bin/dbus-daemon
    if ! grep -q $daemon_path "$plist" ; then
        echo rewritting plist
        /usr/bin/sed "s,@BUNDLE_RES@,$bundle_res," $plist.in > $plist
    fi
    echo launching session dbus
    launchctl load $bundle_res/Library/LaunchAgents/org.freedesktop.dbus-session.plist
fi

#Note that we're calling $PYTHON here to override the version in
#pygtk-demo's shebang.
$EXEC $PYTHON "$bundle_contents/Resources/bin/gpodder" "-v"

# unload the session dbus on exit 
if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
    echo unlaunch session dbus
    launchctl unload $bundle_res/Library/LaunchAgents/org.freedesktop.dbus-session.plist
fi
