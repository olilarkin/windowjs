# Patch Analysis and Migration Guide (2025)

This document analyzes the patches previously applied to Window.js dependencies and provides guidance for the 2025 modernization effort.

---

## Summary

| Patch | Purpose | 2025 Status | Action |
|-------|---------|-------------|--------|
| `v8.patch` | Compiler warning fixes | Likely fixed upstream | Remove, test without |
| `v8_build.patch` | C++20 deprecation warnings | May still be needed on Windows | Conditional |
| `skia.patch` | ANGLE static linking + CFI fix | Needed for static builds only | Conditional |
| `angle.patch` | macOS vsync + static lib + D3D11 fix | Partially needed | Split into parts |
| `glfw.patch` | Static EGL + Win32 fiber + X11 fix | Complex - multiple features | Split into parts |

---

## Detailed Analysis

### 1. v8.patch (36 lines)

**Changes:**

#### 1.1 Comment formatting fix (src/common/globals.h)
```diff
-#endif  // defined(USE_SIMULATOR) && \
-        // (defined(V8_TARGET_ARCH_ARM64) || defined(V8_TARGET_ARCH_MIPS64) || \
+#endif  // defined(USE_SIMULATOR) &&
+        // (defined(V8_TARGET_ARCH_ARM64) || defined(V8_TARGET_ARCH_MIPS64) ||
```
- **Purpose**: Removes trailing backslashes from comment lines that trigger compiler warnings
- **2025 Status**: Likely fixed upstream - this was a code style issue
- **Action**: Remove - test if warning still occurs

#### 1.2 offsetof warning suppression (src/deoptimizer/deoptimizer.h)
```cpp
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
// ... offsetof() calls on non-POD types ...
#pragma clang diagnostic pop
```
- **Purpose**: Suppresses Clang warning about `offsetof()` on non-standard-layout types
- **2025 Status**: V8 may still use this pattern internally
- **Action**: Remove and test - if warning appears, add to compile flags instead:
  ```cmake
  target_compile_options(windowjs PRIVATE -Wno-invalid-offsetof)
  ```

---

### 2. v8_build.patch (13 lines)

**Changes:**

#### 2.1 C++20 deprecation warnings (build/config/win/BUILD.gn)
```gn
cflags += [ "/D_SILENCE_ALL_CXX20_DEPRECATION_WARNINGS" ]
```
- **Purpose**: Silences MSVC warnings about deprecated C++20 features
- **2025 Status**: May still be needed for Windows MSVC builds
- **Action**: Add to GN args instead of patching:
  ```gn
  # In v8-args-windows.gn
  extra_cflags = [ "/D_SILENCE_ALL_CXX20_DEPRECATION_WARNINGS" ]
  ```

---

### 3. skia.patch (36 lines)

**Changes:**

#### 3.1 ANGLE static linking (BUILD.gn)
```diff
-      libs += [ "EGL" ]
+      # libs += [ "EGL" ]
+      public_include_dirs += [ "../angle/include" ]
+      public_defines += [ "KHRONOS_STATIC" ]
```
- **Purpose**: Links against static ANGLE instead of system EGL
- **2025 Status**:
  - **Dynamic builds**: NOT NEEDED - Skia links against libEGL.dylib/so/dll
  - **Static builds**: STILL NEEDED
- **Action**: This should be controlled via GN args, not patches. Add to `skia-args-*.gn`:
  ```gn
  # For static ANGLE linking
  skia_use_angle = true
  # Path configured in BUILD.gn via include_dirs
  ```

#### 3.2 CFI sanitizer disable (include/private/base/SkTArray.h)
```diff
-    SK_NO_SANITIZE("cfi")
+    //SK_NO_SANITIZE("cfi")
```
- **Purpose**: Disables Control Flow Integrity sanitizer for a specific function
- **2025 Status**: This was likely a workaround for a Clang CFI issue
- **Action**: Remove - CFI is typically disabled in release builds anyway. If needed:
  ```gn
  # In skia-args-*.gn
  is_cfi = false
  ```

---

### 4. angle.patch (392 lines) - COMPLEX

This patch contains multiple distinct changes that should be handled separately:

#### 4.1 Static library configuration (BUILD.gn)
```gn
libEGL_template("libEGL_static") {
  complete_static_lib = true
  suppressed_configs = [ "//build/config/compiler:thin_archive" ]
  ...
}
```
- **Purpose**: Ensures static library contains all required symbols
- **2025 Status**:
  - **Dynamic builds**: NOT NEEDED
  - **Static builds**: STILL NEEDED
- **Action**: Keep for static builds only. Consider contributing upstream.

#### 4.2 Clang exit-time-destructor warning (src/libANGLE/renderer/d3d/d3d11/Renderer11.cpp)
```cpp
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wexit-time-destructors"
    static std::mutex gMutex;
#pragma clang diagnostic pop
```
- **Purpose**: Suppresses warning about static destructor
- **2025 Status**: May be fixed upstream or warning disabled globally
- **Action**: Add to compile flags if needed:
  ```gn
  extra_cflags = [ "-Wno-exit-time-destructors" ]
  ```

#### 4.3 SwapChain D3D11 resize fix (src/libANGLE/renderer/d3d/d3d11/SwapChain11.cpp)
```cpp
// This causes invalid draws during resizes:
// swapRect(displayD3D, 0, 0, backbufferWidth, backbufferHeight);
```
- **Purpose**: Fixes visual artifacts during window resize on Windows
- **2025 Status**: May be fixed upstream
- **Action**: Test without this change first. If artifacts occur, consider:
  1. Checking if ANGLE has fixed this
  2. Reporting upstream if still needed
  3. Handling resize synchronization in Window.js code

