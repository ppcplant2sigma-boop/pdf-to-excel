#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
APK=$DIST/build/outputs/apk/debug/pdf2excel-debug.apk
ls -la $APK
rm -rf /tmp/av && mkdir -p /tmp/av && cd /tmp/av
unzip -o -q $APK
echo "== assets/private.tar =="
ls -la assets/private.tar
tar tvzf assets/private.tar | grep -E "main.pyc|engine.pyc"
echo "== libpybundle present =="
ls -la lib/arm64-v8a/libpybundle.so
echo "== copy to Downloads =="
cp $APK "/mnt/c/Users/Admin/Downloads/PDF to Excel.apk"
md5sum "/mnt/c/Users/Admin/Downloads/PDF to Excel.apk"
ls -la "/mnt/c/Users/Admin/Downloads/PDF to Excel.apk"
echo "= DONE ="