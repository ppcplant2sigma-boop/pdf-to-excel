#!/bin/bash
cp '/mnt/e/C14 PPC/New folder/PDF2Excel/main.py' /tmp/t.py
python3 - <<'PY'
import ast
src = open('/tmp/t.py', encoding='utf-8-sig').read()
ast.parse(src)
print('PARSE OK')
PY