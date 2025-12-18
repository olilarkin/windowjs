# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**Prerequisites:** Git, CMake 3.15+, and platform-specific tools (Visual Studio 2022 on Windows, Xcode on macOS, clang on Linux).

**Initial Setup (macOS/Linux):**
```bash
source libraries/setup_build_env.sh
./libraries/sync.sh
./libraries/build_angle.sh
./libraries/build_skia.sh
./libraries/build_v8.sh
```

**Configure and Build:**
```bash
cmake -S. -B out -DCMAKE_BUILD_TYPE=Release -G Ninja
cmake --build out
```

**Run:**
```bash
out/windowjs examples/breakout.js
```

## Testing

```bash
out/windowjs tests/run_tests.js
```

Run specific test file and function:
```bash
out/windowjs tests/run_tests.js -- test_file.js functionName
```

Tests use pixel diffs against golden images. Generate new goldens in Chrome via `tests/canvas.html` (requires `npx http-server`).

## Architecture

Window.js is a JavaScript runtime for desktop graphics programming, built on:
- **v8** - JavaScript engine
- **GLFW** - Window creation and input handling
- **Skia** - 2D graphics (HTML5 Canvas API implementation)
- **ANGLE** - OpenGL ES to native graphics translation

### Core Components (src/)

- **Main** (`main.cc/h`) - Application entry point and main loop. Implements `Js::Delegate` and `Window::Delegate` interfaces to handle JS events and window callbacks. Owns the TaskQueue, Window, Js, and JsApi instances.

- **Js** (`js.cc/h`) - v8 isolate and context wrapper. Manages ES module loading/resolution, promise rejection handling, and provides the bridge between C++ and JavaScript.

- **JsApi** (`js_api.cc/h`) - Custom JavaScript APIs exposed to v8. Handles `setTimeout`, `requestAnimationFrame`, event listeners, font loading. Uses `PostToBackgroundAndResolve()` pattern for async operations.

- **Window** (`window.cc/h`) - GLFW window wrapper. Manages the window lifecycle, input callbacks, rendering, and owns the Canvas for drawing.

- **Canvas** (`canvas.cc/h`) - Skia-based HTML5 Canvas API implementation.

- **JsApiWrapper** - Base class for C++ objects exposed to JavaScript. Supports weak/strong reference semantics for GC integration.

### API Bindings (src/js_api_*.cc)

Each `js_api_*.cc` file exposes a specific API surface:
- `js_api_canvas.cc` - CanvasRenderingContext2D, ImageData, ImageBitmap, Path2D
- `js_api_codec.cc` - Image encoding/decoding
- `js_api_file.cc` - File system access
- `js_api_process.cc` - Process spawning and IPC

### Threading Model

- Main thread runs the v8 isolate and GLFW event loop
- `TaskQueue` posts tasks to main thread
- `ThreadPoolTaskQueue` runs async work (file I/O, image decoding)
- Background tasks return a `ResolveFunction` that executes on main thread to resolve promises

### Memory Management

Enable AddressSanitizer by uncommenting `-fsanitize=address` in `src/CMakeLists.txt` and doing a Debug build. Use `LSAN_OPTIONS=suppressions=libraries/asan-linux-suppressions.txt` to suppress external library leaks.
