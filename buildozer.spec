[app]
title = PDF to Excel
package.name = pdf2excel
package.domain = org.durgesh
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,ttf
source.exclude_exts = spec
version = 1.0.0
requirements = python3,kivy,pymupdf,pdfplumber,pdfminer.six,openpyxl,et-xmlfile,pillow,plyer,charset_normalizer
orientation = portrait
fullscreen = 0

android.permissions = READ_EXTERNAL_STORAGE
android.api = 35
android.minapi = 21
android.archs = arm64-v8a
android.accept_sdk_license = True
p4a.source_dir = /home/admin1234/PDF2Excel/.buildozer/android/platform/python-for-android

[buildozer]
log_level = 2
warn_on_root = 1android.gradle_repositories = maven { url 'https://mirrors.cloud.tencent.com/nexus/repository/maven-public/' }
