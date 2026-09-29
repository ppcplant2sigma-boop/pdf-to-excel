#!/bin/bash
# clean isolated run: ONLY bundle + hostpy on path
cat > /tmp/diag_run.py <<'PY'
import sys
print("sys.path[0:4]:")
for p in sys.path[:4]:
    print("   ", p)
import pdfplumber
print("pdfplumber file:", pdfplumber.__file__)
try:
    import charset_normalizer
    print("charset_normalizer:", charset_normalizer.__file__)
except Exception as e:
    print("charset_normalizer absent:", repr(e))
try:
    import chardet
    print("chardet:", chardet.__file__)
except Exception as e:
    print("chardet absent:", repr(e))
try:
    import pymupdf
    print("PYMUPDF PRESENT (BAD)")
except Exception as e:
    print("pymupdf absent:", repr(e))
PY
export PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages
python3 -S /tmp/diag_run.py