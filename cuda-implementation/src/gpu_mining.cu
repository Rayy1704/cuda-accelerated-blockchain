#include "gpu_mining.h"
#include <cuda_runtime.h>
#include <stdio.h>
#include <string>
#include <stdint.h>
#include <utility> 
#include "cuda_error_check.h"
#include "gpu_sha256.h"
#include "hash.hpp"



__device__ bool hasLeadingZeros(unsigned char* hash) {
    int fullBytes = 3; //for first 6 characters
    for (int i = 0; i < fullBytes; i++) {
        if (hash[i] != 0x00) return false;
    }
    return true;
}
__global__ __launch_bounds__(256)
void mineKernel(const unsigned char* header,int headerLen,unsigned int batchStart,unsigned int* resultNonce,int* found){
    if (__builtin_expect(*found, 0)) return; // already found hash, skip work
    unsigned int og_nonce = batchStart + blockIdx.x * blockDim.x + threadIdx.x; // calculate nonce
    unsigned char input[256]; // buffer for header + nonce and padding
    memcpy(input, header, headerLen); // copy header into buffer]
    int totalLen;
    unsigned int nonce= og_nonce;
    unsigned int n = nonce;
    int nonceLen = 0;
    if (og_nonce == 0) {
        input[headerLen] = '0';
         totalLen= headerLen + 1;
    } else {
        while(n!=0){
            n=n/10;
            nonceLen++;
        }
        int digit;
        for(int i = nonceLen-1; i >= 0; i--) {
            digit= nonce % 10;
            nonce = nonce / 10;
            input[headerLen + i] = digit + '0'; // append nonce string to buffer after header   
        }
        totalLen = headerLen + nonceLen;
    }
    
    

    unsigned char hash[32]; // buffer to hold hash

    sha256_device(input, totalLen, hash);// computer hash using self defined function sha256_hash()
     
          // check if hash is valid 
     if (hasLeadingZeros(hash)) {
        if (atomicCAS(found, 0, 1) == 0) {
            *resultNonce = og_nonce;
        }
    }
} 
// wrapper function to launch kernel (same format as defined by tko22 in simple blockchain)
std::pair <std::string,std::string> findHashGPU(char * header){
    int headerLen= strlen(header);
    unsigned char *d_header; // creating device pointers for global memory in device
    unsigned int *d_resultNonce;
    int *d_found;
    
    // Allocate device memory with error checking
    CUDA_CHECK(cudaMalloc(&d_header, headerLen+1)); // +1 for null terminator
    CUDA_CHECK(cudaMalloc(&d_resultNonce, sizeof(unsigned int)));
    CUDA_CHECK(cudaMalloc(&d_found, sizeof(int)));
    
    // Copy header to device with error checking
    CUDA_CHECK(cudaMemcpy(d_header, header, headerLen, cudaMemcpyHostToDevice));
    
    // Initialize device memory with error checking
    CUDA_CHECK(cudaMemset(d_resultNonce, 0, sizeof(unsigned int)));
    CUDA_CHECK(cudaMemset(d_found, 0, sizeof(int)));

    const int threadsPerBlock = 256;
    const int blocks = 8192; 
    unsigned int batchStart=0;
    int h_found=0;
    dim3 grid(blocks);
    dim3 block(threadsPerBlock);
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    while(!h_found){
            mineKernel<<<grid, block>>>(d_header, headerLen, batchStart, d_resultNonce, d_found);
        
        // Check for kernel launch errors
        CUDA_CHECK_KERNEL();
        
        // Synchronize device and check for errors
        CUDA_CHECK(cudaDeviceSynchronize());
        
        // Copy result back to host with error checking
        CUDA_CHECK(cudaMemcpy(&h_found, d_found, sizeof(int), cudaMemcpyDeviceToHost));
        batchStart += blocks * threadsPerBlock;
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms;
    cudaEventElapsedTime(&ms, start, stop);
    printf("GPU mining time: %.2f s\n", ms / 1000.0f);
    //get winning nonce back to host
    unsigned int h_nonce;
    CUDA_CHECK(cudaMemcpy(&h_nonce, d_resultNonce, sizeof(unsigned int), cudaMemcpyDeviceToHost));
    
    //get the hash using cpu funciton to avoid overhead
    std::string finalInputStr = std::string(header) + std::to_string(h_nonce);
    std::string safeHash = sha256(finalInputStr);  
    std::string safeNonce = std::to_string(h_nonce);
    // Free device memory with error checking
    CUDA_CHECK(cudaFree(d_header));
    CUDA_CHECK(cudaFree(d_resultNonce));
    CUDA_CHECK(cudaFree(d_found));
    
    return std::make_pair(safeHash, safeNonce);
}


  