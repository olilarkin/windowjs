#!/bin/bash
# Bundle script for macOS - packages windowjs with shared libraries
# Usage: ./scripts/bundle_macos.sh [Release|Debug]

set -e

BUILD_TYPE="${1:-Release}"
APP_NAME="windowjs"
BUILD_DIR="out/${BUILD_TYPE}"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
FRAMEWORKS_DIR="${BUNDLE_DIR}/Contents/Frameworks"
MACOS_DIR="${BUNDLE_DIR}/Contents/MacOS"

echo "=== Bundling Window.js for macOS (${BUILD_TYPE}) ==="

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"

# Create app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${FRAMEWORKS_DIR}"

# Copy executable
echo "Copying executable..."
cp "${BUILD_DIR}/windowjs" "${MACOS_DIR}/"

# Copy V8 shared libraries
echo "Copying V8 dylibs..."
V8_DIR="libraries/v8/out/${BUILD_TYPE}"
for lib in libv8.dylib libv8_libplatform.dylib libv8_libbase.dylib; do
    if [ -f "${V8_DIR}/${lib}" ]; then
        cp "${V8_DIR}/${lib}" "${FRAMEWORKS_DIR}/"
    fi
done

# Copy Skia shared library
echo "Copying Skia dylib..."
SKIA_DIR="libraries/skia/out/${BUILD_TYPE}"
if [ -f "${SKIA_DIR}/libskia.dylib" ]; then
    cp "${SKIA_DIR}/libskia.dylib" "${FRAMEWORKS_DIR}/"
fi

# Copy ANGLE shared libraries
echo "Copying ANGLE dylibs..."
ANGLE_DIR="libraries/angle/out/${BUILD_TYPE}"
for lib in libEGL.dylib libGLESv2.dylib; do
    if [ -f "${ANGLE_DIR}/${lib}" ]; then
        cp "${ANGLE_DIR}/${lib}" "${FRAMEWORKS_DIR}/"
    fi
done

# Fix library install names
echo "Fixing library install names..."
for lib in "${FRAMEWORKS_DIR}"/*.dylib; do
    if [ -f "$lib" ]; then
        libname=$(basename "$lib")
        install_name_tool -id "@rpath/${libname}" "$lib" 2>/dev/null || true
    fi
done

# Add rpath to executable
echo "Adding rpath to executable..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "${MACOS_DIR}/windowjs" 2>/dev/null || true

# Update library references in executable
echo "Updating library references..."
for lib in "${FRAMEWORKS_DIR}"/*.dylib; do
    if [ -f "$lib" ]; then
        libname=$(basename "$lib")
        # Try to update the reference (may fail if not directly linked)
        install_name_tool -change "${lib}" "@rpath/${libname}" "${MACOS_DIR}/windowjs" 2>/dev/null || true
    fi
done

# Create Info.plist
echo "Creating Info.plist..."
cat > "${BUNDLE_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>windowjs</string>
    <key>CFBundleIdentifier</key>
    <string>io.windowjs.windowjs</string>
    <key>CFBundleName</key>
    <string>Window.js</string>
    <key>CFBundleDisplayName</key>
    <string>Window.js</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

# Create PkgInfo
echo "APPL????" > "${BUNDLE_DIR}/Contents/PkgInfo"

# List bundle contents
echo ""
echo "=== Bundle created at ${BUNDLE_DIR} ==="
echo "Contents:"
find "${BUNDLE_DIR}" -type f | sed 's|^|  |'

# Calculate size
BUNDLE_SIZE=$(du -sh "${BUNDLE_DIR}" | cut -f1)
echo ""
echo "Total size: ${BUNDLE_SIZE}"
