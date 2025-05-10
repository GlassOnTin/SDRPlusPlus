%module sdrpp_source_manager

%{
#include "../../core/src/signal_path/source.h"
%}

// Include standard library support
%include "std_string.i"
%include "std_vector.i"

// Handle callback mechanisms with directors
%feature("director") SourceEventHandler;

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
        SWIG_exception(SWIG_RuntimeError, "Unknown exception in SourceManager");
    }
    PyEval_RestoreThread(_save);
}

// Define a Python-friendly callback handler for source events
%inline %{
class SourceEventHandler {
public:
    virtual ~SourceEventHandler() {}
    virtual void onSourceRegistered(const std::string& name) {}
    virtual void onSourceUnregistered(const std::string& name) {}
    virtual void onRetune(double frequency) {}
};

// Helper to connect Python callbacks to C++ events
void connectSourceCallbacks(SourceManager* mgr, SourceEventHandler* handler) {
    if (!mgr || !handler) return;
    
    // Save current PyThreadState
    PyGILState_STATE gstate;
    
    mgr->onSourceRegistered.connect([handler](std::string name) {
        // Acquire the GIL before calling into Python
        gstate = PyGILState_Ensure();
        handler->onSourceRegistered(name);
        // Release the GIL
        PyGILState_Release(gstate);
    });
    
    mgr->onSourceUnregister.connect([handler](std::string name) {
        // Acquire the GIL before calling into Python
        gstate = PyGILState_Ensure();
        handler->onSourceUnregistered(name);
        // Release the GIL
        PyGILState_Release(gstate);
    });
    
    mgr->onRetune.connect([handler](double freq) {
        // Acquire the GIL before calling into Python
        gstate = PyGILState_Ensure();
        handler->onRetune(freq);
        // Release the GIL
        PyGILState_Release(gstate);
    });
}

// Helper class for SDRPlay-specific operations
class SDRPlayHelper {
public:
    SDRPlayHelper(SourceManager* mgr) : sourceMgr(mgr) {}
    
    // Check if SDRPlay source is available
    bool isSDRPlayAvailable() {
        if (!sourceMgr) return false;
        
        std::vector<std::string> sources = sourceMgr->getSourceNames();
        for (const auto& source : sources) {
            if (source == "sdrplay") return true;
        }
        return false;
    }
    
    // Configure SDRPlay with common parameters
    bool configureSDRPlay(double freqMHz, double sampleRateHz, double gainReduction) {
        if (!isSDRPlayAvailable() || !sourceMgr) return false;
        
        try {
            sourceMgr->selectSource("sdrplay");
            sourceMgr->tune(freqMHz * 1e6);
            
            // Note: Setting sample rate and gain would require
            // access to the SDRPlay source module-specific parameters
            // This is a placeholder for that functionality
            
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Start the SDRPlay device
    bool startSDRPlay() {
        if (!sourceMgr) return false;
        try {
            sourceMgr->start();
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Stop the SDRPlay device
    bool stopSDRPlay() {
        if (!sourceMgr) return false;
        try {
            sourceMgr->stop();
            return true;
        } catch (...) {
            return false;
        }
    }
    
private:
    SourceManager* sourceMgr;
};
%}

// Process the source manager header
%include "../../core/src/signal_path/source.h"
