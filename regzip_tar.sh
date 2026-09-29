#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
cd /tmp && rm -rf pt && mkdir -p pt
tar xf $DIST/src/main/assets/private.tar -C pt
cd /tmp/pt
tar czf /tmp/private_new.tar.gz main.pyc engine.pyc sitecustomize.pyc p4a_env_vars.txt
cp /tmp/private_new.tar.gz $DIST/src/main/assets/private.tar
echo "== verify gzip tar =="
tar tvzf $DIST/src/main/assets/private.tar
echo "== magic check inside new tar =="
tar xOzqf $DIST/src/main/assets/private.tar engine.pyc | xxd -l 4
ls -la $DIST/src/main/assets/private.tar