#!/bin/bash

# perform bootstrap
./bootstrap.sh

# try ./build.sh here
echo "bootstraping..."
./build.sh bootstrap

OLD_HOME=$HOME
. env.sh

rsync -ar "$OLD_HOME/.ssh" "$HOME/"
echo "$KNOWN_HOST" >> "$HOME/.ssh/known_hosts"
cat "_home/.ssh/known_hosts"
openssl aes-256-cbc -K $encrypted_66daf52526ba_key -iv $encrypted_66daf52526ba_iv -in misc/travis/gpodderbuild.enc -out ../gpodderbuild -d
chmod go-wrx ../gpodderbuild

# upload data
rsync -e "ssh -p$RSYNC_PORT -i ../gpodderbuild -o StrictHostKeyChecking=no" -avrz --exclude "$HOME/jhbuild_checkoutroot" \
	_jhbuild \
	_bundler \
	"$HOME" \
	"$RSYNC_HOME/$TRAVIS_BUILD_NUMBER/"
