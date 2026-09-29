#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
rm -rf /tmp/plychk && mkdir -p /tmp/plychk
cd /tmp/plychk && tar xzf $DIST/libs/arm64-v8a/libpybundle.so
ls /tmp/plychk/_python_bundle/site-packages | grep -i "plyer" || echo "PLYER MISSING"
echo "---"
ls /tmp/plychk/_python_bundle/site-packages/plyer/ 2>/dev/null | head -20