// Type mappings for nlohmann::json in SWIG
%{
#include "../../core/src/json.hpp"
%}

// Don't wrap the actual nlohmann::json class, but instead convert to/from Python dict
%typemap(in) const nlohmann::json& {
    PyObject* json_module = PyImport_ImportModule("json");
    if (!json_module) {
        SWIG_exception(SWIG_RuntimeError, "Failed to import json module");
        SWIG_fail;
    }
    
    PyObject* json_dumps = PyObject_GetAttrString(json_module, "dumps");
    Py_DECREF(json_module);
    
    if (!json_dumps || !PyCallable_Check(json_dumps)) {
        Py_XDECREF(json_dumps);
        SWIG_exception(SWIG_RuntimeError, "Failed to get json.dumps function");
        SWIG_fail;
    }
    
    // Convert Python object to JSON string
    PyObject* str_args = PyTuple_Pack(1, $input);
    PyObject* json_str = PyObject_CallObject(json_dumps, str_args);
    Py_DECREF(str_args);
    Py_DECREF(json_dumps);
    
    if (!json_str) {
        SWIG_exception(SWIG_RuntimeError, "Failed to convert Python object to JSON string");
        SWIG_fail;
    }
    
    // Convert PyObject string to C++ string
    char* buffer;
    Py_ssize_t length;
    PyBytes_AsStringAndSize(PyUnicode_AsEncodedString(json_str, "utf-8", "strict"), &buffer, &length);
    std::string json_cpp_str(buffer, length);
    Py_DECREF(json_str);
    
    // Static variable to hold the temporary json object
    static nlohmann::json temp_json;
    try {
        temp_json = nlohmann::json::parse(json_cpp_str);
        $1 = &temp_json;
    } catch (std::exception& e) {
        SWIG_exception(SWIG_RuntimeError, (std::string("Error parsing JSON: ") + e.what()).c_str());
        SWIG_fail;
    }
}

%typemap(out) nlohmann::json {
    // Convert JSON object to string
    std::string json_str;
    try {
        json_str = $1.dump();
    } catch (std::exception& e) {
        SWIG_exception(SWIG_RuntimeError, (std::string("Error converting JSON to string: ") + e.what()).c_str());
        SWIG_fail;
    }
    
    // Use Python's json module to parse the string into a Python dict
    PyObject* json_module = PyImport_ImportModule("json");
    if (!json_module) {
        SWIG_exception(SWIG_RuntimeError, "Failed to import json module");
        SWIG_fail;
    }
    
    PyObject* json_loads = PyObject_GetAttrString(json_module, "loads");
    Py_DECREF(json_module);
    
    if (!json_loads || !PyCallable_Check(json_loads)) {
        Py_XDECREF(json_loads);
        SWIG_exception(SWIG_RuntimeError, "Failed to get json.loads function");
        SWIG_fail;
    }
    
    // Convert JSON string to Python object
    PyObject* pystr = PyUnicode_FromString(json_str.c_str());
    PyObject* args = PyTuple_Pack(1, pystr);
    $result = PyObject_CallObject(json_loads, args);
    
    Py_DECREF(pystr);
    Py_DECREF(args);
    Py_DECREF(json_loads);
    
    if (!$result) {
        SWIG_exception(SWIG_RuntimeError, "Failed to convert JSON string to Python object");
        SWIG_fail;
    }
}

// Also handle the case where we return json by value
%typemap(out) const nlohmann::json = nlohmann::json;
