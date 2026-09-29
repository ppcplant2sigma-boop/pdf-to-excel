#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
OVER=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/build/python-installs/pdf2excel/arm64-v8a

echo '== charset .so files =='
find "$OVER/charset_normalizer" -name '*.so'
echo '== arch =='
find "$OVER/charset_normalizer" -name '*.so' -exec file {} \;

cd /tmp && rm -rf nbt && mkdir nbt
tar xzf "$DIST/libs/arm64-v8a/libpybundle.so" -C nbt

cp -r "$OVER/charset_normalizer" nbt/_python_bundle/site-packages/
cp -r "$OVER/charset_normalizer-3.5.1.dist-info" nbt/_python_bundle/site-packages/

cd /tmp/nbt
tar cf - _python_bundle | gzip -9 > /tmp/libpybundle_new.so
ls -la /tmp/libpybundle_new.so

echo '== non-aarch64 .so scan (expect 0) =='
find /tmp/nbt/_python_bundle -name '*.so' -exec file {} \; | grep -v AArch64 | grep -v 'symbolic link' | wc -l

echo '== gzip tar test =='
tar tvzf /tmp/libpybundle_new.so --wildcards '*charset_normalizer*' | head -4

cp /tmp/libpybundle_new.so "$DIST/libs/arm64-v8a/libpybundle.so"
echo '== widevine? show new size =='
ls -la "$DIST/libs/arm64-v8a/libpybundle.so"
echo 'NEW BUNDLE DONE'