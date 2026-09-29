# PDF to Excel

Convert PDF documents into a single clean **Excel (.xlsx) sheet** - completely **offline** on your phone or PC.

**by Er. Durgesh Pandey** — 100% on-device conversion, no internet, no data upload, no ads.

---

## Overview

- **Android app** (`Kivy` + `python-for-android`, arm64 APK) with a simple 3-step flow:
  `Select PDF File` → `Convert` → file saved into **Download** folder (or a location you choose).
- **Windows desktop tool** (`Tkinter`/PyInstaller EXE) with the same conversion core.

Everything runs locally. Your documents never leave your device.

### What it can extract

| Content | How it is handled |
|---|---|
| **Text** | Extracted page-by-page into rows |
| **Tables** | Detected via `pdfplumber`; kept in cell order |
| **Pictures** | Re-embedded at their original page position (Floating images, Flate/JPEG/JPX) |
| **Formatting** | Cell borders, fills, bold text, wrap — carried over to Excel |

The final sheet also gets **auto column widths**, **styled headers** and an **auto-filter** on the used range.

---

## Features

- 📵 **100% offline** — nothing is uploaded, no permissions for network
- 📄 **Native Android file picker** (SAF / `ACTION_OPEN_DOCUMENT`) - shows only PDFs, works with Google Drive too
- 💾 **Saves straight to the phone's Download folder** (MediaStore). Fallback: a system *"Save As"* dialog
- 🖼️ **Pictures inside the PDF are embedded** into the workbook at their page coordinates
- 📊 Single Excel sheet with tables/text/pictures combined
- 🖥️ Same core powers the Windows desktop app
- 🛡️ Crash-protection: errors are written to a `crash.log` in app storage, with an on-screen traceback

## Screenshots

Add screenshots (`screenshots/`) of the app / converted output and reference them here:

```
![Landing screen](screenshots/landing.png)
![Converted output](screenshots/output_excel.png)
```

---

## Download & Install (Android)

> The **Windows desktop version** (same logo, icon & name) has its own page:
> **[README_WINDOWS.md](README_WINDOWS.md)**.

1. Grab the latest **`pdf2excel-debug.apk`** from the *Releases* page (arm64-v8a, Android 8+ recommended).
2. Allow installing from unknown sources if asked.
3. Open **PDF to Excel**.
4. Tap **Select PDF File**, choose any PDF from the phone's own file manager.
5. Tap **Convert**.
6. Find the result:
   - in **Download** folder (`Internal storage/Download/<name>.xlsx`), or
   - at whatever location you pick in the *Save As* dialog.

> Debug-signed APK — for day-to-day use install a release-signed build (see `docs/BUILD.md`).

---

## Tech stack

| Layer | Tech |
|---|---|
| Android UI | Kivy (Python) |
| Android packaging | python-for-android / buildozer (`org.durgesh.pdf2excel`) |
| PDF parsing | pdfplumber, pdfminer.six |
| Images | Pillow, pdfminer `LTImage` |
| Excel writing | openpyxl (floating pictures via cell anchors) |
| File picking | Android SAF intents (`ACTION_OPEN_DOCUMENT` / `ACTION_CREATE_DOCUMENT`) via pyjnius |
| Desktop GUI | Tkinter + PyInstaller |

## Project structure

```
├── main.py                 # Android app UI
├── engine.py               # Conversion core
├── buildozer.spec          # Android build configuration
├── pdf2excel.py            # Windows desktop app (single file)
├── README_WINDOWS.md       # Windows desktop docs (same branding)
├── assets_win/             # Windows icon + logo (icon.ico, logo.png, banner.jpg)
├── make_win_icon.py        # regenerates assets_win/ from the master logo
├── docs/
│   └── BUILD.md            # Build-from-source guide (Android + Windows)
├── *.sh                    # WSL build helpers (see docs/BUILD.md)
└── BUILD EXE.bat           # Windows one-click EXE build
```

---

## Building from source

Full instructions (WSL/Linux Android build + Windows EXE) are in **[docs/BUILD.md](docs/BUILD.md)**.

Quick start (Linux/WSL):

```bash
# install buildozer, then
cd PDF2Excel
buildozer android debug
```

---

## Roadmap / ideas

- [ ] Page-by-page sheets (multi-sheet option)
- [ ] Table-only mode (skip layout text)
- [ ] Password-protected PDF handling UI hint
- [ ] Release-signed APK + Play Store listing
- [ ] Hindi UI toggle

---

## Troubleshooting

| Problem | Hint |
|---|---|
| "No module named charset_normalizer" | stale build; use the latest APK release |
| File not saved to Download | the app auto-falls back to a *Save As* dialog; pick any folder |
| PDF is password protected | remove password first (Adobe/EasyPDF tools) |
| Blank/strange layout | scanned/image PDFs need OCR to extract text (out of scope) |

---

## License

MIT — see [LICENSE](LICENSE).

Maintained with ❤️ by **[Er. Durgesh Pandey]**.