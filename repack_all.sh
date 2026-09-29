#!/bin/bash
set -e
HP=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/build/other_builds/hostpython3/desktop/hostpython3/native-build/python
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel

echo "== 1. compile new pyc with device-matching interpreter =="
rm -rf /tmp/pycwork /tmp/tarsrc && mkdir -p /tmp/pycwork /tmp/tarsrc
"$HP" -c "import py_compile; py_compile.compile('/home/admin1234/PDF2Excel/main.py', cfile='/tmp/pycwork/main.pyc', doraise=True)"
"$HP" -c "import py_compile; py_compile.compile('/home/admin1234/PDF2Excel/engine.py', cfile='/tmp/pycwork/engine.pyc', doraise=True)"

echo "-- magic new engine.pyc:"; xxd -l 4 /tmp/pycwork/engine.pyc
echo "-- magic old  engine.pyc:"; tar xOf $DIST/src/main/assets/private.tar engine.pyc | xxd -l 4

echo "== 2. rebuild private.tar (overlay new pyc onto old contents) =="
tar xOf $DIST/src/main/assets/private.tar sitecustomize.pyc  > /tmp/tarsrc/sitecustomize.pyc
tar xOf $DIST/src/main/assets/private.tar p4a_env_vars.txt  > /tmp/tarsrc/p4a_env_vars.txt
cp /tmp/pycwork/main.pyc    /tmp/tarsrc/main.pyc
cp /tmp/pycwork/engine.pyc  /tmp/tarsrc/engine.pyc
cd /tmp/tarsrc && tar cf private.tar main.pyc engine.pyc sitecustomize.pyc p4a_env_vars.txt
ls -la /tmp/tarsrc/private.tar
cp /tmp/tarsrc/private.tar $DIST/src/main/assets/private.tar
echo "new private.tar bytes: $(stat -c%s /tmp/tarsrc/private.tar) (old was 21287)"

echo "== 3. purge all x86_64 native-only packages (never imported at runtime) =="
cd /tmp/bt/_python_bundle/site-packages
rm -rf pymupdf fitz pymupdf-1.28.2.dist-info \
       charset_normalizer charset_normalizer-3.5.1.dist-info \
       chardet chardet-7.6.0.dist-info \
       7cf47097c39cf1afcee8__mypyc.so
ls -d pymupdf fitz charset_normalizer chardet 2>/dev/null || echo "x86 packages removed"

echo "== 4. verify ALL native .so are aarch64 (reject x86_64) =="
python3 - <<'PY'
import glob, struct, os
bad = []
for path in glob.glob("/tmp/bt/_python_bundle/site-packages/**/*.so", recursive=True) + glob.glob("/tmp/bt/_python_bundle/modules/*.so"):
    try:
        with open(path, "rb") as f:
            f.seek(18)
            em = struct.unpack("<H", f.read(2))[0]
        if em != 183:  # EM_AARCH64
            bad.append((path, em))
    except Exception as e:
        bad.append((path, "ERR:" + str(e)))
if bad:
    for b in bad:
        print("BAD:", b)
    exit(1)
else:
    print("ALL .so are AARCH64 (ok)")
PY

echo "== 5. purge stray __pycache__ =="
find /tmp/bt/_python_bundle -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

echo "== 6. repack libpybundle.so =="
cd /tmp/bt
rm -f /tmp/libpybundle_new.so
tar cf - _python_bundle | gzip -9 > /tmp/libpybundle_new.so
ls -la /tmp/libpybundle_new.so
cp /tmp/libpybundle_new.so $DIST/libs/arm64-v8a/libpybundle.so
echo "dist libpybundle.so: $(stat -c%s $DIST/libs/arm64-v8a/libpybundle.so) bytes"
echo "= PACKAGE DONE ="