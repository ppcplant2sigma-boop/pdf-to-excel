#!/bin/bash
set -e
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
echo "== dist artifacts =="
ls -la $DIST/libs/arm64-v8a/libpybundle.so $DIST/src/main/assets/private.tar
echo "== re-extract libpybundle.so =="
rm -rf /tmp/bt2 && mkdir -p /tmp/bt2
cd /tmp/bt2 && tar xzf $DIST/libs/arm64-v8a/libpybundle.so
ls -la /tmp/bt2/
echo "== bundle content check =="
ls /tmp/bt2/_python_bundle/site-packages | grep -iE "pymupdf|fitz|chardet|charset_normalizer" || echo "NO x86 packages (good)"
echo "== native .so arch scan =="
python3 - <<'PY'
import glob, struct
bad = []
for path in glob.glob("/tmp/bt2/_python_bundle/site-packages/**/*.so", recursive=True) + glob.glob("/tmp/bt2/_python_bundle/modules/*.so"):
    with open(path, "rb") as f:
        f.seek(18)
        em = struct.unpack("<H", f.read(2))[0]
    if em != 183:
        bad.append((path, em))
print("BAD .so count:", len(bad))
for b in bad[:10]:
    print("  BAD:", b)
PY
echo "== patched pdfminer check =="
grep -c "_ensure_crypto" /tmp/bt2/_python_bundle/site-packages/pdfminer/pdfdocument.py
echo "== private.tar check =="
tar tvzf $DIST/src/main/assets/private.tar
echo "= VERIFY DONE ="