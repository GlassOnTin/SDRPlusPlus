cmake_minimum_required(VERSION 3.13)
project(sdrpp_core)

if (USE_INTERNAL_LIBCORRECT)
    add_subdirectory("libcorrect/")
endif (USE_INTERNAL_LIBCORRECT)

if (USE_BUNDLE_DEFAULTS)
add_definitions(-DIS_MACOS_BUNDLE)
endif (USE_BUNDLE_DEFAULTS)

# Main code
file(GLOB_RECURSE SRC "src/*.cpp" "src/*.c")

add_definitions(-DSDRPP_IS_CORE)
add_definitions(-DFLOG_ANDROID_TAG="SDR++")
if (MSVC)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif ()

# Configure backend sources
if (OPT_BACKEND_GLFW)
    file(GLOB_RECURSE BACKEND_SRC "backends/glfw/*.cpp" "backends/glfw/*.c")
endif (OPT_BACKEND_GLFW)
if (OPT_BACKEND_ANDROID)
    file(GLOB_RECURSE BACKEND_SRC "backends/android/*.cpp" "backends/android/*.c")
    set(BACKEND_SRC ${BACKEND_SRC} ${ANDROID_NDK}/sources/android/native_app_glue/android_native_app_glue.c)
endif (OPT_BACKEND_ANDROID)

# Add code to dyn lib
add_library(sdrpp_core SHARED ${SRC} ${BACKEND_SRC})

# Set compiler options
if (MSVC)
    target_compile_options(sdrpp_core PRIVATE
        $<$<CONFIG:Debug>:/Zi /Od /RTC1 /EHsc /std:c++17 /FS>
        $<$<CONFIG:Release>:/O2 /Ob2 /std:c++17 /EHsc /FS>
        $<$<CONFIG:RelWithDebInfo>:/Zi /O2 /Ob1 /EHsc /std:c++17 /DNDEBUG /FS>
        $<$<CONFIG:MinSizeRel>:/Os /Ob1 /EHsc /std:c++17 /DNDEBUG /FS>
    )
    set_target_properties(sdrpp_core PROPERTIES
        COMPILE_PDB_NAME_DEBUG "sdrpp_core_d"
        COMPILE_PDB_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/core/${CMAKE_CFG_INTDIR}"
        COMPILE_PDB_NAME_RELEASE "sdrpp_core"
        COMPILE_PDB_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/core/${CMAKE_CFG_INTDIR}"
        COMPILE_PDB_NAME_RELWITHDEBINFO "sdrpp_core_rdi"
        COMPILE_PDB_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/core/${CMAKE_CFG_INTDIR}"
        COMPILE_PDB_NAME_MINSIZEREL "sdrpp_core_msr"
        COMPILE_PDB_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/core/${CMAKE_CFG_INTDIR}"
    )
    message(STATUS "MSVC: Set /FS compile option, custom PDB names, and PDB output directories for sdrpp_core.")
else()
    target_compile_options(sdrpp_core PRIVATE ${SDRPP_COMPILER_FLAGS})
endif()

# Set the install prefix
target_compile_definitions(sdrpp_core PUBLIC INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}")

# Include core headers
target_include_directories(sdrpp_core PUBLIC "src/")
target_include_directories(sdrpp_core PUBLIC "src/imgui")

# Configure backend includes and libraries
if (OPT_BACKEND_GLFW)
    target_include_directories(sdrpp_core PUBLIC "backends/glfw")
    target_include_directories(sdrpp_core PUBLIC "backends/glfw/imgui")

    if (MSVC)
        # GLFW3
        find_package(glfw3 CONFIG REQUIRED)
        target_link_libraries(sdrpp_core PUBLIC glfw)
    else()
        find_package(PkgConfig)
        pkg_check_modules(GLFW3 REQUIRED glfw3)

        target_include_directories(sdrpp_core PUBLIC ${GLFW3_INCLUDE_DIRS})
        target_link_directories(sdrpp_core PUBLIC ${GLFW3_LIBRARY_DIRS})
        target_link_libraries(sdrpp_core PUBLIC ${GLFW3_LIBRARIES})
    endif()
endif (OPT_BACKEND_GLFW)
if (OPT_BACKEND_ANDROID)
    target_include_directories(sdrpp_core PUBLIC "backends/android")
    target_include_directories(sdrpp_core PUBLIC "backends/android/imgui")
endif (OPT_BACKEND_ANDROID)

# Link to libcorrect
if (USE_INTERNAL_LIBCORRECT)
    target_include_directories(sdrpp_core PUBLIC "libcorrect/include")
    target_link_libraries(sdrpp_core PUBLIC correct_static)
endif (USE_INTERNAL_LIBCORRECT)

if (OPT_OVERRIDE_STD_FILESYSTEM)
    target_include_directories(sdrpp_core PUBLIC "std_replacement")
endif (OPT_OVERRIDE_STD_FILESYSTEM)

