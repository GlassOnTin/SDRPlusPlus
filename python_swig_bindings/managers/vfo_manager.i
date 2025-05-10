%module sdrpp_vfo_manager

%{
#include "../../core/src/signal_path/vfo_manager.h"
#include "../../core/src/dsp/stream.h"
%}

// Include standard library support
%include "std_string.i"
%include "std_map.i"

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
        SWIG_exception(SWIG_RuntimeError, "Unknown exception in VFO manager");
    }
    PyEval_RestoreThread(_save);
}

// Handle callback mechanisms with directors
%feature("director") VFOEventHandler;

// Define a Python-friendly callback handler for VFO events
%inline %{
class VFOEventHandler {
public:
    virtual ~VFOEventHandler() {}
    virtual void onVFOCreated(const std::string& name) {}
    virtual void onVFODeleted(const std::string& name) {}
    virtual void onSamplesReceived(void* complex_samples, int sample_count, void* ctx) {}
};

// Helper to connect Python callbacks to VFO events
void connectVFOCallbacks(VFOManager* mgr, const std::string& vfoName, VFOEventHandler* handler) {
    if (!mgr || !handler) return;
    
    // Save current PyThreadState
    PyGILState_STATE gstate;
    
    // Connect to VFO creation event
    mgr->onVFOCreated.connect([handler](std::string name) {
        // Acquire the GIL before calling into Python
        PyGILState_STATE gstate = PyGILState_Ensure();
        handler->onVFOCreated(name);
        // Release the GIL
        PyGILState_Release(gstate);
    });
    
    // Connect to VFO deletion event
    mgr->onVFODelete.connect([handler](std::string name) {
        // Acquire the GIL before calling into Python
        PyGILState_STATE gstate = PyGILState_Ensure();
        handler->onVFODeleted(name);
        // Release the GIL
        PyGILState_Release(gstate);
    });
    
    // Connect to data stream from VFO if it exists
    auto vfo = mgr->getVFO(vfoName);
    if (vfo) {
        vfo->output.bindHandler([handler](dsp::complex_t* data, int count, void* ctx) {
            // Acquire the GIL before calling into Python
            PyGILState_STATE gstate = PyGILState_Ensure();
            
            // Call the Python callback
            handler->onSamplesReceived(data, count, ctx);
            
            // Release the GIL
            PyGILState_Release(gstate);
        }, nullptr);
    }
}

// Helper to provide numpy-friendly sample handling
// In a real implementation, we would use numpy C API to convert directly
PyObject* getSamplesAsComplex(dsp::complex_t* samples, int count) {
    PyObject* result = PyList_New(count);
    if (!result) return nullptr;
    
    for (int i = 0; i < count; i++) {
        PyObject* complex_val = PyComplex_FromDoubles(samples[i].re, samples[i].im);
        if (!complex_val) {
            Py_DECREF(result);
            return nullptr;
        }
        PyList_SET_ITEM(result, i, complex_val);
    }
    
    return result;
}

// Helper class for working with VFOs
class VFOHelper {
public:
    VFOHelper(VFOManager* mgr) : vfoMgr(mgr) {}
    
    // Create a VFO with given parameters
    bool createVFO(const std::string& name, double frequency, double sampleRate, double bandwidth) {
        if (!vfoMgr) return false;
        
        try {
            vfoMgr->createVFO(name, frequency, sampleRate, bandwidth);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Delete a VFO by name
    bool deleteVFO(const std::string& name) {
        if (!vfoMgr) return false;
        
        try {
            vfoMgr->deleteVFO(name);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Set VFO frequency
    bool setVFOFrequency(const std::string& name, double frequency) {
        if (!vfoMgr) return false;
        
        try {
            vfoMgr->setVFOFrequency(name, frequency);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Get VFO frequency
    double getVFOFrequency(const std::string& name) {
        if (!vfoMgr) return 0.0;
        
        try {
            return vfoMgr->getVFOFrequency(name);
        } catch (...) {
            return 0.0;
        }
    }
    
    // Set VFO sample rate
    bool setVFOSampleRate(const std::string& name, double sampleRate) {
        if (!vfoMgr) return false;
        
        try {
            vfoMgr->setVFOSampleRate(name, sampleRate);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Get VFO sample rate
    double getVFOSampleRate(const std::string& name) {
        if (!vfoMgr) return 0.0;
        
        try {
            return vfoMgr->getVFOSampleRate(name);
        } catch (...) {
            return 0.0;
        }
    }
    
    // Set VFO bandwidth
    bool setVFOBandwidth(const std::string& name, double bandwidth) {
        if (!vfoMgr) return false;
        
        try {
            vfoMgr->setVFOBandwidth(name, bandwidth);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Get VFO bandwidth
    double getVFOBandwidth(const std::string& name) {
        if (!vfoMgr) return 0.0;
        
        try {
            return vfoMgr->getVFOBandwidth(name);
        } catch (...) {
            return 0.0;
        }
    }
    
private:
    VFOManager* vfoMgr;
};
%}

// Process the VFO manager header
%include "../../core/src/signal_path/vfo_manager.h"
