#!/bin/bash
set -e
cd /tmp
rm -rf testpdf && mkdir -p testpdf/out
grep -n -i "fitz\|pymupdf" /home/admin1234/PDF2Excel/engine.py || echo "engine has NO fitz references (good)"

PY=/tmp/bt/_python_bundle/site-packages
export PYTHONPATH=$PY

# ---- generate test PDF using host x86 fitz from the bundle ----
python3 - <<'PY'
from PIL import Image
im = Image.new("RGB", (220, 130), (230, 160, 60))
for x in range(0, 220, 40):
    for y in range(0, 130, 30):
        im.paste((40, 90, 200), (x + 4, y + 4, x + 34, y + 24))
im.save("/tmp/testpdf/sample.png")

import fitz
doc = fitz.open()
page = doc.new_page(width=595, height=842)  # A4 pt
page.insert_text((60, 70), "Monthly Sales Report", fontsize=18)
# table-ish: header + 3 rows
cols = [60, 200, 340, 480]
rows = [110, 150, 190, 230, 270]
for cy in rows:
    page.draw_line((60, cy), (560, cy), color=(0.3, 0.3, 0.4), width=1.2)
for cx in cols:
    page.draw_line((cx, 110), (cx, 270), color=(0.3, 0.3, 0.4), width=1.2)
labels = [["Item", "Qty", "Price", "Total"],
          ["Apple", "10", "25.00", "250.00"],
          ["Mango", "5", "40.00", "200.00"],
          ["Banana", "20", "6.50", "130.00"]]
for r, line in enumerate(labels):
    for c, txt in enumerate(line):
        page.insert_text((cols[c] + 8, rows[r] + 22), txt, fontsize=11)
# floating image below the table
page.insert_image(fitz.Rect(80, 320, 380, 500), filename="/tmp/testpdf/sample.png")
page.draw_rect(fitz.Rect(70, 310, 390, 510), width=1.0, color=(0.6, 0.6, 0.6))
doc.save("/tmp/testpdf/test.pdf")
print("test.pdf written")
PY

# ---- convert using NEW engine (no fitz import anywhere) ----
python3 - <<'PY'
import sys
sys.path.insert(0, "/home/admin1234/PDF2Excel")
import engine
out = engine.convert_one("/tmp/testpdf/test.pdf", "/tmp/testpdf/out", print)
print("OUTPUT:", out)
PY

# ---- verify xlsx contents ----
python3 - <<'PY'
import zipfile, glob
p = sorted(glob.glob("/tmp/testpdf/out/*.xlsx"))[0]
z = zipfile.ZipFile(p)
names = z.namelist()
media = [n for n in names if n.startswith("xl/media/")]
drawings = [n for n in names if "drawing" in n]
print("xlsx:", p)
print("media:", media)
print("drawings:", drawings)
xml = z.read([n for n in names if n.endswith(".xml")][0]).decode("UTF-8") if False else None
if drawings:
    print(z.read(drawings[0]).decode("UTF-8"))
PY

echo "=ALL DONE="