if (MSVC)
    # Lib path
    # target_link_directories(sdrpp_core PUBLIC "C:/Program Files/PothosSDR/lib/") # Prefer vcpkg

    # Misc headers
    # target_include_directories(sdrpp_core PUBLIC "C:/Program Files/PothosSDR/include/") # Prefer vcpkg

    # VOLK (Vector-Optimized Library of Kernels)
    # First try vcpkg's volk CONFIG mode
    find_package(volk CONFIG QUIET)
    if(TARGET volk::volk)
        message(STATUS "Found VOLK via vcpkg's volk::volk target")
        target_link_libraries(sdrpp_core PUBLIC volk::volk)
    else()
        # Fallback to manual VOLK installation
        # Note: This requires GNURadio's VOLK library, not Vulkan's VOLK meta-loader
        # See PYTHON_BINDING.md for more information
        
        # Check for custom VOLK installation path via CMake variable
        if(NOT DEFINED VOLK_ROOT)
            # Default location - can be overridden via -DVOLK_ROOT=path
            set(VOLK_ROOT "C:/volk" CACHE PATH "Path to VOLK installation")
        endif()
        
        set(VOLK_INCLUDE_DIR "${VOLK_ROOT}/include")
        if(WIN32)
            set(VOLK_LIBRARY "${VOLK_ROOT}/lib/volk.lib")
        else()
            set(VOLK_LIBRARY "${VOLK_ROOT}/lib/libvolk.so")
        endif()
        
        # Check if the VOLK installation exists
        if(EXISTS "${VOLK_INCLUDE_DIR}/volk/volk.h")
            message(STATUS "Found VOLK include at: ${VOLK_INCLUDE_DIR}")
            if(EXISTS "${VOLK_LIBRARY}")
                message(STATUS "Found VOLK library at: ${VOLK_LIBRARY}")
                target_include_directories(sdrpp_core PUBLIC "${VOLK_INCLUDE_DIR}")
                target_link_libraries(sdrpp_core PUBLIC "${VOLK_LIBRARY}")
            else()
                message(FATAL_ERROR "SDR++ requires the VOLK library. Cannot find VOLK library at ${VOLK_LIBRARY}. Please build and install VOLK from https://github.com/gnuradio/volk or specify VOLK_ROOT.")
            endif()
        else()
            message(FATAL_ERROR "SDR++ requires the VOLK library. Cannot find VOLK headers at ${VOLK_INCLUDE_DIR}/volk/volk.h. Please build and install VOLK from https://github.com/gnuradio/volk or specify VOLK_ROOT.")
        endif()
    endif()

    # OpenGL
    find_package(OpenGL REQUIRED)
    target_link_libraries(sdrpp_core PUBLIC OpenGL::GL)

    # GLFW3
    find_package(glfw3 CONFIG REQUIRED)
    target_link_libraries(sdrpp_core PUBLIC glfw)

    # FFTW3
    find_package(FFTW3f CONFIG REQUIRED)
    target_link_libraries(sdrpp_core PUBLIC FFTW3::fftw3f)

    # WinSock2
    target_link_libraries(sdrpp_core PUBLIC wsock32 ws2_32 iphlpapi)

    # ZSTD
    find_package(zstd CONFIG REQUIRED)
    target_link_libraries(sdrpp_core PUBLIC zstd::libzstd_shared)
elseif (ANDROID)
    target_include_directories(sdrpp_core PUBLIC
        /sdr-kit/${ANDROID_ABI}/include
        ${ANDROID_NDK}/sources/android/native_app_glue
    )

    target_link_libraries(sdrpp_core PUBLIC
        /sdr-kit/${ANDROID_ABI}/lib/libvolk.so
        /sdr-kit/${ANDROID_ABI}/lib/libfftw3f.so
        /sdr-kit/${ANDROID_ABI}/lib/libzstd.so
        android
        EGL
        GLESv3
        log
    )
else()
    find_package(PkgConfig)
    find_package(OpenGL REQUIRED)

    pkg_check_modules(FFTW3 REQUIRED fftw3f)
    pkg_check_modules(VOLK REQUIRED volk)
    pkg_check_modules(GLFW3 REQUIRED glfw3)
    pkg_check_modules(LIBZSTD REQUIRED libzstd)

    target_include_directories(sdrpp_core PUBLIC
        ${OPENGL_INCLUDE_DIRS}
        ${FFTW3_INCLUDE_DIRS}
        ${GLFW3_INCLUDE_DIRS}
        ${VOLK_INCLUDE_DIRS}
        ${LIBZSTD_INCLUDE_DIRS}
    )
    
    target_link_directories(sdrpp_core PUBLIC
        ${OPENGL_LIBRARY_DIRS}
        ${FFTW3_LIBRARY_DIRS}
        ${GLFW3_LIBRARY_DIRS}
        ${VOLK_LIBRARY_DIRS}
        ${LIBZSTD_LIBRARY_DIRS}
    )

    target_link_libraries(sdrpp_core PUBLIC
        ${OPENGL_LIBRARIES}
        ${FFTW3_LIBRARIES}
        ${GLFW3_LIBRARIES}
        ${VOLK_LIBRARIES}
        ${LIBZSTD_LIBRARIES}
    )

    if (NOT USE_INTERNAL_LIBCORRECT)
        pkg_check_modules(CORRECT REQUIRED libcorrect)
        target_include_directories(sdrpp_core PUBLIC ${CORRECT_INCLUDE_DIRS})
        target_link_directories(sdrpp_core PUBLIC ${CORRECT_LIBRARY_DIRS})
        target_link_libraries(sdrpp_core PUBLIC ${CORRECT_LIBRARIES})
    endif (NOT USE_INTERNAL_LIBCORRECT)

    if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        target_link_libraries(sdrpp_core PUBLIC stdc++fs)
    endif ()

endif ()

set(CORE_FILES ${RUNTIME_OUTPUT_DIRECTORY} PARENT_SCOPE)

# cmake .. "-DCMAKE_TOOLCHAIN_FILE=C:/dev/vcpkg/scripts/buildsystems/vcpkg.cmake"

# Install directives
install(TARGETS sdrpp_core DESTINATION lib)