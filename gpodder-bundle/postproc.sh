#!/bin/sh

rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/distutils
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/idlelib
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/lib-tk
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/lib2to3
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/pydoc-data
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/test
rm -Rf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/unittest
rm -Rvf ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/*/test
rm -f ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7/config/libpython2.7.a
find ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7 -name '*.pyc' -delete
find ~/Desktop/gPodder.app/Contents/Resources/lib/python2.7 -name '*.pyo' -delete
rm ~/Desktop/gPodder.app/Contents/MacOS/gPodder-bin
