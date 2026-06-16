@echo off
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "FLUTTER_BIN=C:\Users\sasankan\Downloads\flutter_windows_3.44.1-stable\flutter\bin"
set "PS_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0"
set "PATH=%JAVA_HOME%\bin;%FLUTTER_BIN%;%PS_PATH%;%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem"

echo --- Fetching dependencies ---
call flutter clean


echo --- Building release APK ---
rd /s /q build\flutter_plugin_android_lifecycle
call flutter build apk --release 2>&1

echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ==========================================
    echo BUILD SUCCESS!
    echo APK is ready at:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo ==========================================
) else (
    echo BUILD FAILED - check errors above
)
