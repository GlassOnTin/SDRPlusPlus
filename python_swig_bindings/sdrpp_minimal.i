%module sdrpp

// Define that we're building with SWIG to enable conditional compilation
#define SWIG_BUILDING

%{
// Include our JSON helper
#include "common/json_helper.h"

// Include only the essential SDR++ headers we need
#include "../core/src/config.h"
#include "../core/src/signal_path/source.h"
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

// Template instantiations for containers used in SDR++
%template(StringVector) std::vector<std::string>;

// Include our JSON typemap and helper
%include "common/json_typemap.i"
%include "common/json_helper.h"

// Create simplified SourceManager wrapper for SDRPlay testing
%rename(SourceManager) SimplifiedSourceManager;

%inline %{
// Simplified source manager wrapper
class SimplifiedSourceManager {
private:
    SourceManager* mgr;

public:
    SimplifiedSourceManager() {
        mgr = new SourceManager();
    }
    
    ~SimplifiedSourceManager() {
        delete mgr;
    }
    
    // Get available source names
    std::vector<std::string> getSourceNames() {
        return mgr->getSourceNames();
    }
    
    // Check if SDRPlay is available
    bool isSDRPlayAvailable() {
        std::vector<std::string> sources = mgr->getSourceNames();
        for (const auto& source : sources) {
            if (source == "sdrplay") return true;
        }
        return false;
    }
    
    // Select a source by name
    bool selectSource(const std::string& name) {
        try {
            mgr->selectSource(name);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Tune to a specific frequency
    bool tune(double frequency) {
        try {
            mgr->tune(frequency);
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Start the selected source
    bool start() {
        try {
            mgr->start();
            return true;
        } catch (...) {
            return false;
        }
    }
    
    // Stop the selected source
    bool stop() {
        try {
            mgr->stop();
            return true;
        } catch (...) {
            return false;
        }
    }
};

// Simplified config manager wrapper
class SimplifiedConfigManager {
private:
    ConfigManager* mgr;

public:
    SimplifiedConfigManager() {
        mgr = new ConfigManager();
    }
    
    ~SimplifiedConfigManager() {
        delete mgr;
    }
    
    void setPath(const std::string& path) {
        mgr->setPath(path);
    }
    
    void loadFromString(const std::string& jsonStr) {
        try {
            // Validate JSON first
            if (!JsonHelper::isValidJson(jsonStr)) {
                throw std::runtime_error("Invalid JSON string provided");
            }
            
#ifndef SWIG
            // Only in C++ code, not in SWIG parsing
            nlohmann::json defaultConfig = JsonHelper::parseJson(jsonStr);
            mgr->load(defaultConfig);
#endif
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to load config: ") + e.what());
        }
    }
    
    std::string saveToString() {
        try {
#ifndef SWIG
            // Only in C++ code, not in SWIG parsing
            mgr->acquire();
            std::string jsonStr = JsonHelper::stringifyJson(mgr->conf);
            mgr->release(false);
            return jsonStr;
#else
            // Dummy implementation for SWIG parsing
            return "{}";
#endif
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to save config: ") + e.what());
        }
    }
    
    void enableAutoSave() {
        mgr->enableAutoSave();
    }
    
    void disableAutoSave() {
        mgr->disableAutoSave();
    }
    
    void save() {
        mgr->save();
    }
};

// Utility functions to provide version info
const char* getSdrppVersion() {
    return "SDR++ Python Bindings 1.0.0 Minimal";
}

%}
