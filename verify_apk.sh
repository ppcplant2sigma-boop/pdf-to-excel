#!/bin/bash
set -e
DIST="${1:-$HOME/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel}"
APK=$DIST/build/outputs/apk/debug/pdf2excel-debug.apk
ls -la $APK
cd /tmp && rm -rf apkx && mkdir -p apkx && cd apkx
unzip -o -q $APK
echo "== key entries =="
ls -la assets/private.tar lib/arm64-v8a/libpybundle.so
echo "== native libs in APK =="
ls lib/arm64-v8a/ | head -40
echo "== private.tar (from APK) =="
tar tvzf assets/private.tar
echo "== extract libpybundle.so from APK and rescan arch =="
mkdir -p bt3 && cd bt3 && tar xzf ../lib/arm64-v8a/libpybundle.so
python3 - <<'PY'
import glob, struct
bad = []
for path in glob.glob("/tmp/apkx/bt3/_python_bundle/site-packages/**/*.so", recursive=True) + glob.glob("/tmp/apkx/bt3/_python_bundle/modules/*.so"):
    with open(path, "rb") as f:
        f.seek(18)
        em = struct.unpack("<H", f.read(2))[0]
    if em != 183:
        bad.append((path, em))
print("non-aarch64 .so:", len(bad))
for b in bad[:10]:
    print("  BAD:", b)
PY
echo "== no x86 packages =="
ls /tmp/apkx/bt3/_python_bundle/site-packages | grep -iE "pymupdf|fitz|chardet|charset_normalizer|cryptography" || echo "none (good)"
echo "== engine.pyc new? (compile date magic 3.14) =="
tar xOzf assets/private.tar engine.pyc | xxd -l 4
echo "= APK VERIFY DONE ="