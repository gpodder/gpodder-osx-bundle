#!/bin/bash

# perform bootstrap
./bootstrap.sh

# try ./build.sh here
echo "bootstraping first few packages..."
./build.sh bootstrap xz autoconf automake libtool gettext-tools readline bash cmake autoconf-archive automake-1.10 automake-1.11 automake-1.12 automake-1.13 automake-1.14 pkg-config

OLD_HOME=$HOME
. env.sh

rsync -ar "$OLD_HOME/.ssh" "$HOME/"
echo "$KNOWN_HOST" >> "$HOME/.ssh/known_hosts"
cat "_home/.ssh/known_hosts"
openssl aes-256-cbc -K $encrypted_66daf52526ba_key -iv $encrypted_66daf52526ba_iv -in misc/travis/gpodderbuild.enc -out ../gpodderbuild -d
chmod go-wrx ../gpodderbuild

# upload data
rsync -e "ssh -p$RSYNC_PORT -i ../gpodderbuild -o StrictHostKeyChecking=no" -arz \
	_jhbuild \
	_bundler \
	"$HOME" \
	"$RSYNC_HOME/$TRAVIS_BUILD_NUMBER/"
