#!/bin/sh

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "$DIR"

# reset `$PATH` to defaults to make sure there are no non-standard
# binaries available, e.g. from homebrew
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

export HOME="$DIR/_home"
export PATH="$PATH:$HOME/.local/bin:$HOME/jhbuild_prefix/bin"
export QL_OSXBUNDLE_MODULESETS_DIR="$DIR/modulesets"
export QL_OSXBUNDLE_BUNDLE_DEST="$DIR/_build"
alias jhbuild="python2.7 `which jhbuild`"
