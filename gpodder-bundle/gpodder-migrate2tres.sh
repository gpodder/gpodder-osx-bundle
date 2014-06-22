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

#Note that we're calling $PYTHON here to override the version in
#gpodder-migrate2tres's shebang.
$EXEC $PYTHON "$bundle_contents/Resources/bin/gpodder-migrate2tres"
