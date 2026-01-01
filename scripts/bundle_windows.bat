@echo off
REM Bundle script for Windows - packages windowjs with DLLs
REM Usage: scripts\bundle_windows.bat [Release|Debug]

setlocal EnableDelayedExpansion

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release

set BUILD_DIR=out\%BUILD_TYPE%
set BUNDLE_DIR=%BUILD_DIR%\windowjs-win64

echo === Bundling Window.js for Windows (%BUILD_TYPE%) ===

REM Clean previous bundle
if exist "%BUNDLE_DIR%" rmdir /s /q "%BUNDLE_DIR%"
mkdir "%BUNDLE_DIR%"

REM Copy executable
echo Copying executable...
copy "%BUILD_DIR%\windowjs.exe" "%BUNDLE_DIR%\"

REM Copy V8 DLLs
echo Copying V8 DLLs...
set V8_DIR=libraries\v8\out\%BUILD_TYPE%
if exist "%V8_DIR%\v8.dll" copy "%V8_DIR%\v8.dll" "%BUNDLE_DIR%\"
if exist "%V8_DIR%\v8_libplatform.dll" copy "%V8_DIR%\v8_libplatform.dll" "%BUNDLE_DIR%\"
if exist "%V8_DIR%\v8_libbase.dll" copy "%V8_DIR%\v8_libbase.dll" "%BUNDLE_DIR%\"

REM Copy Skia DLL
echo Copying Skia DLL...
set SKIA_DIR=libraries\skia\out\%BUILD_TYPE%
if exist "%SKIA_DIR%\skia.dll" copy "%SKIA_DIR%\skia.dll" "%BUNDLE_DIR%\"

REM Copy ANGLE DLLs
echo Copying ANGLE DLLs...
set ANGLE_DIR=libraries\angle\out\%BUILD_TYPE%
if exist "%ANGLE_DIR%\libEGL.dll" copy "%ANGLE_DIR%\libEGL.dll" "%BUNDLE_DIR%\"
if exist "%ANGLE_DIR%\libGLESv2.dll" copy "%ANGLE_DIR%\libGLESv2.dll" "%BUNDLE_DIR%\"

REM Copy D3D compiler if present
if exist "%ANGLE_DIR%\d3dcompiler_47.dll" copy "%ANGLE_DIR%\d3dcompiler_47.dll" "%BUNDLE_DIR%\"

echo.
echo === Bundle created at %BUNDLE_DIR% ===
echo Contents:
dir /b "%BUNDLE_DIR%"

echo.
echo Done!
