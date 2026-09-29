#!/bin/bash
export PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages
python3 - <<'PY'
import sys
sys.path.insert(0, "/home/admin1234/PDF2Excel")
import engine
for name in ("test.png.pdf", "test.jpg.pdf"):
    out = engine.convert_one("/tmp/testpdf/" + name, "/tmp/testpdf/out2", print)
    print("OUTPUT:", out)
import zipfile, glob
for p in sorted(glob.glob("/tmp/testpdf/out2/*.xlsx")):
    z = zipfile.ZipFile(p)
    print("OK:", p, "media:", [n for n in z.namelist() if n.startswith("xl/media/")])
PY
echo SMOKE_DONE