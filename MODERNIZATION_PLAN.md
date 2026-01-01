# Window.js Build Modernization Plan (2025)

## Executive Summary

This document outlines a comprehensive plan to modernize Window.js's build system and dependencies for 2025. The current setup uses V8 11.3.81 (~2023), pinned Skia/ANGLE commits, and static linking throughout. We'll upgrade to current versions and transition to dynamic linking (shared libraries) as the primary build mode to simplify development, with static linking as an optional release configuration.

---

## Current State Analysis

### Current Dependency Versions
| Dependency | Current Version | Approximate Date |
|------------|----------------|------------------|
| V8 | 11.3.81 | ~May 2023 |
| Skia | `9f561bc...` | ~2023 |
| ANGLE | `51ddcab...` | ~2023 |
| GLFW | 3.3.8 | April 2022 |
| libuv | 1.44.2 | June 2022 |

### Current Issues
1. **Stale dependencies**: 2+ years behind current versions
2. **Complex gclient setup**: Heavy transitive dependencies (~500MB+ download)
3. **Long build times**: Static linking requires full rebuilds
4. **Patch maintenance**: Custom patches require updates for each version bump
5. **ABI conflicts**: Different Chromium build versions between V8/Skia/ANGLE cause conflicts

---

## Modernization Strategy

### Phase 1: Dynamic Linking Infrastructure (Foundation)

The key insight is that switching to **shared libraries (DLLs/dylibs/SOs)** dramatically simplifies dependency management:

1. **Isolation**: Each library can use its own build settings without ABI conflicts
2. **Faster iteration**: Only rebuild changed components
3. **Easier debugging**: Can swap debug/release versions independently
4. **Version flexibility**: Each library can use compatible but not identical toolchains

### Phase 2: Platform-by-Platform Migration

We'll tackle platforms in this order:
1. **macOS** (cleanest toolchain, good test bed)
2. **Windows** (most complex, DLL management)
3. **Linux** (most flexible, final validation)

---

## Target Dependency Versions (2025)

| Dependency | Target Version | Release Date | Notes |
|------------|---------------|--------------|-------|
| V8 | 13.x (latest stable) | 2025 | Chrome 130+ |
| Skia | m130+ | 2025 | Match V8's Chromium milestone |
| ANGLE | chromium/6xxx | 2025 | Match V8's Chromium milestone |
| GLFW | 3.4 | 2024 | Major release with Wayland |
| libuv | 1.48+ | 2024 | Latest stable |

**Critical**: Keep V8, Skia, and ANGLE aligned to the same Chromium milestone to avoid ABI conflicts in shared dependencies.

---

## Phase 1: macOS Implementation

### Step 1.1: Update Build Tools

```bash
# Required tools (2025 versions)
- Xcode 16+ with Command Line Tools
- CMake 3.28+
- Ninja 1.12+
- Python 3.12+
```

### Step 1.2: V8 as Shared Library

**Changes to `libraries/v8-args-mac.gn`:**
```gn
# Switch from monolithic to component build
is_component_build = true      # Was: false
v8_monolithic = false          # Was: true

# Enable shared library output
is_debug = false
v8_enable_sandbox = false
v8_enable_i18n_support = false
v8_enable_backtrace = true

# macOS-specific
use_custom_libcxx = false

# Output: libv8.dylib, libv8_libplatform.dylib, etc.
```

**Expected outputs:**
- `libv8.dylib`
- `libv8_libplatform.dylib`
- `libv8_libbase.dylib`
- `libchrome_zlib.dylib`
- `libicuuc.dylib` (if i18n enabled)

### Step 1.3: Skia as Shared Library

**Changes to `libraries/skia-args-mac.gn`:**
```gn
is_official_build = false       # Required for component builds
is_component_build = true       # Was: false
is_debug = false

skia_use_egl = true
skia_gl_standard = "gles"

# Keep bundled dependencies for simplicity
skia_use_system_expat = false
skia_use_system_libjpeg_turbo = false
skia_use_system_libpng = false
skia_use_system_libwebp = false
skia_use_system_zlib = false

# Disable unused features
skia_enable_pdf = false
skia_enable_skottie = false
skia_enable_skparagraph = false
skia_enable_skshaper = false
skia_enable_svg = false
skia_use_icu = false
```

**Expected output:**
- `libskia.dylib`

### Step 1.4: ANGLE as Shared Library

