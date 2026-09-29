#!/bin/bash
set -e
HP=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/build/other_builds/hostpython3/desktop/hostpython3/native-build/python
echo "== hostpython ==" ; "$HP" -V 2>&1 | head -1

ls -la /home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel/ 2>/dev/null
echo "== assets =="
ls -la /home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel/assets/ 2>/dev/null
echo "== find private.tar =="
find /home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists -name '*.tar' -o -name 'private*' 2>/dev/null | head -20