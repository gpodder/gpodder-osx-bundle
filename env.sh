#!/bin/sh

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "$DIR"

# reset `$PATH` to defaults to make sure there are no non-standard
# binaries available, e.g. from homebrew
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# java is unnecessary for gpodder; but some packages check for its
# presence at configuration step; on OSX, if java is not installed,
# an annoying dialog appears => to avoid that, we alias java-related
# commands to return an error exit code
export PATH="$DIR/fake_java:$PATH"

export HOME="$DIR/_home"
export PATH="$PATH:$HOME/.local/bin:$HOME/jhbuild_prefix/bin"
export QL_OSXBUNDLE_MODULESETS_DIR="$DIR/modulesets"
export QL_OSXBUNDLE_BUNDLE_DEST="$DIR/_build"

alias jhbuild="$(which python2.7 || which python2.6) $(which jhbuild)"
