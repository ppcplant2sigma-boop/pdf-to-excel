#!/bin/bash
SP=/tmp/bt/_python_bundle/site-packages
echo "== who imports chardet =="
grep -rIl "chardet" $SP/pdfminer $SP/pdfplumber $SP/openpyxl 2>/dev/null | head
echo "== chardet version dirs =="
ls $SP | grep -i chardet
echo "== who imports charset_normalizer =="
grep -rIl "charset_normalizer" $SP/pdfminer $SP/pdfplumber $SP/openpyxl 2>/dev/null | head
echo "== charset_normalizer dir layout =="
ls $SP/charset_normalizer/ | head -30