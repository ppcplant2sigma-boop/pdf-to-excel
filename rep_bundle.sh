#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel

cd /tmp && rm -rf nbt && mkdir nbt
tar xzf "$DIST/libs/arm64-v8a/libpybundle.so" -C nbt

rm -f /tmp/nbt/_python_bundle/site-packages/charset_normalizer/cd.cpython-314-x86_64-linux-gnu.so
rm -f /tmp/nbt/_python_bundle/site-packages/charset_normalizer/md.cpython-314-x86_64-linux-gnu.so

echo '== case-insensitive non-arm64 scan (want 0) =='
find /tmp/nbt/_python_bundle -name '*.so' -exec file {} \; | grep -iv aarch64 | grep -v 'symbolic link' || true
echo "non-arm64 count: $(find /tmp/nbt/_python_bundle -name '*.so' -exec file {} \; | grep -icv aarch64)"
echo '== charset .so present (want 0) =='
find /tmp/nbt/_python_bundle/site-packages/charset_normalizer -name '*.so' | wc -l

echo '== import test =='
python3 - <<'PY'
import sys
sys.path.insert(0, '/tmp/nbt/_python_bundle/site-packages')
import charset_normalizer
print('charset_normalizer OK', charset_normalizer.__version__)
import requests
print('requests OK', requests.__version__)
PY

cd /tmp/nbt
tar cf - _python_bundle | gzip -9 > /tmp/libpybundle_new.so
ls -la /tmp/libpybundle_new.so
cp /tmp/libpybundle_new.so "$DIST/libs/arm64-v8a/libpybundle.so"
ls -la "$DIST/libs/arm64-v8a/libpybundle.so"
echo 'BUNDLE DONE'