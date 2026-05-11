#include "gpu_verification.h"

#include <cuda_runtime.h>
#include <cstdio>
#include <cstring>
#include <memory>
#include <string>
#include <vector>
#include "gpu_sha256.h"
#include "gpu_merkle.h"
#include "cuda_error_check.h"

__device__ void bytesToHex(unsigned char* bytes, char* hex) {
    const char* table = "0123456789abcdef";
    for (int i = 0; i < 32; i++) {
        hex[i*2]     = table[(bytes[i] >> 4) & 0xF];
        hex[i*2 + 1] = table[bytes[i]        & 0xF];
    }
    hex[64] = '\0';
}

__device__ bool stringsEqual(const char* a, const char* b) {
    for (int i = 0; i < 64; i++) {
        if (a[i] != b[i]) return false;
    }
    return true;
}
void copyString(char* destination, const std::string& source) {
    std::memset(destination, 0, 65);
    std::strncpy(destination, source.c_str(), 64);
    destination[64] = '\0';
}
__global__ void verifyChainKernel(const VerificationRecord* records, int size, int* result) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= size - 1 || atomicAdd(result, 0) == 0) { //experiemtn with atomic add
        return;
    }

    const VerificationRecord& previous = records[idx];
    const VerificationRecord& current = records[idx + 1];
    unsigned char hashBytes[32];
    sha256_device(
        (const unsigned char*)current.header,
        current.headerLen,
        hashBytes
    );
    char computedHex[65];
    bytesToHex(hashBytes, computedHex);

    bool valid = (current.index == previous.index + 1) &&stringsEqual(current.previousHash, previous.hash) &&stringsEqual(current.hash, computedHex);

    if (!valid) {
        printf("[GPU] Block %d failed validation\n", current.index);
        atomicExch(result, 0);
    }
}

bool runVerifyKernel(VerificationRecord* h_blockChain, int size) {
    if (size < 2) {
        return true;
    }


    VerificationRecord* d_blockChain = nullptr;
    CUDA_CHECK_BOOL(cudaMalloc(&d_blockChain, size * sizeof(VerificationRecord)));

    int* d_result = nullptr;
    int h_result = 1;
    CUDA_CHECK_BOOL(cudaMalloc(&d_result, sizeof(int)));

    CUDA_CHECK_BOOL(cudaMemcpy(d_blockChain, h_blockChain, size * sizeof(VerificationRecord), cudaMemcpyHostToDevice));

    CUDA_CHECK_BOOL(cudaMemcpy(d_result, &h_result, sizeof(int), cudaMemcpyHostToDevice));

    const int threadsPerBlock = 256;
    const int blocks = static_cast<int>((size + threadsPerBlock - 1) / threadsPerBlock);
    dim3 grid(blocks);
    dim3 block(threadsPerBlock);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    verifyChainKernel<<<grid, block>>>(d_blockChain, size, d_result);

    CUDA_CHECK_KERNEL_BOOL();

    CUDA_CHECK_BOOL(cudaDeviceSynchronize());

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);
    printf("GPU verification time: %.5f s\n", ms / 1000.0f);

    CUDA_CHECK_BOOL(cudaMemcpy(&h_result, d_result, sizeof(int), cudaMemcpyDeviceToHost));
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_blockChain);
    cudaFree(d_result);
    return h_result != 0;
}