#### 4.4 macOS CGL/CVDisplayLink vsync implementation (CRITICAL)
Files: `DisplayCGL.mm`, `WindowSurfaceCGL.h`, `WindowSurfaceCGL.mm`

This is a significant feature implementation:
- Adds CVDisplayLink-based vsync synchronization
- Implements `waitClient()` for proper resize handling
- Adds `waitForVsync()` for frame timing
- Fixes minSwapInterval to allow vsync disable (0)
- Prevents red borders during window resize

**2025 Status**: This is Window.js-specific functionality that may not be upstream

**Action Options**:
1. **Preferred**: Check if ANGLE has improved macOS vsync support in 2025
2. **If still needed**: Maintain as a separate patch file with clear documentation
3. **Alternative**: Implement vsync handling in Window.js layer instead of ANGLE

---

### 5. glfw.patch (577 lines) - VERY COMPLEX

This patch contains multiple distinct features:

#### 5.1 Static EGL linking (egl_context.c, egl_context.h, src/CMakeLists.txt)

Replaces dynamic EGL loading with static linking:
```c
// Instead of dlopen/dlsym for EGL functions:
_glfw.egl.GetConfigAttrib = eglGetConfigAttrib;
_glfw.egl.GetConfigs = eglGetConfigs;
// ... etc
```

- **Purpose**: Required for static ANGLE linking
- **2025 Status**:
  - **Dynamic builds**: NOT NEEDED - use standard EGL loading
  - **Static builds**: STILL NEEDED
- **Action**: This could be made conditional via a GLFW compile flag

#### 5.2 Win32 fiber-based message processing (FEATURE)

Files: `init.c`, `internal.h`, `win32_init.c`, `win32_platform.h`, `win32_window.c`, `docs/intro.dox`, `include/GLFW/glfw3.h`

Adds `GLFW_WIN32_MESSAGES_IN_FIBER` init hint that:
- Processes Windows messages in a separate fiber
- Allows rendering during window move/resize operations
- Prevents application freeze during modal operations

- **Purpose**: Critical feature for smooth Windows rendering
- **2025 Status**:
  - Check if GLFW 3.4 has this feature
  - If not, this is a significant feature that should be maintained
- **Action**:
  1. Check GLFW 3.4 changelog for similar functionality
  2. If not present, consider contributing upstream
  3. Maintain as a feature patch with documentation

#### 5.3 X11 EGL termination order fix (x11_init.c)
```c
// This needs to be called before XCloseDisplay for ANGLE.
_glfwTerminateEGL();
```
- **Purpose**: Fixes crash when using ANGLE on X11/Linux
- **2025 Status**: Likely still needed
- **Action**: Keep as a simple one-line patch or contribute upstream

#### 5.4 APIENTRY redefinition (win32_platform.h)
```c
#undef APIENTRY
#define APIENTRY
```
- **Purpose**: Avoids conflicts between Windows headers and ANGLE headers
- **2025 Status**: May still be needed
- **Action**: Test without - add back if conflicts occur

#### 5.5 Window title bar click handling (win32_window.c)
Part of the fiber message processing feature - tracks non-client area mouse events.

---

## Recommended Migration Path

### For Dynamic Linking (Default 2025 Build)

**Remove these patches entirely:**
- `v8.patch` - compiler warnings likely fixed
- `v8_build.patch` - handle via GN args
- `skia.patch` - not needed for dynamic linking
- `angle.patch` - static library parts not needed; test macOS without vsync patch
- `glfw.patch` - static EGL parts not needed; keep fiber feature if desired

**Changes needed without patches:**

1. **GLFW static EGL** → Use dynamic EGL loading (no change needed)
2. **Skia ANGLE include** → Configure via Skia GN args or use EGL discovery
3. **ANGLE static lib** → Link against dynamic libEGL/libGLESv2

### For Static Linking (Optional Release Build)

Maintain minimal patches:
1. `skia-static.patch` - ANGLE include paths and KHRONOS_STATIC
2. `angle-static.patch` - complete_static_lib configuration
3. `glfw-static-egl.patch` - static EGL function binding

### Feature Patches (Keep Regardless of Linking)

1. **Win32 fiber messaging** - if not in GLFW 3.4, maintain `glfw-win32-fiber.patch`
2. **macOS vsync** - if ANGLE doesn't support it, maintain `angle-macos-vsync.patch`
3. **X11 termination order** - maintain as `glfw-x11-angle.patch`

---

## Testing Checklist

When building without patches, verify:

- [ ] V8 compiles without warnings (test on all platforms)
- [ ] Skia finds and links EGL correctly
- [ ] ANGLE builds and links correctly
- [ ] GLFW EGL context creation works
- [ ] Window resize doesn't show artifacts (Windows D3D11)
- [ ] Window resize doesn't show red borders (macOS)
- [ ] Vsync works correctly (all platforms)
- [ ] Window move/resize doesn't freeze app (Windows)
- [ ] Application shutdown doesn't crash (X11 Linux)

---

## Files to Create (if maintaining patches)

```
libraries/patches/
├── README.md                    # This document
├── optional/
│   ├── glfw-win32-fiber.patch   # Win32 fiber messaging feature
│   └── angle-macos-vsync.patch  # macOS CVDisplayLink vsync
└── static-build/
    ├── skia-static.patch        # ANGLE static linking for Skia
    ├── angle-static.patch       # ANGLE static library config
    └── glfw-static-egl.patch    # GLFW static EGL binding
```
