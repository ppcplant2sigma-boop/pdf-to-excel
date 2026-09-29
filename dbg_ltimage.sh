#!/bin/bash
export PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages
python3 - <<'PY'
from pdfminer.high_level import extract_pages
from pdfminer.layout import LTImage, LTPage, LTFigure
for f in ("test.png.pdf",):
    print("###", f)
    with open("/tmp/testpdf/" + f, "rb") as fp:
        pages = list(extract_pages(fp))
    print("pages:", len(pages))
    for p in pages:
        print(" LTPage bbox:", p.bbox, "size:", p.width, p.height)
        for o in p:
            print("   ", type(o).__name__, getattr(o, "bbox", None),
                  "name:", getattr(o, "name", None))
            if isinstance(o, LTImage):
                print("      stream attrs:", o.stream.attrs)
                data = o.stream.get_data()
                print("      data len:", len(data), "head:", data[:16].hex())
            if isinstance(o, LTFigure):
                for sub in o:
                    print("         sub:", type(sub).__name__, getattr(sub, "bbox", None),
                          "name:", getattr(sub, "name", None))
PY