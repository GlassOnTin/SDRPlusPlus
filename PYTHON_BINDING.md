# SDR++ Build Guide with Python Bindings

This document covers the process of building SDR++ with Python bindings on Windows, including solutions to common issues encountered during the build process.

## Prerequisites

- Visual Studio 2022 with C++ workload
- CMake 3.13 or higher
- Git
- Python 3.x with development headers
- SWIG 4.x
- vcpkg for managing dependencies

## Building the Core SDR++ Application

### Step 1: Clone the SDR++ Repository

```bash
git clone https://github.com/AlexandreRouma/SDR-plus-plus.git
cd SDR-plus-plus
```

### Step 2: Install Dependencies with vcpkg

First, ensure vcpkg is properly installed and bootstrapped:

```bash
# Clone vcpkg if you don't have it
git clone https://github.com/microsoft/vcpkg.git C:/dev/vcpkg
cd C:/dev/vcpkg
.\bootstrap-vcpkg.bat

# Install dependencies using vcpkg
.\vcpkg install glfw3 fftw3 zstd
```

### Step 3: Build VOLK Library Manually

You need to build the Vector-Optimized Library of Kernels (VOLK), which is different from the Vulkan meta loader also named "volk" in vcpkg.

```bash
# Clone VOLK repository
git clone https://github.com/gnuradio/volk.git
cd volk

# Initialize submodules
git submodule update --init

# Install Python Mako templates (if not already installed)
pip install mako

# Build VOLK
mkdir build
cd build
cmake -B . -S .. -DCMAKE_INSTALL_PREFIX=C:/volk
cmake --build . --config Release
cmake --build . --target install --config Release
```

### Step 4: Configure and Build SDR++

Create a build directory and configure the project:

```bash
# Create build directory
mkdir build_sdrpp
cd build_sdrpp

# Configure with CMake

# Basic configuration
cmake -B . -S .. -DCMAKE_TOOLCHAIN_FILE=C:/dev/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_POLICY_VERSION_MINIMUM="3.5"

# Build the project

# If you needed to use explicit package paths in the configure step,
# the build command remains the same
cmake --build . --config Release
```

### Step 5: Set Up the Runtime Environment

1. Copy the DLLs to the application directory:

```powershell
# Copy all module DLLs to the modules directory
mkdir -Force build_sdrpp\Release\modules
Copy-Item build_sdrpp\decoder_modules\*\Release\*.dll build_sdrpp\Release\modules\
Copy-Item build_sdrpp\sink_modules\*\Release\*.dll build_sdrpp\Release\modules\
Copy-Item build_sdrpp\source_modules\*\Release\*.dll build_sdrpp\Release\modules\
Copy-Item build_sdrpp\misc_modules\*\Release\*.dll build_sdrpp\Release\modules\

# Copy resources
xcopy /s /y root build_sdrpp\Release\

# Copy VOLK DLL
Copy-Item C:\volk\bin\volk.dll build_sdrpp\Release\
```

1. Create a basic configuration file (config.json):

```json
{
    "bandManager": {
        "enabled": true,
        "source": "general"
    },
    "bandPlan": {
        "enableCustomBands": false,
        "customBands": []
    },
    "discord": {
        "enabled": false
    },
    "frequency": 97500000,
    "modules": [
        "audio_sink",
        "meteor_demodulator",
        "radio",
        "recorder",
        "scanner",
        "sdrplay_source",
        "spyserver_source"
    ],
    "moduleInstances": {},
    "theme": "dark",
    "sourceName": "spyserver",
    "spacing": 10.0,
    "gui": {
        "windowSize": {
            "w": 1280,
            "h": 720
        }
    },
    "colorMap": "turbo",
    "configVersion": 3
}
```

## Python Bindings (Advanced)

The Python bindings in SDR++ use SWIG to generate Python wrappers for the C++ core. Building these bindings involves additional challenges.

### Common Issues and Solutions

1. **nlohmann::json Issue**:  
   The main challenge with the Python bindings is handling the nlohmann::json library through SWIG.

1. **Approach 1: Disable JSON in SWIG Interface**:
   Modify the SWIG interface files to avoid direct exposure of nlohmann::json objects:

   ```cpp
   // In json_helper.h
   #ifndef SWIG
   // Only include in C++ code, not in SWIG parsing
   #include "../../core/src/json.hpp"
   // JSON methods go here
   #endif
   
   // Provide string-only methods for SWIG
   ```