**Changes to `libraries/angle-args-mac.gn`:**
```gn
is_component_build = true       # Was: false
is_debug = false
angle_assert_always_on = false

use_system_xcode = true

# macOS backends
angle_enable_d3d11 = false
angle_enable_d3d9 = false
angle_enable_gl = true
angle_enable_null = false
angle_enable_vulkan = false
angle_enable_metal = true       # NEW: Enable Metal for macOS
```

**Expected outputs:**
- `libEGL.dylib`
- `libGLESv2.dylib`
- `libangle_common.dylib`

### Step 1.5: Update CMake Integration

**New `libraries/v8.cmake` for dynamic linking:**
```cmake
add_library(v8 INTERFACE)

target_include_directories(v8 INTERFACE
    "${PROJECT_SOURCE_DIR}/libraries/v8/include"
    "${PROJECT_SOURCE_DIR}/libraries/v8"
)

target_compile_definitions(v8 INTERFACE
    V8_COMPRESS_POINTERS
    V8_ENABLE_SANDBOX=0
)

set(V8_OUT_DIR "${PROJECT_SOURCE_DIR}/libraries/v8/out/Release")

if(APPLE)
    # Link against shared libraries
    target_link_libraries(v8 INTERFACE
        "${V8_OUT_DIR}/libv8.dylib"
        "${V8_OUT_DIR}/libv8_libplatform.dylib"
        "${V8_OUT_DIR}/libv8_libbase.dylib"
    )

    # Set rpath for runtime discovery
    set_target_properties(v8 PROPERTIES
        BUILD_RPATH "${V8_OUT_DIR}"
        INSTALL_RPATH "@executable_path/../lib"
    )
endif()
```

**Similar updates for `skia.cmake` and `angle.cmake`.**

### Step 1.6: Runtime Library Bundling

Create install/packaging script for macOS:

```bash
#!/bin/bash
# scripts/bundle_macos.sh

APP_NAME="windowjs"
BUILD_DIR="out/Release"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"

# Create app bundle structure
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Frameworks"

# Copy executable
cp "${BUILD_DIR}/windowjs" "${BUNDLE_DIR}/Contents/MacOS/"

# Copy shared libraries
cp libraries/v8/out/Release/libv8*.dylib "${BUNDLE_DIR}/Contents/Frameworks/"
cp libraries/skia/out/Release/libskia.dylib "${BUNDLE_DIR}/Contents/Frameworks/"
cp libraries/angle/out/Release/libEGL.dylib "${BUNDLE_DIR}/Contents/Frameworks/"
cp libraries/angle/out/Release/libGLESv2.dylib "${BUNDLE_DIR}/Contents/Frameworks/"

# Fix rpaths
install_name_tool -add_rpath "@executable_path/../Frameworks" \
    "${BUNDLE_DIR}/Contents/MacOS/windowjs"

# Fix library install names
for lib in "${BUNDLE_DIR}/Contents/Frameworks/"*.dylib; do
    install_name_tool -id "@rpath/$(basename $lib)" "$lib"
done
```

### Step 1.7: Update .gclient for 2025 Versions

```python
vars = {
    'glfw_git': 'https://github.com/glfw/glfw.git',
    'glfw_commit': 'e2c92645a3d8d1892450ac9bd8d65d96cb74a3f1',  # 3.4

    'skia_git': 'https://skia.googlesource.com/skia.git',
    'skia_commit': 'XXXXX',  # Chrome m130 milestone tag

    'v8_git': 'https://chromium.googlesource.com/v8/v8.git',
    'v8_commit': 'XXXXX',  # 13.x latest stable

    'libuv_git': 'https://github.com/libuv/libuv.git',
    'libuv_commit': 'XXXXX',  # v1.48.x

    'angle_git': 'https://chromium.googlesource.com/angle/angle.git',
    'angle_commit': 'XXXXX',  # Match V8's chromium milestone

    'chromium_git': 'https://chromium.googlesource.com',
}
```

---

## Phase 2: Windows Implementation

### Step 2.1: Windows Build Tools

```
- Visual Studio 2022 (17.8+) with Desktop C++ workload
- Windows 11 SDK (10.0.22621.0+)
- CMake 3.28+
- Ninja 1.12+
- Python 3.12+
```

### Step 2.2: V8 as DLL

