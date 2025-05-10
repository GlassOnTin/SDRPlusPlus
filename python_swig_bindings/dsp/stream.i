%module sdrpp_dsp_stream

// Define the DSP_STREAM_H macro to prevent inclusion of the real stream.h
#define DSP_STREAM_H

%{
// Use our mock headers and wrappers to completely bypass VOLK
#define DSP_STREAM_H
#include "../common/stream_wrapper.h"
%}

// Thread-safe exception handling
%exception {
    PyThreadState *_save = PyEval_SaveThread();
    try {
        $action
    } catch (const std::exception& e) {
        PyEval_RestoreThread(_save);
        SWIG_exception(SWIG_RuntimeError, e.what());
    } catch (...) {
        PyEval_RestoreThread(_save);
        SWIG_exception(SWIG_RuntimeError, "Unknown exception in DSP stream");
    }
    PyEval_RestoreThread(_save);
}

// Process our wrapper header instead of the direct dsp headers
%include "../common/stream_wrapper.h"

// Handle director callbacks
%feature("director") StreamCallback;

// Define Python-compatible sample processing
%inline %{
// Director class for Python callbacks
class StreamCallback {
public:
    virtual ~StreamCallback() {}
    virtual void onSamples(float* real_part, float* imag_part, int count) {}
};

// Wrapper to connect Python callbacks to streams
class PythonStreamHelper {
public:
    PythonStreamHelper() : streamWrapper(nullptr), callback(nullptr) {}
    ~PythonStreamHelper() {
        disconnect();
    }
    
    // Connect to a stream and set up a Python callback
    bool connect(dsp::stream<dsp::complex_t>* stream, StreamCallback* pythonCallback) {
        if (!stream || !pythonCallback) return false;
        
        // Store Python callback
        callback = pythonCallback;
        
        // Connect to stream using our wrapper
        streamWrapper.connect(stream);
        
        // Set C++ callback that will invoke Python
        return streamWrapper.setCallback([this](dsp::complex_t* samples, int count) {
            if (!callback) return;
            
            // Acquire GIL for Python operations
            PyGILState_STATE gstate = PyGILState_Ensure();
            
            // Allocate temporary arrays for real and imaginary parts
            float* real_part = new float[count];
            float* imag_part = new float[count];
            
            // Split complex samples into real and imaginary arrays
            for (int i = 0; i < count; i++) {
                real_part[i] = samples[i].re;
                imag_part[i] = samples[i].im;
            }
            
            // Call Python callback
            callback->onSamples(real_part, imag_part, count);
            
            // Clean up
            delete[] real_part;
            delete[] imag_part;
            
            // Release GIL
            PyGILState_Release(gstate);
        });
    }
    
    // Disconnect from stream
    void disconnect() {
        streamWrapper.disconnect();
        callback = nullptr;
    }
    
private:
    StreamWrapper streamWrapper;
    StreamCallback* callback;
};

// Helper to create a Python complex list from samples
PyObject* complexSamplesToList(const dsp::complex_t* samples, int count) {
    PyObject* list = PyList_New(count);
    if (!list) return nullptr;
    
    for (int i = 0; i < count; i++) {
        PyObject* complex_val = PyComplex_FromDoubles(samples[i].re, samples[i].im);
        if (!complex_val) {
            Py_DECREF(list);
            return nullptr;
        }
        PyList_SET_ITEM(list, i, complex_val);
    }
    
    return list;
}
%}

// Define complex type for Python
%inline %{
typedef struct {
    float re;
    float im;
} py_complex_t;
%}
