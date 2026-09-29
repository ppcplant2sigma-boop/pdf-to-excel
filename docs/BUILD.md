# Building PDF to Excel from source

Two builds exist:

1. **Android APK** — Kivy UI + python-for-android.
2. **Windows desktop EXE** — same conversion core, Tkinter UI + PyInstaller.

---

## Prerequirements (both)

- Python 3.10+
- Git
- ~6 GB free disk (Android build toolchain)

---

## 1. Android build (APK)

The Android app is built on Linux/WSL with **buildozer**. This project was built
and tested inside **WSL (Ubuntu)** targeting **arm64-v8a**.

### 1.1 Environment

```bash
sudo apt update && sudo apt install -y \
  python3-pip python3-venv \
  openjdk-17-jdk unzip \
  zlib1g-dev libffi-dev libssl-dev \
  autoconf automake libtool pkg-config \
  libncurses-dev libxml2-dev libxslt1-dev \
  ccache git curl

python3 -m venv ~/venv && source ~/venv/bin/activate
pip install -U buildozer cython
```

> Android SDK components (adb, platform-tools, NDK) are downloaded automatically
> by buildozer on first run — this takes a while.

### 1.2 Build

```bash
cd PDF2Excel
buildozer android debug apk
```

Output: `bin/pdf2excel-1.0.0-arm64-v8a-debug.apk`.

Install on a connected device:

```bash
adb install -r bin/*debug.apk
```

### 1.3 Notes about this project's real pipeline

For production-grade binaries we extend the default buildozer flow:

- **Compile** `main.py` / `engine.py` to `.pyc` using the p4a **hostpython3**
  interpreter (so the exact Python 3.14 bytecode magic matches the device).
- **Bundle**: app code lives in `dists/.../src/main/assets/private.tar`
  (gzip) — contains `main.pyc`, `engine.pyc`, `sitecustomize.pyc`.
  `lib/arm64-v8a/libpybundle.so` is the Python bundle (site-packages +
  stdlib). It is **re-packed** as a gzip tar after pruning undesired
  x86-only modules (e.g. `pymupdf`, `fitz`, `chardet`) and re-adding
  needed pure-Python deps (`charset_normalizer`).
- **Verify before shipping** (see `scripts/`):
  - `verify_apk.sh` — unpacks the APK and checks `private.tar` contents
    and the bundle size.
  - non-AArch64 `.so` scan must return **0**.
  - import smoke-test of `charset_normalizer` / `requests` etc. from the bundle.
- Final assembleDebug via gradle:

```bash
cd .buildozer/android/platform/build-arm64-v8a/dists/pdf2excel
JAVA_TOOL_OPTIONS=-Djava.net.preferIPv6Addresses=true ./gradlew assembleDebug
```

### 1.4 Useful helper scripts (Linux/WSL, executed from the repo)

| Script | Purpose |
|---|---|
| `repack_main.sh` | copy new main, compile `.pyc`, rebuild `private.tar` |
| `rep_bundle.sh` | rebuild `libpybundle.so` from dist bundle, arch-scan |
| `verify_apk.sh` | extract APK and verify assets |
| `final_copy.sh` | copy built APK to `~/Downloads` |
| `copy_icons.sh` | install launcher icons / presplash into the APK source |

---

## 2. Windows desktop build (EXE)

Pure Python + Tkinter — no Android SDK needed.

### 2.1 Setup

```powershell
pip install -r requirements.txt   # pdfplumber, pymupdf, pillow, openpyxl
```

### 2.2 Branding assets

The desktop app uses the **same logo/icon/name** as the Android app:

| Path | Purpose |
|---|---|
| `assets_win/icon.ico` | EXE + taskbar + window icon (built from the same gradient logo) |
| `assets_win/logo.png` | repo/branding |

Regenerate with `make_win_icon.py` (needs Pillow).

### 2.3 Build with PyInstaller

```powershell
pyinstaller --onefile --windowed --name "PDF to Excel" `
  --icon "assets_win\icon.ico" `
  --add-data "assets_win\icon.ico;assets_win" `
  pdf2excel.py
```

Output: `dist/PDF to Excel.exe` — a single portable file. The bundled
`assets_win/icon.ico` is picked up at runtime via `sys._MEIPASS` so the
**window/taskbar icon** also shows the logo.

> Or simply run **`BUILD EXE.bat`** at the repo root.

> Note: PyMuPDF (fitz) is used only by the desktop app; the Android engine is
> pymupdf-**free** (uses pdfminer's `LTImage` + Pillow instead).

---

## 3. Concurrency / threading model (Android)

- Conversion runs on a **background thread** (`threading.Thread`).
- Progress messages flow back to the UI through a `queue.Queue` drained
  by a Kivy `Clock` interval.
- Uncaught exceptions are trapped by a custom `sys.excepthook` /
  `threading.excepthook` and written to `crash.log` inside app storage
  (plus an on-screen traceback).