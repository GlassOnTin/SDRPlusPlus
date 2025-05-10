@echo off
REM Build script for SDR++ Python SWIG bindings
REM This script only builds the module without running tests

echo === Building SDR++ Python SWIG Bindings ===

REM Create build directory if it doesn't exist
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake .. ^
    -DOPT_BUILD_SDRPLAY_SOURCE=ON ^
    -DOPT_BUILD_PYTHON_BINDINGS=ON ^
    -DCMAKE_BUILD_TYPE=Debug

REM Build the project with more verbose output
echo Building SDR++...
cmake --build . --config Debug --verbose

REM Copy MSVC runtime DLLs if needed
echo.
echo === Copying Dependencies ===
if exist "%VCToolsRedistDir%\x64\Microsoft.VC143.CRT\vcruntime140.dll" (
  echo Copying Microsoft Visual C++ Runtime...
  copy "%VCToolsRedistDir%\x64\Microsoft.VC143.CRT\vcruntime140.dll" python_swig_bindings\sdrpp\
  copy "%VCToolsRedistDir%\x64\Microsoft.VC143.CRT\vcruntime140_1.dll" python_swig_bindings\sdrpp\
  copy "%VCToolsRedistDir%\x64\Microsoft.VC143.CRT\msvcp140.dll" python_swig_bindings\sdrpp\
)

REM Copy any SDR++ core DLLs needed
echo Copying SDR++ core dependencies...
for %%f in (..\..\..\core\bin\Debug\*.dll) do copy %%f python_swig_bindings\sdrpp\

REM Return to the original directory
cd ..

echo.
echo === Build Complete ===
echo To run tests, copy the _sdrpp.pyd from build\python_swig_bindings\sdrpp\ 
echo to a directory in your Python path.