**Changes to `libraries/v8-args-windows.gn`:**
```gn
is_component_build = true
v8_monolithic = false
is_debug = false

# Use VS 2022 toolchain
is_clang = false  # Use MSVC for better DLL compatibility
visual_studio_version = "2022"
wdk_version = "10.0.22621.0"

v8_enable_sandbox = false
v8_enable_i18n_support = false
symbol_level = 0
```

**Expected outputs:**
- `v8.dll` + `v8.dll.lib`
- `v8_libplatform.dll` + `v8_libplatform.dll.lib`
- `v8_libbase.dll` + `v8_libbase.dll.lib`

### Step 2.3: Skia as DLL

**Changes to `libraries/skia-args-windows.gn`:**
```gn
is_component_build = true
is_official_build = false
is_debug = false

# Use MSVC for DLL builds
is_clang = false

skia_use_egl = true
skia_gl_standard = "gles"

# Windows-specific
skia_use_xps = false
skia_enable_winuwp = false
```

**Expected output:**
- `skia.dll` + `skia.dll.lib`

### Step 2.4: ANGLE as DLL

**Changes to `libraries/angle-args-windows.gn`:**
```gn
is_component_build = true
is_debug = false

# Windows backends
angle_enable_d3d11 = true
angle_enable_d3d9 = false
angle_enable_gl = false         # D3D11 is preferred on Windows
angle_enable_null = false
angle_enable_vulkan = false     # Optional: enable for modern GPUs
```

**Expected outputs:**
- `libEGL.dll` + `libEGL.dll.lib`
- `libGLESv2.dll` + `libGLESv2.dll.lib`
- `d3dcompiler_47.dll` (redistributable from Windows SDK)

### Step 2.5: CMake Updates for Windows DLLs

**Updated `libraries/v8.cmake`:**
```cmake
if(WIN32)
    set(V8_OUT_DIR "${PROJECT_SOURCE_DIR}/libraries/v8/out/Release")

    target_link_libraries(v8 INTERFACE
        "${V8_OUT_DIR}/v8.dll.lib"
        "${V8_OUT_DIR}/v8_libplatform.dll.lib"
        "${V8_OUT_DIR}/v8_libbase.dll.lib"
        DbgHelp.lib
        WinMM.lib
    )

    # Copy DLLs to output directory at build time
    add_custom_command(TARGET windowjs POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${V8_OUT_DIR}/v8.dll"
            "${V8_OUT_DIR}/v8_libplatform.dll"
            "${V8_OUT_DIR}/v8_libbase.dll"
            $<TARGET_FILE_DIR:windowjs>
    )
endif()
```

### Step 2.6: DLL Manifest and Distribution

Create installer script:
```batch
@echo off
REM scripts/bundle_windows.bat

set BUILD_DIR=out\Release
set BUNDLE_DIR=%BUILD_DIR%\windowjs

mkdir %BUNDLE_DIR%

REM Copy executable
copy %BUILD_DIR%\windowjs.exe %BUNDLE_DIR%\

REM Copy V8 DLLs
copy libraries\v8\out\Release\v8.dll %BUNDLE_DIR%\
copy libraries\v8\out\Release\v8_libplatform.dll %BUNDLE_DIR%\
copy libraries\v8\out\Release\v8_libbase.dll %BUNDLE_DIR%\

REM Copy Skia DLL
copy libraries\skia\out\Release\skia.dll %BUNDLE_DIR%\

REM Copy ANGLE DLLs
copy libraries\angle\out\Release\libEGL.dll %BUNDLE_DIR%\
copy libraries\angle\out\Release\libGLESv2.dll %BUNDLE_DIR%\

REM Copy VC++ Runtime (or use static CRT)
REM copy "%VCToolsRedistDir%\x64\Microsoft.VC143.CRT\*.dll" %BUNDLE_DIR%\
```

---

## Phase 3: Linux Implementation

### Step 3.1: Linux Build Tools

```bash
# Ubuntu 22.04+ / Debian 12+
sudo apt-get install \
    build-essential \
    clang-17 \
    cmake \
    ninja-build \
    python3 \
    libfontconfig-dev \
    libfreetype-dev \
    libx11-dev \
    libxrandr-dev \
    libxcursor-dev \
    libxi-dev \
    libxinerama-dev \
    libwayland-dev \
    libxkbcommon-dev
```

### Step 3.2: V8 as Shared Library

