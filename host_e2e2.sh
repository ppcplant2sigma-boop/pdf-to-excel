#!/bin/bash
set -e
cd /tmp
rm -rf testpdf && mkdir -p testpdf/out

export PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages

python3 - <<'PY'
print("fitz import (host x86, gen only):", end=" ")
import fitz
print("ok")
PY

# ---- generate test PDF (image via mupdf pixmap, table via draw ops) ----
python3 - <<'PY'
import fitz
doc = fitz.open()
page = doc.new_page(width=595, height=842)
page.insert_text((60, 70), "Monthly Sales Report", fontsize=18)
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
# build an image pixmap (pure mupdf, no PIL) to embed
tile = fitz.open()
tp = tile.new_page(width=220, height=130)
tp.draw_rect(fitz.Rect(0, 0, 220, 130), color=None, fill=(0.93, 0.66, 0.25))
tp.draw_rect(fitz.Rect(8, 8, 40, 34), color=None, fill=(0.16, 0.35, 0.78))
tp.draw_rect(fitz.Rect(48, 8, 80, 34), color=None, fill=(0.16, 0.35, 0.78))
pix = tp.get_pixmap()
png_path = "/tmp/testpdf/sample.png"
if hasattr(pix, "save") or True:
    try:
        pix.save(png_path)
    except Exception as e:
        print("png save failed:", e)
# try jpeg too
jpg_path = "/tmp/testpdf/sample.jpg"
try:
    pix.save(jpg_path)
    print("jpg saved ok")
except Exception:
    print("jpg save skipped")
page.insert_image(fitz.Rect(80, 320, 380, 500), filename=png_path)
page.draw_rect(fitz.Rect(70, 310, 390, 510), width=1.0, color=(0.6, 0.6, 0.6))
doc.save("/tmp/testpdf/test.png.pdf")
# second PDF with JPEG image if available
import os
if os.path.exists(jpg_path):
    doc2 = fitz.open()
    p2 = doc2.new_page(width=595, height=400)
    p2.insert_image(fitz.Rect(40, 40, 340, 220), filename=jpg_path)
    doc2.save("/tmp/testpdf/test.jpg.pdf")
print("generated")
PY

# ---- new engine conversion (uses pdfplumber + pdfminer + PIL-hostshim) ----
python3 - <<'PY'
import sys
sys.path.insert(0, "/home/admin1234/PDF2Excel")
import engine
for name in ("test.png.pdf", "test.jpg.pdf"):
    out = engine.convert_one("/tmp/testpdf/" + name, "/tmp/testpdf/out", print)
    print("OUTPUT:", out)
PY

# ---- verify xlsx ----
python3 - <<'PY'
import zipfile, glob
for p in sorted(glob.glob("/tmp/testpdf/out/*.xlsx")):
    z = zipfile.ZipFile(p)
    names = z.namelist()
    media = [n for n in names if n.startswith("xl/media/")]
    dr = [n for n in names if "drawing" in n]
    print(p)
    print("  media:", media)
    for d in dr:
        print("  drawing:", z.read(d).decode("UTF-8"))
PY

echo "=ALL DONE="