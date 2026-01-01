#!/bin/sh
# Build V8 for Window.js (2025)
# Supports both component (shared) and monolithic (static) builds

set -e

echo "Building V8 in libraries/v8/out/Release"

cd libraries/v8

mkdir -p out/Release

# Copy platform-specific args
if [ "$(uname)" = "Darwin" ]; then
    cp ../v8-args-mac.gn out/Release/args.gn
else
    cp ../v8-args-linux.gn out/Release/args.gn
fi

# Run GN
gn gen out/Release

if [ $? -ne 0 ]; then
    echo "GN failed!"
    exit 1
fi

# Determine build target based on args.gn
if grep -q "is_component_build = true" out/Release/args.gn; then
    echo "Building V8 as shared libraries (component build)..."
    # Build the main V8 targets for component build
    ninja -C out/Release v8 v8_libplatform v8_libbase
else
    echo "Building V8 as monolithic static library..."
    ninja -C out/Release v8_monolith
fi

if [ $? -ne 0 ]; then
    echo "Ninja failed!"
    exit 1
fi

echo ""
echo "V8 build done."
echo "Output directory: libraries/v8/out/Release"
