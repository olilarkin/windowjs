#!/bin/sh
# Build Skia for Window.js (2025)
# Supports both component (shared) and static builds

set -e

echo "Building Skia in libraries/skia/out/Release"

cd libraries/skia

mkdir -p out/Release

# Copy platform-specific args
if [ "$(uname)" = "Darwin" ]; then
    cp ../skia-args-mac.gn out/Release/args.gn
else
    cp ../skia-args-linux.gn out/Release/args.gn
fi

# Run GN
gn gen out/Release

if [ $? -ne 0 ]; then
    echo "GN failed!"
    exit 1
fi

# Determine build type based on args.gn
if grep -q "is_component_build = true" out/Release/args.gn; then
    echo "Building Skia as shared library (component build)..."
else
    echo "Building Skia as static library..."
fi

ninja -C out/Release skia

if [ $? -ne 0 ]; then
    echo "Ninja failed!"
    exit 1
fi

echo ""
echo "Skia build done."
echo "Output directory: libraries/skia/out/Release"