**Changes to `libraries/v8-args-linux.gn`:**
```gn
is_component_build = true
v8_monolithic = false
is_debug = false

target_cpu = "x64"

is_clang = true
use_custom_libcxx = false
use_sysroot = false

v8_enable_backtrace = true
v8_enable_sandbox = false
v8_enable_i18n_support = false
```

**Expected outputs:**
- `libv8.so`
- `libv8_libplatform.so`
- `libv8_libbase.so`

### Step 3.3: Skia as Shared Library

**Changes to `libraries/skia-args-linux.gn`:**
```gn
is_component_build = true
is_official_build = false
is_debug = false

skia_use_egl = true
skia_gl_standard = "gles"

is_clang = true
cc = "clang-17"
cxx = "clang++-17"

# Use system libraries where beneficial
skia_use_system_freetype2 = true
skia_use_system_libpng = true
skia_use_system_zlib = true
skia_use_system_libjpeg_turbo = false  # Bundled is more compatible
skia_use_system_libwebp = false
```

**Expected output:**
- `libskia.so`

### Step 3.4: ANGLE as Shared Library

**Changes to `libraries/angle-args-linux.gn`:**
```gn
is_component_build = true
is_debug = false

is_clang = true
use_sysroot = false

# Linux backends
angle_enable_d3d11 = false
angle_enable_d3d9 = false
angle_enable_gl = true
angle_enable_gl_desktop = true
angle_enable_null = false
angle_enable_vulkan = false    # Optional: enable for Vulkan support
```

**Expected outputs:**
- `libEGL.so`
- `libGLESv2.so`
- `libangle_common.so`

### Step 3.5: CMake Updates for Linux SOs

**Updated `libraries/v8.cmake`:**
```cmake
if(UNIX AND NOT APPLE)
    set(V8_OUT_DIR "${PROJECT_SOURCE_DIR}/libraries/v8/out/Release")

    target_link_libraries(v8 INTERFACE
        "${V8_OUT_DIR}/libv8.so"
        "${V8_OUT_DIR}/libv8_libplatform.so"
        "${V8_OUT_DIR}/libv8_libbase.so"
        pthread
        dl
        atomic
    )

    # Set rpath for runtime discovery
    set_target_properties(windowjs PROPERTIES
        BUILD_RPATH "${V8_OUT_DIR}"
        INSTALL_RPATH "$ORIGIN/../lib"
    )
endif()
```

### Step 3.6: Linux Distribution

Create packaging script:
```bash
#!/bin/bash
# scripts/bundle_linux.sh

BUILD_DIR="out/Release"
BUNDLE_DIR="${BUILD_DIR}/windowjs-linux"
LIB_DIR="${BUNDLE_DIR}/lib"

mkdir -p "${LIB_DIR}"

# Copy executable
cp "${BUILD_DIR}/windowjs" "${BUNDLE_DIR}/"

# Copy shared libraries
cp libraries/v8/out/Release/libv8*.so "${LIB_DIR}/"
cp libraries/skia/out/Release/libskia.so "${LIB_DIR}/"
cp libraries/angle/out/Release/libEGL.so "${LIB_DIR}/"
cp libraries/angle/out/Release/libGLESv2.so "${LIB_DIR}/"

# Create launch wrapper
cat > "${BUNDLE_DIR}/run.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
exec "${SCRIPT_DIR}/windowjs" "$@"
EOF
chmod +x "${BUNDLE_DIR}/run.sh"

# Create tarball
tar -czvf windowjs-linux-x64.tar.gz -C "${BUILD_DIR}" windowjs-linux
```

---

## Dependency Synchronization Strategy

### The Core Problem

V8, Skia, and ANGLE all depend on various Chromium infrastructure:
- `build/` (Chromium build configs)
- `third_party/abseil-cpp/`
- `third_party/zlib/`
- `tools/clang/`

When these have different versions, builds fail with ABI mismatches or missing symbols.

### Solution: Chromium Milestone Alignment

All three libraries follow Chrome's milestone releases. **Pin all to the same milestone:**

```python
# .gclient - Example for Chrome M130
chromium_milestone = "6778"  # M130

vars = {
    # V8 from M130
    'v8_git': 'https://chromium.googlesource.com/v8/v8.git',
    'v8_commit': 'refs/heads/13.0-lkgr',  # Or specific tag

    # Skia from M130
    'skia_git': 'https://skia.googlesource.com/skia.git',
    'skia_commit': 'refs/heads/chrome/m130',

    # ANGLE from M130
    'angle_git': 'https://chromium.googlesource.com/angle/angle.git',
    'angle_commit': 'refs/heads/chromium/6778',  # M130 branch
}
```

