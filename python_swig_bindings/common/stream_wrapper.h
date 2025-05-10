#pragma once

// Forward declarations and wrapper for SDR++ stream functionality
// Avoids direct inclusion of VOLK-dependent headers during SWIG processing

// Completely bypass real stream.h since it has VOLK dependency
#define DSP_STREAM_H

#include <functional>
#include <string>
#include <stdexcept>
#include <cstring>

// Define the complex type first so we can use it
namespace dsp {
    struct complex_t {
        float re;
        float im;
    };

    // Forward declare the stream class that will be used by our wrappers
    template <typename T>
    class stream {
    public:
        // Define just enough of the stream class API for our wrappers to compile
        typedef std::function<void(T*, int, void*)> handler_t;
        void bindHandler(handler_t handler, void* ctx) {}
        void unbindHandler() {}
    };
}

// Wrapper for stream functionality that avoids VOLK dependency in SWIG
class StreamWrapper {
public:
    // Constructor that takes an existing stream
    StreamWrapper(dsp::stream<dsp::complex_t>* existingStream = nullptr) 
        : stream(existingStream), handler(nullptr), handlerCtx(nullptr), connected(false) {}
    
    // Destructor - automatically disconnects
    ~StreamWrapper() {
        disconnect();
    }
    
    // Connect to an existing stream
    bool connect(dsp::stream<dsp::complex_t>* existingStream) {
        if (!existingStream) return false;
        
        disconnect(); // First disconnect if already connected
        stream = existingStream;
        return true;
    }
    
    // Disconnect from current stream
    void disconnect() {
        if (stream && connected) {
            stream->unbindHandler();
            connected = false;
        }
        handler = nullptr;
        handlerCtx = nullptr;
    }
    
    // Setup a simple callback for receiving samples
    typedef std::function<void(dsp::complex_t*, int)> SampleCallback;
    
    bool setCallback(SampleCallback callback) {
        if (!stream) return false;
        
        // Store the callback
        handler = [](dsp::complex_t* data, int count, void* ctx) {
            StreamWrapper* wrapper = static_cast<StreamWrapper*>(ctx);
            if (wrapper && wrapper->userCallback) {
                wrapper->userCallback(data, count);
            }
        };
        
        // Bind the handler to the stream
        stream->bindHandler(handler, this);
        connected = true;
        userCallback = callback;
        
        return true;
    }
    
    // Get the underlying stream (for C++ code)
    dsp::stream<dsp::complex_t>* getStream() const {
        return stream;
    }
    
private:
    dsp::stream<dsp::complex_t>* stream;
    std::function<void(dsp::complex_t*, int, void*)> handler;
    void* handlerCtx;
    SampleCallback userCallback;
    bool connected;
};

// Helper function to create a Python-friendly representation of complex samples
inline void complexToFloatArrays(const dsp::complex_t* samples, int count, 
                                float* real_out, float* imag_out) {
    for (int i = 0; i < count; i++) {
        real_out[i] = samples[i].re;
        imag_out[i] = samples[i].im;
    }
}
