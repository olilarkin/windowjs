# CI Build Fix Status - PR #7

## Current Status (2026-01-02)

### Passing
- **macOS**: Consistently passing
- **Linux GCC**: PASSING (run 20659167298, 51m39s)

### Failing
- **Linux clang**: Failed due to cached build without `<algorithm>` fix - should pass on next run
- **Windows**: Failing at ANGLE build (~9 mins) due to SDK version mismatch

## Fixes Applied

1. **v8 WebAssembly GCC 13 compatibility** (`libraries/v8-args-linux.gn`)
   - Added `v8_enable_webassembly = false` to avoid template instantiation errors with incomplete types

2. **Missing include** (`src/js_events.cc`)
   - Added `#include <algorithm>` for `std::find` and `std::remove`

3. **ANGLE warnings-as-errors** (`libraries/angle-args-linux.gn`)
   - Added `treat_warnings_as_errors = false` for GCC 12+ C++20 deprecation warnings

4. **v8 system toolchain** (`libraries/v8-args-linux.gn`)
   - Added `use_sysroot = false`, `is_clang = false`, `use_custom_libcxx = false`

## Outstanding Issue: Windows ANGLE SDK

**Problem**: ANGLE's `setup_toolchain.py` calls `vcvarsall.bat` internally for different architectures (x86, x64). Visual Studio on GitHub runners defaults to SDK 10.0.22621.0, but only 10.0.26100.0 is installed.

**Error**:
```
Exception: Path "C:\Program Files (x86)\Windows Kits\10\\include\10.0.22621.0\\um"
from environment variable "include" does not exist.
```

**Attempted fixes that didn't work**:
- Setting `windows_sdk_version` in GN args
- Setting `WindowsSDKVersion`, `WindowsSDKDir`, `UCRTVersion` environment variables
- Patching INCLUDE/LIB paths after vcvarsall.bat

**Potential solutions to try**:
1. Install Windows SDK 10.0.22621.0 via chocolatey or winget
2. Patch ANGLE's `build/toolchain/win/setup_toolchain.py` to skip missing paths (needs proper patch format)
3. Use VS Developer PowerShell action to properly configure environment
4. Modify VS installation to use the installed SDK as default

## Files Modified

- `.github/workflows/windows-build.yml` - Added gn download, ninja install, SDK debugging
- `.github/workflows/linux-build.yml` - Added libglib2.0-dev, libpci-dev packages
- `.github/workflows/linux-build-gcc.yml` - Same package additions
- `libraries/v8-args-linux.gn` - WebAssembly disable, system toolchain flags
- `libraries/angle-args-linux.gn` - System sysroot, GCC, warnings-as-errors disable
- `libraries/angle-args-windows.gn` - Removed hardcoded SDK version
- `libraries/skia-args-windows.gn` - MSVC instead of clang
- `libraries/setup_build_env.ps1` - SDK detection, environment variable setup
- `src/js_events.cc` - Added `<algorithm>` include
