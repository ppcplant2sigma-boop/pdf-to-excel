@echo off
setlocal
set PYTHON=%LOCALAPPDATA%\Programs\Python\Python312\python.exe
echo Building standalone exe... this can take a few minutes.
"%PYTHON%" -m PyInstaller --noconfirm --onefile --windowed --collect-all pymupdf --name "PDF to Excel" --icon "%~dp0assets_win\icon.ico" --add-data "%~dp0assets_win\icon.ico;assets_win" --distpath "%~dp0dist" --workpath "%~dp0build" --specpath "%~dp0" "%~dp0pdf2excel.py"
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)
copy /y "%~dp0dist\PDF to Excel.exe" "%~dp0PDF to Excel.exe" >nul
echo.
echo Done! The app is at: "%~dp0PDF to Excel.exe"
pause