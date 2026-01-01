#!/bin/bash
# Bundle script for Linux - packages windowjs with shared libraries
# Usage: ./scripts/bundle_linux.sh [Release|Debug]

set -e

BUILD_TYPE="${1:-Release}"
APP_NAME="windowjs"
BUILD_DIR="out/${BUILD_TYPE}"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}-linux-x64"
LIB_DIR="${BUNDLE_DIR}/lib"

echo "=== Bundling Window.js for Linux (${BUILD_TYPE}) ==="

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"

# Create bundle structure
mkdir -p "${LIB_DIR}"

# Copy executable
echo "Copying executable..."
cp "${BUILD_DIR}/windowjs" "${BUNDLE_DIR}/"

# Copy V8 shared libraries
echo "Copying V8 shared libraries..."
V8_DIR="libraries/v8/out/${BUILD_TYPE}"
for lib in libv8.so libv8_libplatform.so libv8_libbase.so; do
    if [ -f "${V8_DIR}/${lib}" ]; then
        cp "${V8_DIR}/${lib}" "${LIB_DIR}/"
    fi
done

# Copy Skia shared library
echo "Copying Skia shared library..."
SKIA_DIR="libraries/skia/out/${BUILD_TYPE}"
if [ -f "${SKIA_DIR}/libskia.so" ]; then
    cp "${SKIA_DIR}/libskia.so" "${LIB_DIR}/"
fi

# Copy ANGLE shared libraries
echo "Copying ANGLE shared libraries..."
ANGLE_DIR="libraries/angle/out/${BUILD_TYPE}"
for lib in libEGL.so libGLESv2.so; do
    if [ -f "${ANGLE_DIR}/${lib}" ]; then
        cp "${ANGLE_DIR}/${lib}" "${LIB_DIR}/"
    fi
done

# Create launch wrapper script
echo "Creating launch wrapper..."
cat > "${BUNDLE_DIR}/windowjs.sh" << 'SCRIPT'
#!/bin/bash
# Window.js launch wrapper - sets up library path and runs the executable
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
exec "${SCRIPT_DIR}/windowjs" "$@"
SCRIPT
chmod +x "${BUNDLE_DIR}/windowjs.sh"

# Set executable permissions
chmod +x "${BUNDLE_DIR}/windowjs"

# List bundle contents
echo ""
echo "=== Bundle created at ${BUNDLE_DIR} ==="
echo "Contents:"
find "${BUNDLE_DIR}" -type f | sed 's|^|  |'

# Calculate size
BUNDLE_SIZE=$(du -sh "${BUNDLE_DIR}" | cut -f1)
echo ""
echo "Total size: ${BUNDLE_SIZE}"

# Create tarball
echo ""
echo "Creating tarball..."
TARBALL="${BUILD_DIR}/${APP_NAME}-linux-x64.tar.gz"
tar -czvf "${TARBALL}" -C "${BUILD_DIR}" "${APP_NAME}-linux-x64"
TARBALL_SIZE=$(du -sh "${TARBALL}" | cut -f1)
echo "Tarball created: ${TARBALL} (${TARBALL_SIZE})"
