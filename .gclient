# Window.js dependency configuration (2025)
#
# This file configures gclient to fetch V8, Skia, ANGLE, GLFW, and libuv.
# All Chromium-based dependencies (V8, Skia, ANGLE) are aligned to Chrome M140
# to avoid ABI conflicts in shared build infrastructure.
#
# DYNAMIC LINKING (default):
#   No patches are required - libraries are built as shared libraries and
#   link against each other dynamically, avoiding ABI conflicts.
#
# STATIC LINKING (optional for releases):
#   See libraries/patches/ for patches needed when building static libraries.
#   Apply patches manually before building with WINDOWJS_STATIC=ON.
#
# To sync dependencies:
#   gclient sync --shallow --no-history -D -R --force
#
# For more info: https://chromium.googlesource.com/chromium/tools/depot_tools

vars = {
    # ============================================================================
    # Core dependencies - updated for 2025 (Chrome M140 alignment)
    # ============================================================================

    # GLFW 3.4 (February 2024) - major release with Wayland support
    'glfw_git': 'https://github.com/glfw/glfw.git',
    'glfw_commit': '7b6aead9fb88b3623e3b3725ebb42670cbe4c579',  # Tag 3.4

    # Skia - aligned to Chrome M140 milestone
    # Update skia_deps below when the Skia version is updated.
    'skia_git': 'https://skia.googlesource.com/skia.git',
    'skia_commit': 'chrome/m140',  # Chrome M140 branch

    # V8 - aligned to Chrome M140 (V8 14.0.x)
    # Update v8_deps below when the v8 version is updated.
    'v8_git': 'https://chromium.googlesource.com/v8/v8.git',
    'v8_commit': 'branch-heads/14.0',  # V8 14.0.x for Chrome M140

    # libuv 1.51.0 (April 2025) - latest stable
    'libuv_git': 'https://github.com/libuv/libuv.git',
    'libuv_commit': 'v1.51.0',  # Tag v1.51.0

    # ANGLE - aligned to Chrome M140 (branch 7339)
    'angle_git': 'https://chromium.googlesource.com/angle/angle.git',
    'angle_commit': 'chromium/7339',  # Chrome M140 branch

    'chromium_git': 'https://chromium.googlesource.com',
}

# ============================================================================
# ANGLE dependencies
# With component builds, each library manages its own deps independently.
# These will be fetched when gclient syncs libraries/angle.
# ============================================================================
angle_deps = {
    'build': '{chromium_git}/chromium/src/build.git',
    'testing': '{chromium_git}/chromium/src/testing',
    'tools/protoc_wrapper': '{chromium_git}/chromium/src/tools/protoc_wrapper',
    'third_party/abseil-cpp': '{chromium_git}/chromium/src/third_party/abseil-cpp',
    'third_party/catapult': '{chromium_git}/catapult.git',
    'third_party/jsoncpp': '{chromium_git}/chromium/src/third_party/jsoncpp',
    'third_party/googletest': '{chromium_git}/chromium/src/third_party/googletest',
    'third_party/libjpeg_turbo': '{chromium_git}/chromium/deps/libjpeg_turbo.git',
    'third_party/nasm': '{chromium_git}/chromium/deps/nasm.git',
    'third_party/protobuf': '{chromium_git}/chromium/src/third_party/protobuf',
    'third_party/SwiftShader': 'https://swiftshader.googlesource.com/SwiftShader',
    'third_party/vulkan_memory_allocator': '{chromium_git}/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator',
    'third_party/zlib': '{chromium_git}/chromium/src/third_party/zlib',
    'third_party/astc-encoder/src': '{chromium_git}/external/github.com/ARM-software/astc-encoder',
    'tools/clang': '{chromium_git}/chromium/src/tools/clang.git',

    # Vulkan dependencies
    'third_party/vulkan-deps': '{chromium_git}/vulkan-deps',
    'third_party/vulkan-deps/glslang/src': '{chromium_git}/external/github.com/KhronosGroup/glslang',
    'third_party/vulkan-deps/spirv-cross/src': '{chromium_git}/external/github.com/KhronosGroup/SPIRV-Cross',
    'third_party/vulkan-deps/spirv-headers/src': '{chromium_git}/external/github.com/KhronosGroup/SPIRV-Headers',
    'third_party/vulkan-deps/spirv-tools/src': '{chromium_git}/external/github.com/KhronosGroup/SPIRV-Tools',
    'third_party/vulkan-deps/vulkan-headers/src': '{chromium_git}/external/github.com/KhronosGroup/Vulkan-Headers',
    'third_party/vulkan-deps/vulkan-loader/src': '{chromium_git}/external/github.com/KhronosGroup/Vulkan-Loader',
    'third_party/vulkan-deps/vulkan-tools/src': '{chromium_git}/external/github.com/KhronosGroup/Vulkan-Tools',
    'third_party/vulkan-deps/vulkan-validation-layers/src': '{chromium_git}/external/github.com/KhronosGroup/Vulkan-ValidationLayers',
}

# ============================================================================
# Skia dependencies
# ============================================================================
skia_deps = {
    "third_party/externals/expat": "{chromium_git}/external/github.com/libexpat/libexpat.git",
    "third_party/externals/libjpeg-turbo": "{chromium_git}/chromium/deps/libjpeg_turbo.git",
    "third_party/externals/libpng": "https://skia.googlesource.com/third_party/libpng.git",
    "third_party/externals/libwebp": "{chromium_git}/webm/libwebp.git",
    "third_party/externals/wuffs": "https://skia.googlesource.com/external/github.com/google/wuffs-mirror-release-c.git",
    "third_party/externals/zlib": "{chromium_git}/chromium/src/third_party/zlib",
}

