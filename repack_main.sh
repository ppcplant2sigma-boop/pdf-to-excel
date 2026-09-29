#!/bin/bash
set -e
HP=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/build/other_builds/hostpython3/desktop/hostpython3/native-build/python
DIST=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel

cp '/mnt/e/C14 PPC/New folder/PDF2Excel/main.py' /home/admin1234/PDF2Excel/main.py
python3 - <<'PY'
import ast
ast.parse(open('/home/admin1234/PDF2Excel/main.py').read())
print('main updated + syntax OK')
PY

echo "== compile main.pyc (engine.pyc reused unchanged) =="
"$HP" -c "import py_compile; py_compile.compile('/home/admin1234/PDF2Excel/main.py', cfile='/tmp/pycwork/main.pyc', doraise=True)"
echo "magic:"; xxd -l 4 /tmp/pycwork/main.pyc

echo "== rebuild private.tar (gzip): new main + existing engine =="
cd /tmp && rm -rf pt && mkdir -p pt
tar xzf $DIST/src/main/assets/private.tar -C pt
cp /tmp/pycwork/main.pyc /tmp/pt/main.pyc
cd /tmp/pt
tar czf /tmp/private_new.tar.gz main.pyc engine.pyc sitecustomize.pyc p4a_env_vars.txt
cp /tmp/private_new.tar.gz $DIST/src/main/assets/private.tar
tar tvzf $DIST/src/main/assets/private.tar
ls -la $DIST/src/main/assets/private.tar
echo "= MAIN PACK DONE ="