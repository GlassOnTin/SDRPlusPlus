#pragma once

// This header provides simplified wrappers for JSON functionality
// for use with SWIG Python bindings

#include <string>
#include <stdexcept>

// Forward declare the nlohmann::json class for C++ code
namespace nlohmann {
    class json;
}

// Include the actual JSON header in C++ code only, not in SWIG parsing
#ifndef SWIG
#include "../../core/src/json.hpp"
#endif

// Helper class to convert between JSON and string representations
// Avoids directly exposing nlohmann::json to SWIG
class JsonHelper {
private:
#ifndef SWIG
    // Internal methods that use nlohmann::json - not exposed to SWIG
    static nlohmann::json _parseJsonInternal(const std::string& jsonStr) {
        try {
            return nlohmann::json::parse(jsonStr);
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to parse JSON: ") + e.what());
        }
    }
    
    static std::string _stringifyJsonInternal(const nlohmann::json& jsonObj, bool pretty) {
        try {
            if (pretty) {
                return jsonObj.dump(4); // Pretty print with indent of 4
            }
            return jsonObj.dump();
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to stringify JSON: ") + e.what());
        }
    }
#endif

public:
    // String-only methods for SWIG
    // Validate JSON string
    static bool isValidJson(const std::string& jsonStr) {
#ifndef SWIG
        try {
            nlohmann::json::parse(jsonStr);
            return true;
        } catch (...) {
            return false;
        }
#else
        return false; // Placeholder for SWIG parsing
#endif
    }
    
    // Pretty print JSON string
    static std::string prettyPrint(const std::string& jsonStr) {
#ifndef SWIG
        try {
            auto parsed = nlohmann::json::parse(jsonStr);
            return parsed.dump(4);
        } catch (const std::exception& e) {
            throw std::runtime_error(std::string("Failed to pretty print JSON: ") + e.what());
        }
#else
        return jsonStr; // Placeholder for SWIG parsing
#endif
    }
    
#ifndef SWIG
    // These methods are only available in C++ code, not in SWIG/Python
    // Parse JSON string to nlohmann::json
    static nlohmann::json parseJson(const std::string& jsonStr) {
        return _parseJsonInternal(jsonStr);
    }
    
    // Convert nlohmann::json to string
    static std::string stringifyJson(const nlohmann::json& jsonObj, bool pretty = true) {
        return _stringifyJsonInternal(jsonObj, pretty);
    }
#endif
};
