#ifndef CUDA_ERROR_CHECK_H
#define CUDA_ERROR_CHECK_H

#include <stdio.h>
#include <utility>
#include <cuda_runtime.h>

// CUDA_CHECK for functions returning std::pair<std::string, std::string>
#define CUDA_CHECK(call) \
    { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return std::make_pair("", ""); \
        } \
    }

#define CUDA_CHECK_KERNEL() \
    { \
        cudaError_t err = cudaGetLastError(); \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Kernel Launch Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return std::make_pair("", ""); \
        } \
    }

// CUDA_CHECK_STR for functions returning std::string
#define CUDA_CHECK_STR(call) \
    { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return ""; \
        } \
    }

#define CUDA_CHECK_KERNEL_STR() \
    { \
        cudaError_t err = cudaGetLastError(); \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Kernel Launch Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return ""; \
        } \
    }

// CUDA_CHECK_BOOL for functions returning bool
#define CUDA_CHECK_BOOL(call) \
    { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return false; \
        } \
    }

#define CUDA_CHECK_KERNEL_BOOL() \
    { \
        cudaError_t err = cudaGetLastError(); \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA Kernel Launch Error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            return false; \
        } \
    }

#endif // CUDA_ERROR_CHECK_H
