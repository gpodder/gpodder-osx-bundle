#!/bin/sh

set -e

source env.sh
source pins.sh

# to allow bootstrapping again, try to delete everything first
rm -Rf "_gtk-osx"
rm -Rf "_bundler"
rm -Rf "$HOME/.newlocal"
rm -f "$HOME/.config/jhbuildrc"
rm -f "$HOME/.config/jhbuildrc-custom"

mkdir -p "$HOME/.config"
cp misc/jhbuildrc-custom "$HOME/.config/jhbuildrc-custom"

git clone https://gitlab.gnome.org/GNOME/gtk-osx.git _gtk-osx
(cd _gtk-osx && git checkout $PIN_GTK_OSX_COMMIT)
# don't silence curl errors when bootstrapping
sed -i '' 's:curl -ks :curl -ksS :' _gtk-osx/gtk-osx-setup.sh
./_gtk-osx/gtk-osx-setup.sh

git clone https://gitlab.gnome.org/GNOME/gtk-mac-bundler.git _bundler
(cd _bundler && git checkout $PIN_GTK_MAC_BUNDLER_COMMIT)
(cd _bundler && make install bindir=$HOME/.new_local/bin)
