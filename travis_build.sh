#!/bin/bash
# adapted from https://stackoverflow.com/questions/26082444/how-to-work-around-travis-cis-4mb-output-limit/26082445#26082445
# Abort on Error
set -e

if [ "$1" == "--python3" ]; then
	with_python3=1
	shift
else
	with_python3=0
fi
if [ -z "$1" ]; then
	echo "Usage: $0 [--python3] <PKG> [PKG ...]"
fi

export PING_SLEEP=30s
export WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BUILD_OUTPUT=$WORKDIR/build.out

touch "$BUILD_OUTPUT"

dump_output() {
   echo "Tailing the last 500 lines of output:"
   tail -500 "$BUILD_OUTPUT"
}
error_handler() {
  echo "ERROR: An error was encountered with the build."
  dump_output
  exit 1
}
# If an error occurs, run our error handler to output a tail of the build
trap 'error_handler' ERR

# Set up a repeating loop to send some output to Travis.

bash -c "while true; do echo \$(date) - building ...; sleep $PING_SLEEP; done" &
PING_LOOP_PID=$!

# Show build steps
(tail -f "$BUILD_OUTPUT" | grep -E '\[[0-9]+/[0-9]+\]') &
TAIL=$!

./bootstrap.sh

OLD_HOME=$HOME
. env.sh

# download data
rsync -ar "$OLD_HOME/.ssh" "$HOME/"
echo "$KNOWN_HOST" >> "$HOME/.ssh/known_hosts"
openssl aes-256-cbc -K $encrypted_66daf52526ba_key -iv $encrypted_66daf52526ba_iv -in misc/travis/gpodderbuild.enc -out ../gpodderbuild -d
rsync -e "ssh -p$RSYNC_PORT -i ../gpodderbuild -o StrictHostKeyChecking=no" -arz "$RSYNC_HOME/$TRAVIS_BUILD/jhbuild_prefix" "$HOME/"



if [ "$with_python3" == 1 ]; then
	export PYTHON=$HOME/jhbuild_prefix/bin/python3
fi

while [ -n "$1" ]; do
	echo "building $1..."
	jhbuild build "$1" >> "$BUILD_OUTPUT" 2>&1
	shift
done

# The build finished without returning an error so dump a tail of the output
dump_output

# nicely terminate the ping output loop
kill "$PING_LOOP_PID"
kill "$TAIL"

# upload data
rsync -e "ssh -p$RSYNC_PORT -i ../gpodderbuild" -arz "$HOME/jhbuild_prefix" "$RSYNC_HOME/$TRAVIS_BUILD/"
