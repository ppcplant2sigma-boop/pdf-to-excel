#!/bin/bash
set -e
HP=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/build/other_builds/hostpython3/desktop/hostpython3
"$HP" -V

# recompile main.py and engine.py with the SAME interpreter the device uses
cd /home/admin1234/PDF2Excel
mkdir -p /tmp/pycwork
rm -rf /tmp/pycwork/* && mkdir -p /tmp/pycwork

"$HP" -c "import py_compile,sys; py_compile.compile('/home/admin1234/PDF2Excel/main.py', cfile='/tmp/pycwork/main.pyc', doraise=True)"
"$HP" -c "import py_compile; py_compile.compile('/home/admin1234/PDF2Excel/engine.py', cfile='/tmp/pycwork/engine.pyc', doraise=True)"
ls -la /tmp/pycwork/

# show magic bytes to compare with existing private.tar entries
echo "--- magic of new engine.pyc:"
xxd -l 8 /tmp/pycwork/engine.pyc
echo "--- magic of OLD dist private.tar engine.pyc:"
tar xOf /home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel/assets/private.tar engine.pyc 2>/dev/null | xxd -l 8 || true