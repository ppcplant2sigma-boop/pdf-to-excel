#!/bin/bash
export PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages
python3 - <<'PY'
import sys
sys.path.insert(0, "/home/admin1234/PDF2Excel")
import engine
for name in ("test.png.pdf",):
    imgs = engine.collect_page_images("/tmp/testpdf/" + name)
    print("pages:", len(imgs))
    for i, page_ims in enumerate(imgs):
        print(" page", i + 1, "imgs:", len(page_ims))
        for bbox, stream in page_ims:
            print("  bbox:", bbox)
            print("  attrs:", stream.attrs)
            d = stream.get_data()
            print("  data len:", len(d), "head:", d[:24].hex())
            try:
                im, ext, raw = engine._pil_image_from_stream(stream)
                print("  pil:", im, ext, raw and len(raw))
            except Exception as e:
                print("  pil ERROR:", repr(e))
PY