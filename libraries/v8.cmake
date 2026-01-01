# V8 CMake configuration (2025)
# Supports both static and dynamic linking via WINDOWJS_STATIC option

add_library(v8 INTERFACE)

target_include_directories(v8 INTERFACE
    "${PROJECT_SOURCE_DIR}/libraries/v8/include"
    "${PROJECT_SOURCE_DIR}/libraries/v8"
    "${PROJECT_SOURCE_DIR}/libraries"
)

target_compile_definitions(v8 INTERFACE
    V8_COMPRESS_POINTERS
    V8_ENABLE_SANDBOX=0
)

set(V8_OUT_DIR "${PROJECT_SOURCE_DIR}/libraries/v8/out/Release")

option(WINDOWJS_STATIC "Build with static linking" OFF)

if(WINDOWJS_STATIC)
    # Static linking (monolithic build)
    if(WIN32)
        target_link_libraries(v8 INTERFACE
            ${V8_OUT_DIR}/obj/v8_monolith.lib
            DbgHelp.dll
            WinMM.dll
        )
    else()
        target_link_libraries(v8 INTERFACE
            ${V8_OUT_DIR}/obj/libv8_monolith.a
            pthread
            dl
        )
        if(NOT APPLE)
            target_link_libraries(v8 INTERFACE atomic)
        endif()
    endif()
else()
    # Dynamic linking (component build)
    if(WIN32)
        target_link_libraries(v8 INTERFACE
            "${V8_OUT_DIR}/v8.dll.lib"
            "${V8_OUT_DIR}/v8_libplatform.dll.lib"
            "${V8_OUT_DIR}/v8_libbase.dll.lib"
            DbgHelp.lib
            WinMM.lib
        )
        # Define V8 shared library exports
        target_compile_definitions(v8 INTERFACE
            USING_V8_SHARED
        )
    elseif(APPLE)
        target_link_libraries(v8 INTERFACE
            "${V8_OUT_DIR}/libv8.dylib"
            "${V8_OUT_DIR}/libv8_libplatform.dylib"
            "${V8_OUT_DIR}/libv8_libbase.dylib"
        )
    else()
        # Linux
        target_link_libraries(v8 INTERFACE
            "${V8_OUT_DIR}/libv8.so"
            "${V8_OUT_DIR}/libv8_libplatform.so"
            "${V8_OUT_DIR}/libv8_libbase.so"
            pthread
            dl
            atomic
        )
    endif()
endif()
