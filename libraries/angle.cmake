# ANGLE CMake configuration (2025)
# Supports both static and dynamic linking via WINDOWJS_STATIC option

add_library(angle INTERFACE)

target_include_directories(angle INTERFACE "${PROJECT_SOURCE_DIR}/libraries/angle/include")

set(ANGLE_OUT_DIR "${PROJECT_SOURCE_DIR}/libraries/angle/out/Release")

# Use same option as v8.cmake
if(NOT DEFINED WINDOWJS_STATIC)
    option(WINDOWJS_STATIC "Build with static linking" OFF)
endif()

if(WINDOWJS_STATIC)
    # Static linking - use static ANGLE definitions
    target_compile_definitions(angle INTERFACE
        ANGLE_EXPORT=
        ANGLE_STATIC=1
        ANGLE_UTIL_EXPORT=
        EGLAPI=
        GL_APICALL=
        GL_API=
    )

    if(WIN32)
        target_link_libraries(angle INTERFACE
            ${ANGLE_OUT_DIR}/obj/libEGL_static.lib
            dxguid.lib
            dxgi.lib
        )
    elseif(APPLE)
        target_link_libraries(angle INTERFACE
            ${ANGLE_OUT_DIR}/obj/libEGL_static.a
            "-framework Foundation"
            "-framework IOKit"
            "-framework CoreFoundation"
            "-framework CoreGraphics"
            "-framework OpenGL"
            "-framework IOSurface"
            "-framework QuartzCore"
            "-framework Cocoa"
            "-framework Metal"
            "-framework MetalKit"
        )
    else()
        # Linux
        target_link_libraries(angle INTERFACE
            ${ANGLE_OUT_DIR}/obj/libEGL_static.a
            atomic
            dl
            pthread
            rt
            X11
            Xext
            xcb
        )
    endif()
else()
    # Dynamic linking (component build)
    # No static definitions needed - using DLL exports

    if(WIN32)
        target_link_libraries(angle INTERFACE
            "${ANGLE_OUT_DIR}/libEGL.dll.lib"
            "${ANGLE_OUT_DIR}/libGLESv2.dll.lib"
            dxguid.lib
            dxgi.lib
        )
    elseif(APPLE)
        target_link_libraries(angle INTERFACE
            "${ANGLE_OUT_DIR}/libEGL.dylib"
            "${ANGLE_OUT_DIR}/libGLESv2.dylib"
            "-framework Foundation"
            "-framework IOKit"
            "-framework CoreFoundation"
            "-framework CoreGraphics"
            "-framework OpenGL"
            "-framework IOSurface"
            "-framework QuartzCore"
            "-framework Cocoa"
            "-framework Metal"
            "-framework MetalKit"
        )
    else()
        # Linux
        target_link_libraries(angle INTERFACE
            "${ANGLE_OUT_DIR}/libEGL.so"
            "${ANGLE_OUT_DIR}/libGLESv2.so"
            dl
            pthread
            X11
            Xext
            xcb
        )
    endif()
endif()