2. **Approach 2: Use Python's JSON Module**:
   Create a typemap that converts between nlohmann::json and Python's native JSON objects.

3. **Approach 3: Simplified Implementation**:
   Create a simplified Python binding layer that focuses only on the most essential functionality and avoids complex C++ features like templated classes and modern C++ features that SWIG struggles with.

### Building Python Bindings

To enable Python bindings (once issues are resolved):

1. Modify the main CMakeLists.txt:

```cmake
# Python SWIG bindings
option(OPT_BUILD_PYTHON_BINDINGS "Build Python SWIG bindings" ON)
if (OPT_BUILD_PYTHON_BINDINGS)
add_subdirectory("python_swig_bindings")
endif (OPT_BUILD_PYTHON_BINDINGS)
```

1. Configure CMake with Python development components found:

```bash
cmake -B build_sdrpp -S . -DCMAKE_TOOLCHAIN_FILE=C:/dev/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_POLICY_VERSION_MINIMUM="3.5"
```

2. Build the project with Python bindings enabled:

```bash
cmake --build build_sdrpp --config Release
```

## Troubleshooting

1. **Missing VOLK Library**: Ensure you've built the correct VOLK library (Vector-Optimized Library of Kernels), not the Vulkan meta loader that's available in vcpkg.

2. **Missing DLLs**: Make sure all required DLLs are in the correct locations. The main application needs access to both the core DLLs and the module DLLs.

3. **JSON Parsing Issues in Python Bindings**: Consider using string-based interfaces instead of direct nlohmann::json objects in SWIG interfaces.

4. **Module Loading Failures**: Check that modules are correctly built and placed in the 'modules' directory relative to the executable.

5. **CMake Can't Find vcpkg Packages**: On Windows, CMake might fail to find packages installed via vcpkg despite using the toolchain file. If you encounter errors like `Could not find a package configuration file provided by "glfw3"`, try explicitly setting the package configuration paths:

   ```bash
   # Full configuration command with explicit package paths
   cmake -B . -S .. \
       -DCMAKE_TOOLCHAIN_FILE=C:/dev/vcpkg/scripts/buildsystems/vcpkg.cmake \
       -DCMAKE_POLICY_VERSION_MINIMUM="3.5" \
       -DVOLK_ROOT=C:/volk \
       -Dglfw3_DIR=C:/dev/vcpkg/installed/x64-windows/share/glfw3 \
       -DFFTW3f_DIR=C:/dev/vcpkg/installed/x64-windows/share/fftw3f \
       -Dzstd_DIR=C:/dev/vcpkg/installed/x64-windows/share/zstd
   ```
   
   The package configuration files are typically located in subdirectories of `C:/dev/vcpkg/installed/x64-windows/share/`.
   
   You can verify the existence of these files with: `dir "C:\dev\vcpkg\installed\x64-windows\share\glfw3"`.

## Alternative Approaches for Python Integration

If SWIG continues to be problematic, consider these alternatives:

1. **Direct ctypes Binding**: Create a simpler C-style API for SDR++ and use Python's ctypes to interface with it.

2. **pybind11**: Consider using pybind11 instead of SWIG, as it often handles modern C++ features better.

3. **Simplified API**: Create a purpose-built, simplified C++ API specifically for Python integration that avoids complex C++ features.

## Contributing Changes to the Main Repository

If you plan to submit a pull request to the main SDR++ repository with Windows build improvements, follow these guidelines to increase the chances of your PR being accepted:

1. **Minimal Changes**: Focus only on the changes necessary to make the build work on Windows. Avoid unrelated code style or feature changes.

2. **Flexible Configuration**:
   - Use conditional compilation (`if (MSVC)`) for Windows-specific code
   - Provide fallback mechanisms for cross-platform compatibility
   - Use CMake variables with sensible defaults (e.g., `VOLK_ROOT` with a clear description)

3. **Clear Documentation**:
   - Document Windows-specific build steps in this file
   - Include comments in CMake files explaining Windows-specific workarounds
   - Explain any manual steps required (such as building VOLK library)

4. **Testing**:
   - Verify your changes work on a clean Windows environment
   - Ensure the original Linux/macOS build process is unaffected
   - Test with both vcpkg and manually built dependencies

5. **PR Description**:
   - Clearly explain the Windows build issues you've solved
   - Reference any relevant issues in the issue tracker
   - Include screenshots of the working application if relevant
