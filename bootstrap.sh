#!/bin/sh

set -e

source env.sh

# to allow bootstrapping again, try to delete everything first
rm -Rf "_gtk-osx"
rm -Rf "_bundler"
rm -Rf "$HOME/.newlocal"
rm -f "$HOME/.config/jhbuildrc"
rm -f "$HOME/.config/jhbuildrc-custom"

mkdir -p "$HOME/.config"
cp misc/jhbuildrc-custom "$HOME/.config/jhbuildrc-custom"
git clone  https://gitlab.gnome.org/GNOME/gtk-osx.git _gtk-osx
# try latest commit
(cd _gtk-osx && git checkout 357671e5)
# fix boostrap failure: error message on pip download
sed -i '' s,https://bootstrap.pypa.io/2.7/get-pip.py,https://bootstrap.pypa.io/pip/2.7/get-pip.py, _gtk-osx/gtk-osx-setup.sh
yes | ./_gtk-osx/gtk-osx-setup.sh
git clone https://gitlab.gnome.org/GNOME/gtk-mac-bundler.git _bundler
(cd _bundler && make install bindir=$HOME/.new_local/bin)
