#!/bin/bash
echo "PYPATH=[$PYTHONPATH]"
cat > /tmp/p.py <<'PY'
import sys
print("all sys.path:")
for p in sys.path:
    print("  ", p)
try:
    import pdfplumber
    print("pdfplumber ->", pdfplumber.__file__)
except Exception as e:
    print("pdfplumber import failed:", repr(e))
PY
cd /tmp
python3 /tmp/p.py