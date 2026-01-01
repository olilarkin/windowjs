#!/bin/sh
# Build ANGLE for Window.js (2025)
# Supports both component (shared) and static builds

set -e

echo "Building ANGLE in libraries/angle/out/Release"

cd libraries/angle

mkdir -p out/Release

# Copy platform-specific args
if [ "$(uname)" = "Darwin" ]; then
    cp ../angle-args-mac.gn out/Release/args.gn
else
    cp ../angle-args-linux.gn out/Release/args.gn
fi

# Run GN
gn gen out/Release

if [ $? -ne 0 ]; then
    echo "GN failed!"
    exit 1
fi

# Determine build target based on args.gn
if grep -q "is_component_build = true" out/Release/args.gn; then
    echo "Building ANGLE as shared libraries (component build)..."
    ninja -C out/Release libEGL libGLESv2
else
    echo "Building ANGLE as static library..."
    ninja -C out/Release libEGL_static
fi

if [ $? -ne 0 ]; then
    echo "Ninja failed!"
    exit 1
fi

echo ""
echo "ANGLE build done."
echo "Output directory: libraries/angle/out/Release"
