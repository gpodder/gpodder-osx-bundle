import os
import platform
import re
import runpy
import sys
from os.path import basename, dirname, join


# print("launcher.py sys.argv=", sys.argv)
bundlepath = sys.argv.pop(0)
app = basename(sys.argv[0])

bundle_contents = join(bundlepath, 'Contents')
bundle_res = join(bundle_contents, 'Resources')

bundle_lib = join(bundle_res, 'lib')
bundle_bin = join(bundle_res, 'bin')
bundle_data = join(bundle_res, 'share')
bundle_etc = join(bundle_res, 'etc')

os.environ['CHARSETALIASDIR'] = bundle_lib
os.environ['DYLD_LIBRARY_PATH'] = bundle_lib
os.environ['GTK_DATA_PREFIX'] = bundle_res
os.environ['GTK_EXE_PREFIX'] = bundle_res
os.environ['GTK_PATH'] = bundle_res
os.environ['LD_LIBRARY_PATH'] = bundle_lib
os.environ['XDG_CONFIG_DIRS'] = bundle_etc
os.environ['XDG_DATA_DIRS'] = bundle_data

os.environ['PANGO_LIBDIR'] = bundle_lib
os.environ['PANGO_RC_FILE'] = join(bundle_etc, 'pango', 'pangorc')
os.environ['PANGO_SYSCONFDIR'] = bundle_etc
os.environ['GDK_PIXBUF_MODULE_FILE'] = join(bundle_lib, 'gdk-pixbuf-2.0',
                                                '2.10.0', 'loaders.cache')
if int(platform.release().split('.')[0]) > 10:
    os.environ['GTK_IM_MODULE_FILE'] = join(bundle_etc, 'gtk-3.0',
                                            'gtk.immodules')

os.environ['GI_TYPELIB_PATH'] = join(bundle_lib, 'girepository-1.0')

# for forked python
os.environ['PYTHONHOME'] = bundle_res
#Set $PYTHON to point inside the bundle
PYVER = 'python3.9'
sys.path.append(bundle_res)
print('System Path:\n','\n'.join(sys.path))

for k, v in os.environ.items():
  print("%s=%s" % (k,v))

python_exe = join(bundle_contents, 'MacOS', 'python3')

if app == 'run-python':
    # executable is repeated as argv[0].
    # Old sys.argv[0] points to Contents/MacOS so must be removed
    args = [python_exe] + sys.argv[1:]
    # print("running", args)
    os.execv(python_exe, args)
elif app == 'run-pip':
    pip = join(bundle_contents, 'Resources', 'bin', 'pip3')
    # executable is repeated as argv[0].
    # Old sys.argv[0] points to Contents/MacOS so must be removed
    args = [python_exe, pip] + sys.argv[1:]
    # print("running", args)
    os.execv(python_exe, args)
else:
    import runpy
    runpy.run_path(join(bundle_bin, app), run_name='__main__')
