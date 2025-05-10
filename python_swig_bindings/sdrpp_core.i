%module sdrpp

// Define that we're building with SWIG to enable conditional compilation
#define SWIG_BUILDING
// Bypass stream.h to avoid VOLK dependency
#define DSP_STREAM_H

%{
// Include our VOLK mock for SWIG processing
#include "common/volk_mock.h"

// Now include the actual SDR++ headers
#include "../core/src/config.h"
#include "../core/src/module.h"
#include "../core/src/signal_path/source.h"
#include "../core/src/signal_path/sink.h"
#include "../core/src/signal_path/vfo_manager.h"
#include "../core/src/dsp/types.h"
#include "common/stream_wrapper.h"
%}

// Begin section for proper Python initialization
%begin %{
#define PY_SSIZE_T_CLEAN
#include <Python.h>
%}

// Handle exceptions and GIL management
%include "exception.i"
%exception {
    PyThreadState *_save = PyEval_SaveThread();
    try {
        $action
    } catch (const std::exception& e) {
        PyEval_RestoreThread(_save);
        SWIG_exception(SWIG_RuntimeError, e.what());
    } catch (...) {
        PyEval_RestoreThread(_save);
        SWIG_exception(SWIG_RuntimeError, "Unknown exception");
    }
    PyEval_RestoreThread(_save);
}

// Include standard library support
%include "std_string.i"
%include "std_vector.i"
%include "std_map.i"

// Template instantiations for containers used in SDR++
%template(StringVector) std::vector<std::string>;

// Include our component modules
%include "managers/config_manager.i"
%include "managers/source_manager.i"
%include "managers/vfo_manager.i"
%include "dsp/stream.i"

// Handle dsp::complex_t type for Python compatibility
%inline %{
// Basic SDR++ version information
const char* getSdrppVersion() {
    return "SDR++ Python Bindings 1.0.0";
}

// Convert dsp::complex_t to Python complex
PyObject* complex_to_python(dsp::complex_t& cpx) {
    return PyComplex_FromDoubles(cpx.re, cpx.im);
}

// Convert Python complex to dsp::complex_t
dsp::complex_t python_to_complex(PyObject* obj) {
    dsp::complex_t result;
    if (PyComplex_Check(obj)) {
        result.re = PyComplex_RealAsDouble(obj);
        result.im = PyComplex_ImagAsDouble(obj);
    } else if (PyFloat_Check(obj)) {
        result.re = PyFloat_AsDouble(obj);
        result.im = 0.0f;
    } else if (PyLong_Check(obj)) {
        result.re = (float)PyLong_AsLong(obj);
        result.im = 0.0f;
    }
    return result;
}

// Version info and utility functions

%}

// Include core type definitions
%include "../core/src/dsp/types.h"

// Include core module components 
%include "../core/src/config.h"
%include "../core/src/module.h"
%include "../core/src/signal_path/source.h"
%include "../core/src/signal_path/sink.h"
%include "../core/src/signal_path/vfo_manager.h"
