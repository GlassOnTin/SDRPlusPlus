cmake_minimum_required(VERSION 3.13)
project(sdrpp_python_bindings)

# Find SWIG
find_package(SWIG REQUIRED)
include(${SWIG_USE_FILE})

# Find Python
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
include_directories(${Python3_INCLUDE_DIRS})

# Include directories - include the core src directory to find all headers
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../
    ${CMAKE_CURRENT_SOURCE_DIR}/../core/src
)

# Define compile definitions to handle third-party dependencies
add_compile_definitions(SWIG_BUILDING DSP_STREAM_H)

# SWIG wrapper module sources
set(SWIG_MODULE_SOURCES
    sdrpp_core.i
    managers/config_manager.i
    managers/source_manager.i
    managers/vfo_manager.i
    dsp/stream.i
)

# Set SWIG properties
set_property(SOURCE sdrpp_minimal.i PROPERTY CPLUSPLUS ON)
set_property(SOURCE sdrpp_minimal.i PROPERTY SWIG_MODULE_NAME _sdrpp)

# Configure SWIG output directory
set(CMAKE_SWIG_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/_sdrpp)

# Add SWIG module
swig_add_library(_sdrpp 
    TYPE MODULE
    LANGUAGE python 
    SOURCES sdrpp_minimal.i
)

# Link against SDR++ core library
target_link_libraries(_sdrpp PRIVATE 
    sdrpp_core
    ${Python3_LIBRARIES}
)

# Windows-specific settings
if(WIN32)
    # Add Windows-specific libraries if needed
    # target_link_libraries(_sdrpp PRIVATE ws2_32)
    
    # Set the output directory for Windows builds
    set_target_properties(_sdrpp PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/_sdrpp
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/_sdrpp
    )
endif()

# Install targets
install(TARGETS _sdrpp DESTINATION ${Python3_SITEARCH})

# Copy Python test files - ensure directory exists first
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests)
file(GLOB TEST_FILES "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.py")
file(COPY ${TEST_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/tests)

# Add a custom target for running the tests
add_custom_target(run_sdrpp_python_tests
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/tests/test_sdrplay_basic.py
    DEPENDS _sdrpp
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Running SDR++ Python bindings tests"
)

message(STATUS "Python bindings build configured for SDR++")
message(STATUS "Python interpreter: ${Python3_EXECUTABLE}")
message(STATUS "Python include dirs: ${Python3_INCLUDE_DIRS}")
message(STATUS "Python libraries: ${Python3_LIBRARIES}")
