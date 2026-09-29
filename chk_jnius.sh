#!/bin/bash
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
cd /tmp && rm -rf jchk && mkdir jchk && cd jchk
tar xzf $DIST/libs/arm64-v8a/libpybundle.so
echo "== jnius =="
ls _python_bundle/site-packages/ | grep -i "jnius\|android"
echo "== android pkg contents =="
ls _python_bundle/site-packages/android/ 2>/dev/null