### Simplified Dependency Tree

With dynamic linking, each library can maintain its own `build/` and `third_party/`:

```
libraries/
├── v8/
│   ├── build/          # V8's own copy
│   ├── third_party/    # V8's dependencies
│   └── ...
├── skia/
│   ├── build/          # Skia's own copy (can differ!)
│   ├── third_party/    # Skia's dependencies
│   └── ...
├── angle/
│   ├── build/          # ANGLE's own copy
│   ├── third_party/    # ANGLE's dependencies
│   └── ...
└── ...
```

This isolation is possible because:
1. Each library exports only C-compatible symbols (V8 API, EGL/GLES, Skia)
2. Internal C++ ABIs don't need to match
3. Each can use its own libcxx/STL

### Updated .gclient Structure

```python
# Simplified .gclient - each library manages its own deps

solutions = [
    {
        "name": "libraries/v8",
        "url": "{v8_git}@{v8_commit}",
        "managed": False,
        "custom_vars": {
            "checkout_fuchsia": False,
            "checkout_nacl": False,
        },
    },
    {
        "name": "libraries/skia",
        "url": "{skia_git}@{skia_commit}",
        "managed": False,
    },
    {
        "name": "libraries/angle",
        "url": "{angle_git}@{angle_commit}",
        "managed": False,
    },
]

# Hooks for each library run independently
hooks = [
    # V8 hooks
    {"cwd": "libraries/v8", "action": ["gclient", "sync", "--shallow"]},
    # Skia hooks
    {"cwd": "libraries/skia", "action": ["python3", "tools/git-sync-deps"]},
    # ANGLE hooks
    {"cwd": "libraries/angle", "action": ["gclient", "sync", "--shallow"]},
]
```

---

## Patch Modernization Strategy

### Current Patches Analysis

| Patch | Purpose | Likely Status in 2025 |
|-------|---------|----------------------|
| `v8.patch` | Compiler warning fixes | May be fixed upstream |
| `v8_build.patch` | Build config tweaks | Needs update |
| `skia.patch` | ANGLE integration + CFI fix | Needs update |
| `angle.patch` | macOS vsync, static lib fixes | Partially upstream |
| `glfw.patch` | Platform-specific fixes | Check if in 3.4 |

### Strategy

1. **Check upstream first**: Many fixes get merged; check before re-applying
2. **Minimize patches**: With dynamic linking, many build patches are unnecessary
3. **Document each patch**: Why it exists, when it can be removed

### Creating Version-Tagged Patches

```
libraries/patches/
├── v8/
│   ├── v13.x/
│   │   └── compiler-warnings.patch
│   └── common/
│       └── build-config.patch
├── skia/
│   ├── m130/
│   │   └── angle-integration.patch
│   └── common/
│       └── ...
└── angle/
    ├── chromium-6778/
    │   └── ...
    └── common/
        └── ...
```

---

## Build Script Updates

### New Build Flow

```bash
#!/bin/bash
# build.sh - Unified build script

set -e

PLATFORM=$(uname)
BUILD_TYPE=${1:-Release}

echo "=== Building Window.js for ${PLATFORM} (${BUILD_TYPE}) ==="

# Step 1: Sync dependencies (if needed)
if [ ! -d libraries/v8/out ]; then
    echo "==> Syncing dependencies..."
    gclient sync --shallow --no-history
fi

# Step 2: Build V8
echo "==> Building V8..."
cd libraries/v8
gn gen out/${BUILD_TYPE} --args="$(cat ../v8-args-${PLATFORM,,}.gn)"
ninja -C out/${BUILD_TYPE}
cd ../..

# Step 3: Build Skia
echo "==> Building Skia..."
cd libraries/skia
gn gen out/${BUILD_TYPE} --args="$(cat ../skia-args-${PLATFORM,,}.gn)"
ninja -C out/${BUILD_TYPE}
cd ../..

# Step 4: Build ANGLE
echo "==> Building ANGLE..."
cd libraries/angle
gn gen out/${BUILD_TYPE} --args="$(cat ../angle-args-${PLATFORM,,}.gn)"
ninja -C out/${BUILD_TYPE}
cd ../..

# Step 5: Build Window.js
echo "==> Building Window.js..."
cmake -S . -B out/${BUILD_TYPE} \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -G Ninja
cmake --build out/${BUILD_TYPE} --target windowjs

echo "=== Build complete ==="
```

