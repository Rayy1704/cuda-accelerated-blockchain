    #include "gpu_mining.h"
    #include <cuda_runtime.h>
    #include <stdio.h>
    #include <string>
    #include <stdint.h>
    #include <utility> 
    #include "cuda_error_check.h"
    #include "gpu_sha256.h"
    #include "hash.hpp"
    #include <atomic>
    #include <thread>
    #include <chrono>

    __constant__ unsigned char d_header[256];

    __device__ bool hasLeadingZeros(unsigned char* hash) {
        int fullBytes = 4; //for first 6 characters
        for (int i = 0; i < fullBytes; i++) {
            if (hash[i] != 0x00) return false;
        }
        return true;
    }
    __global__ __launch_bounds__(256)
    void mineKernel(int headerLen,unsigned int* resultNonce,volatile int* found,volatile int * abortFlag) {
        if (__builtin_expect(*found, 0)) return; // already found hash, skip work
        unsigned int og_nonce = blockIdx.x * blockDim.x + threadIdx.x; // calculate nonce
        const unsigned int stride = gridDim.x * blockDim.x;
        unsigned char input[256]; // buffer for header + nonce and padding
        for (int i = 0; i < headerLen; i++) {
            input[i] = d_header[i];
        }
        int totalLen;
        int iter = 0;
        while( true) {
            if (iter % 64 == 0) {
                if (*found == 1 || *abortFlag == 1) break;
            }
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
                if (atomicCAS((int *)found, 0, 1) == 0) {
                    *resultNonce = og_nonce;
                }
                break; // exit loop if found
            }    
        og_nonce += stride; // move to next nonce for this thread
        if (og_nonce > UINT32_MAX - stride) break; // would overflow, exit
        iter++;
        }
    }
    
    // wrapper function to launch kernel (same format as defined by tko22 in simple blockchain)
    std::pair <std::string,std::string> findHashGPU(char * header, std::atomic<bool>* cancelFlag){
        cudaStream_t stream; 
        cudaStreamCreate(&stream);
        int headerLen= strlen(header);
    // creating device pointers for global memory in device
        unsigned int *d_resultNonce;
        // create a shared array (Index 0 = found, Index 1 = abort)
        volatile int *h_flags_mapped; 
        int *d_flags_mapped;          
        
    
        cudaHostAlloc((void**)&h_flags_mapped, 2 * sizeof(int), cudaHostAllocMapped);
        h_flags_mapped[0] = 0; 
        h_flags_mapped[1] = 0; 
        
        // Ask CUDA for the GPU's memory address that points to this same host RAM
        cudaHostGetDevicePointer((void**)&d_flags_mapped, (void*)h_flags_mapped, 0);

        CUDA_CHECK(cudaMalloc(&d_resultNonce, sizeof(unsigned int)));
            
        // Initialize device memory with error checking
        CUDA_CHECK(cudaMemsetAsync(d_resultNonce, 0, sizeof(unsigned int), stream));
            // Copy header to constant memory with error checking
        CUDA_CHECK(cudaMemcpyToSymbolAsync(d_header, header, headerLen, 0, cudaMemcpyHostToDevice, stream));
        const int threadsPerBlock = 256;
        const int blocks = 8192; 
        dim3 grid(blocks);
        dim3 block(threadsPerBlock);
        cudaEvent_t start, stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start,stream);
        mineKernel<<<grid, block,0,stream>>>(headerLen, d_resultNonce, &d_flags_mapped[0],&d_flags_mapped[1]);
            
        // Check for kernel launch errors
        CUDA_CHECK_KERNEL();
            
        while(cudaStreamQuery(stream) == cudaErrorNotReady) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            if (cancelFlag != nullptr && cancelFlag->load()) {
                printf("\n[!] GPU Mining aborted: Network provided a newer chain.\n");
                h_flags_mapped[1] = 1;
                break;
            }
        }
        cudaStreamSynchronize(stream);
        // Copy result back to host with error checking
        cudaEventRecord(stop,stream);
        cudaEventSynchronize(stop);
        float ms;
        cudaEventElapsedTime(&ms, start, stop);
        std::string safeHash = "fail";
        std::string safeNonce = "fail";
        if (h_flags_mapped[0]) {
            printf("GPU mining time: %.2f s\n", ms / 1000.0f);
            unsigned int h_nonce;
            CUDA_CHECK(cudaMemcpy(&h_nonce, d_resultNonce, sizeof(unsigned int), cudaMemcpyDeviceToHost));
            
            std::string finalInputStr = std::string(header) + std::to_string(h_nonce);
            safeHash = sha256(finalInputStr);  
            safeNonce = std::to_string(h_nonce);
        }
        // Free device memory with error checking
        CUDA_CHECK(cudaStreamDestroy(stream));
        CUDA_CHECK(cudaEventDestroy(start));
        CUDA_CHECK(cudaEventDestroy(stop));
        CUDA_CHECK(cudaFreeHost((void*)h_flags_mapped));
        CUDA_CHECK(cudaFree(d_resultNonce));            
        return std::make_pair(safeHash, safeNonce);
    }


    