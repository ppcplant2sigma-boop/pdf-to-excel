#!/bin/bash
set -e
head -5 /home/admin1234/PDF2Excel/main.py
echo ---
head -3 /home/admin1234/PDF2Excel/engine.py
echo ---
python3 - <<'PY'
import ast
ast.parse(open('/home/admin1234/PDF2Excel/main.py').read()); print('main syntax OK')
ast.parse(open('/home/admin1234/PDF2Excel/engine.py').read()); print('engine syntax OK')
PY