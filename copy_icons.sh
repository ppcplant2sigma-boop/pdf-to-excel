#!/bin/bash
set -e
SRC=/mnt/c/Users/Admin/AppData/Local/Temp/opencode/androidapp/icons
RES=/home/admin1234/PDF2Excel/.buildozer/android/platform/build-arm64-v8a/dists/pdf2excel/src/main/res
cp "$SRC/icon_512.png" "$RES/mipmap/icon.png"
cp "$SRC/icon_48.png"  "$RES/drawable-mdpi/ic_launcher.png"
cp "$SRC/icon_72.png"  "$RES/drawable-hdpi/ic_launcher.png"
cp "$SRC/icon_96.png"  "$RES/drawable-xhdpi/ic_launcher.png"
cp "$SRC/icon_144.png" "$RES/drawable-xxhdpi/ic_launcher.png"
cp "$SRC/presplash.jpg" "$RES/drawable/presplash.jpg"
file "$RES/mipmap/icon.png" "$RES/drawable/presplash.jpg"
echo ICON_COPIED