import os, sys
from PIL import Image

SRC = r"C:\Users\Admin\AppData\Local\Temp\opencode\androidapp\icons\icon_512.png"
OUTDIR = r"E:\C14 PPC\New folder\PDF2Excel\assets_win"
os.makedirs(OUTDIR, exist_ok=True)

img = Image.open(SRC).convert("RGBA")
ico_path = os.path.join(OUTDIR, "icon.ico")
img.save(ico_path, format="ICO", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
print("ICO ->", ico_path)

img.resize((512,512)).save(os.path.join(OUTDIR, "logo.png"))
img2 = Image.open(r"C:\Users\Admin\AppData\Local\Temp\opencode\androidapp\icons\presplash.jpg")
img2.save(os.path.join(OUTDIR, "banner.jpg"))
print("logo/banner copied")