---

## Testing Strategy

### Incremental Testing

1. **Library-level tests**: Run each library's tests independently
   ```bash
   # V8 tests
   ninja -C libraries/v8/out/Release v8_unittests
   libraries/v8/out/Release/v8_unittests

   # ANGLE tests
   ninja -C libraries/angle/out/Release angle_end2end_tests
   libraries/angle/out/Release/angle_end2end_tests
   ```

2. **Integration tests**: Run Window.js examples
   ```bash
   ./out/Release/windowjs examples/canvas/arc.js
   ./out/Release/windowjs examples/window/hello.js
   ```

3. **Platform-specific tests**: macOS Metal, Windows D3D11, Linux GL

### CI/CD Updates

```yaml
# .github/workflows/build.yml
jobs:
  build-macos:
    runs-on: macos-14  # M1 runner
    steps:
      - uses: actions/checkout@v4
      - name: Setup build environment
        run: |
          brew install cmake ninja
          source libraries/setup_build_env.sh
      - name: Sync dependencies
        run: gclient sync --shallow --no-history
      - name: Build libraries
        run: |
          ./libraries/build_v8.sh
          ./libraries/build_skia.sh
          ./libraries/build_angle.sh
      - name: Build Window.js
        run: |
          cmake -S . -B out/Release -DCMAKE_BUILD_TYPE=Release -G Ninja
          cmake --build out/Release
      - name: Bundle
        run: ./scripts/bundle_macos.sh
      - uses: actions/upload-artifact@v4
        with:
          name: windowjs-macos
          path: out/Release/windowjs.app
```

---

## Migration Timeline

### Week 1-2: macOS Foundation
- [ ] Update .gclient to 2025 versions
- [ ] Modify GN args for dynamic linking
- [ ] Update CMake files for dylib linking
- [ ] Create bundle script
- [ ] Test on Intel + Apple Silicon

### Week 3-4: Windows Migration
- [ ] Update GN args for DLL builds
- [ ] Update CMake for Windows DLLs
- [ ] Handle MSVC vs Clang builds
- [ ] Create installer/bundle script
- [ ] Test on Windows 10/11

### Week 5-6: Linux Migration
- [ ] Update GN args for SO builds
- [ ] Update CMake for Linux SOs
- [ ] Test with system vs bundled libs
- [ ] Create distribution packages
- [ ] Test on Ubuntu, Fedora

### Week 7-8: Polish & Static Builds
- [ ] Add static build option (for releases)
- [ ] Update documentation
- [ ] CI/CD pipeline updates
- [ ] Performance testing
- [ ] Release preparation

---

## Static Build Option (Future)

For release builds, static linking produces a single portable binary. Keep this as an option:

```cmake
# CMakeLists.txt
option(WINDOWJS_STATIC "Build with static linking" OFF)

if(WINDOWJS_STATIC)
    # Use monolithic/static library builds
    include(libraries/v8-static.cmake)
    include(libraries/skia-static.cmake)
    include(libraries/angle-static.cmake)
else()
    # Use shared library builds (default for development)
    include(libraries/v8.cmake)
    include(libraries/skia.cmake)
    include(libraries/angle.cmake)
endif()
```

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| API changes in V8 13.x | High | Incremental updates, test coverage |
| Skia API changes | Medium | Review migration guides |
| ANGLE Metal bugs | Medium | Keep GL fallback |
| Build time increase from deps sync | Low | Use shallow clones, caching |
| DLL hell on Windows | Medium | Bundle all DLLs, use manifests |
| rpath issues on Linux | Low | Use $ORIGIN, wrapper scripts |

---

## Conclusion

This modernization plan provides a path from the current 2023-era static build to a modern 2025 dynamic-linked build. The key benefits:

1. **Faster development cycles**: Only rebuild what changed
2. **Easier debugging**: Swap debug libraries independently
3. **Reduced conflicts**: Isolated library ABIs
4. **Better maintainability**: Simpler patches, clearer dependencies
5. **Future-proof**: Ready for 2025+ versions

Start with macOS as it has the cleanest toolchain, then port to Windows and Linux.
