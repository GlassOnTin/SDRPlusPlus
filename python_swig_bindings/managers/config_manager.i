%module sdrpp_config_manager

%{
// Include the necessary headers
#include "../../core/src/config.h"
#include "../common/json_helper.h"
%}

// Include standard library support
%include "std_string.i"

// Handle exceptions for thread safety
%exception {
    try {
        $action
    } catch (const std::exception& e) {
        SWIG_exception(SWIG_RuntimeError, e.what());
    } catch (...) {
        SWIG_exception(SWIG_RuntimeError, "Unknown exception in ConfigManager");
    }
}

// Include our JSON helper
%include "../common/json_helper.h"

// Create a simplified ConfigManager wrapper that doesn't expose json directly
%rename(ConfigManager) SimplifiedConfigManager;

%inline %{
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
            // Use our helper to parse JSON
            nlohmann::json defaultConfig = JsonHelper::parseJson(jsonStr);
            mgr->load(defaultConfig);
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to load config: ") + e.what());
        }
    }
    
    std::string saveToString() {
        try {
            mgr->acquire();
            // Use our helper to stringify JSON
            std::string jsonStr = JsonHelper::stringifyJson(mgr->conf);
            mgr->release(false);
            return jsonStr;
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
%}

// Don't process the original ConfigManager header to avoid json dependency
