#pragma once

// Mock implementation of VOLK for SWIG processing
// This allows the SWIG interface to be built without VOLK dependency
// Real VOLK functionality will be provided at runtime through SDR++ libraries

#ifndef VOLK_H
#define VOLK_H

#ifdef __cplusplus
extern "C" {
#endif

// Mock VOLK API functions that SDR++ relies on
typedef struct volk_func_desc {
    const char* name;
    const char* impl_names;
    const char* docs;
    int impl_count;
    size_t (*func)(void);
} volk_func_desc_t;

#define VOLK_ATTR_ALIGNED(x)
#define SWIG_BUILDING_PYTHON

// Basic VOLK type definitions
typedef float lv_32fc_t[2];

// Mock implementations of commonly used VOLK functions
static inline void volk_32fc_s32fc_multiply_32fc(float* cVector, const float* aVector, const float* bVector, unsigned int num_points) {
    // Mock implementation - no operation
}

static inline void volk_32fc_32f_multiply_32fc(float* cVector, const float* aVector, const float* bVector, unsigned int num_points) {
    // Mock implementation - no operation
}

static inline void volk_32fc_deinterleave_real_32f(float* iBuffer, const float* complexVector, unsigned int num_points) {
    // Mock implementation - no operation
}

static inline void volk_32fc_deinterleave_imag_32f(float* qBuffer, const float* complexVector, unsigned int num_points) {
    // Mock implementation - no operation
}

#ifdef __cplusplus
}
#endif

#endif /* VOLK_H */
