import os, sys
from PIL import Image

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.join(BASE_DIR, "assets_win")
os.makedirs(OUTDIR, exist_ok=True)

SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(OUTDIR, "logo.png")

if os.path.exists(SRC):
    img = Image.open(SRC).convert("RGBA")
    ico_path = os.path.join(OUTDIR, "icon.ico")
    img.save(ico_path, format="ICO", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
    print("ICO ->", ico_path)
else:
    print(f"Source image not found: {SRC}")