# ============================================================================
# V8 dependencies
# ============================================================================
v8_deps = {
    'base/trace_event/common': '{chromium_git}/chromium/src/base/trace_event/common.git',
    'build': '{chromium_git}/chromium/src/build.git',
    'third_party/googletest/src': '{chromium_git}/external/github.com/google/googletest.git',
    'third_party/jinja2': '{chromium_git}/chromium/src/third_party/jinja2.git',
    'third_party/markupsafe': '{chromium_git}/chromium/src/third_party/markupsafe.git',
    'third_party/zlib': '{chromium_git}/chromium/src/third_party/zlib.git',
    'tools/clang': '{chromium_git}/chromium/src/tools/clang.git',
}

# ============================================================================
# Solutions configuration
# ============================================================================
solutions = [
    {
        "name": "libraries",
        "url": None,
        "managed": False,
        "custom_deps": {
            "libraries/angle": vars['angle_git'] + '@' + vars['angle_commit'],
            "libraries/glfw": vars['glfw_git'] + '@' + vars['glfw_commit'],
            "libraries/libuv": vars['libuv_git'] + '@' + vars['libuv_commit'],
            "libraries/skia": vars['skia_git'] + '@' + vars['skia_commit'],
            "libraries/v8": vars['v8_git'] + '@' + vars['v8_commit'],
        },
    },
]

# Add transitive dependencies
for (k, v) in angle_deps.items():
    solutions[0]['custom_deps']['libraries/angle/' + k] = v

for (k, v) in skia_deps.items():
    solutions[0]['custom_deps']['libraries/skia/' + k] = v

for (k, v) in v8_deps.items():
    solutions[0]['custom_deps']['libraries/v8/' + k] = v

# ============================================================================
# Hooks - run after sync
# ============================================================================
hooks = [
    # -------------------------------------------------------------------------
    # ANGLE hooks (toolchain setup)
    # -------------------------------------------------------------------------
    {
        'cwd': 'libraries/angle',
        'name': 'win_toolchain',
        'pattern': '.',
        'condition': 'checkout_win',
        'action': ['python3', 'build/vs_toolchain.py', 'update', '--force'],
    },
    {
        'cwd': 'libraries/angle',
        'name': 'clang',
        'pattern': '.',
        'action': ['python3', 'tools/clang/scripts/update.py'],
    },
    {
        'cwd': 'libraries/angle',
        'name': 'lastchange',
        'pattern': '.',
        'action': ['python3', 'build/util/lastchange.py', '-o', 'build/util/LASTCHANGE'],
    },
    {
        'cwd': 'libraries/angle',
        'name': 'rc_win',
        'pattern': '.',
        'condition': 'checkout_win',
        'action': [
            'python3', '../depot_tools/download_from_google_storage.py',
            '--no_resume', '--no_auth',
            '--bucket', 'chromium-browser-clang/rc',
            '-s', 'build/toolchain/win/rc/win/rc.exe.sha1',
        ],
    },
    {
        'cwd': 'libraries/angle',
        'name': 'sysroot_x64',
        'pattern': '.',
        'condition': 'checkout_linux',
        'action': ['python3', 'build/linux/sysroot_scripts/install-sysroot.py', '--arch=x64'],
    },

    # -------------------------------------------------------------------------
    # V8 hooks (toolchain setup)
    # -------------------------------------------------------------------------
    {
        'name': 'lastchange',
        'cwd': 'libraries/v8',
        'pattern': '.',
        'action': ['python3', 'build/util/lastchange.py', '-o', 'build/util/LASTCHANGE'],
    },
    {
        'name': 'sysroot_x64',
        'cwd': 'libraries/v8',
        'pattern': '.',
        'condition': 'checkout_linux and checkout_x64',
        'action': ['python3', 'build/linux/sysroot_scripts/install-sysroot.py', '--arch=x64'],
    },
    {
        'name': 'win_toolchain',
        'cwd': 'libraries/v8',
        'pattern': '.',
        'condition': 'checkout_win',
        'action': ['python3', 'build/vs_toolchain.py', 'update', '--force'],
    },
    {
        'name': 'mac_toolchain',
        'cwd': 'libraries/v8',
        'pattern': '.',
        'condition': 'checkout_mac',
        'action': ['python3', 'build/mac_toolchain.py'],
    },
    {
        'name': 'clang',
        'cwd': 'libraries/v8',
        'pattern': '.',
        'condition': 'host_os != "aix"',
        'action': ['python3', 'tools/clang/scripts/update.py'],
    },

    # -------------------------------------------------------------------------
    # V8 build configuration
    # -------------------------------------------------------------------------
    {
        "action": ["python3", "libraries/v8_build.py"],
    },

    # -------------------------------------------------------------------------
    # ANGLE build configuration
    # -------------------------------------------------------------------------
    {
        "action": ["python3", "libraries/angle_build.py"],
    },

    # =========================================================================
    # PATCHES REMOVED FOR 2025 DYNAMIC LINKING BUILD
    # =========================================================================
    # The following patches were previously applied but are NOT NEEDED for
    # dynamic linking builds. See PATCH_ANALYSIS.md for details.
    #
    # For STATIC builds, apply patches manually from libraries/patches/:
    #   - glfw.patch: Static EGL linking, Win32 fiber messaging
    #   - v8.patch: Compiler warning fixes (likely not needed)
    #   - v8_build.patch: C++20 deprecation warnings (Windows only)
    #   - skia.patch: ANGLE static linking, CFI disable
    #   - angle.patch: Static lib config, macOS vsync, D3D11 fixes
    # =========================================================================
]
