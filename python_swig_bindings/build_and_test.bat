@echo off
REM Build and Test script for SDR++ Python SWIG bindings
REM This script builds the SWIG bindings and runs the tests with the SDRPlay device

echo === Building SDR++ Python SWIG Bindings ===

REM Create build directory if it doesn't exist
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake .. ^
    -DOPT_BUILD_SDRPLAY_SOURCE=ON ^
    -DOPT_BUILD_PYTHON_BINDINGS=ON

REM Build the project
echo Building SDR++...
cmake --build . --config Release

REM Copy test files to the build directory
echo.
echo === Copying Test Files ===
if not exist python_swig_bindings\tests mkdir python_swig_bindings\tests
xcopy /Y ..\tests\*.py python_swig_bindings\tests\

REM Run basic tests
echo.
echo === Running Basic SDRPlay Tests ===
cd python_swig_bindings\tests
python test_sdrplay_basic.py

REM Return to the original directory
cd ..\..\..

echo.
echo === Build and Test Complete ===
