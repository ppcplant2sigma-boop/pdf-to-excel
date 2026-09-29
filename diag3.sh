#!/bin/bash
ls -la /tmp/bt/_python_bundle/site-packages/pdfplumber/__init__.pyc /tmp/bt/_python_bundle/site-packages/pdfplumber 2>&1
echo "== symlink check =="
find /tmp/bt/_python_bundle/site-packages -maxdepth 1 -type l | head
echo "== import -v trace =="
cd /tmp && PYTHONPATH=/tmp/hostpy:/tmp/bt/_python_bundle/site-packages python3 -v /tmp/p.py 2>&1 | grep -i "pdfplumber" | head -8