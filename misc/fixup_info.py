#!/usr/bin/env python

"""Insert VERSION and COPYRIGHT in Info.plist"""

import sys
import gpodder

def main(argv):
    # fixup_info.py Info.plist "3.8.5"
    
    print("Version is %s" % (gpodder.__version__))
    with open(argv[1], "rb") as h:
        data = h.read()

    data = data.replace(b"@VERSION@", gpodder.__version__.encode('utf8'))
    data = data.replace(b"@COPYRIGHT@", gpodder.__copyright__.encode('utf8'))

    with open(argv[1], "wb") as h:
        h.write(data)

if __name__ == "__main__":
    main(sys.argv)
