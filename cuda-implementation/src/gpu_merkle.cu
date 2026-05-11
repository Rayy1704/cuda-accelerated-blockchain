#include "gpu_merkle.h"
#include "cuda_error_check.h"
#include "gpu_sha256.h"
#include "hash.hpp"

__global__ 
void merkelKernel(unsigned char *header, int headerLen){
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    // each thread handles a consecutive pair of hashes
    if(i*2+1>=headerLen) return; // out of bounds
    //for hash indexing

    unsigned char* left = (unsigned char*) (header + (i * 2)*32);// left hash
    unsigned char* right = (unsigned char*) (header + (i * 2+1)*32); // right hash
    unsigned char * out = (unsigned char * )(header+i*32);// output slot (thread itself)
    //for calculating
    unsigned char combined_hashes[64];
    memcpy(combined_hashes, left, 32);
    memcpy(combined_hashes + 32, right, 32);

    //calling self created hashfunction to hash them together
    unsigned char hash_output[32]; // output of the hash function
    sha256_device(combined_hashes, 64, hash_output); // hash the combined hashes
    memcpy(out, hash_output, 32); // store resultant hash into thread id place
}

__global__ 
void merkleParentKernel(unsigned char *d_hashes, int initial_count) {
    if (threadIdx.x != 0 || blockIdx.x != 0) return;

    int count = initial_count;
    
    while (count > 1) {
        if (count % 2 != 0) { 
            memcpy(d_hashes + count * 32, d_hashes + (count - 1) * 32, 32);
            count++; 
        }
        
        int pairs = count / 2;
        int num_threads = 256; 
        int num_blocks = (pairs + num_threads - 1) / num_threads; 
        
        merkelKernel<<<num_blocks, num_threads>>>(d_hashes, count); 
        cudaDeviceSynchronize(); 
        
        count = count / 2; 
    }
}

std::string getMerkleRootGPU(std::vector<std::string>& merkle, char verbose) { 
    std::vector<std::string> hashes = merkle; 
    if(hashes.size() % 2 != 0){ 
        hashes.push_back(hashes.back()); 
    }
    
    int numHashes=hashes.size();
    unsigned char* h_hashes = new unsigned char [numHashes*32];
    for (int i = 0; i < numHashes; i++) {
        std::string hashed = sha256(hashes[i]);  // hash the raw data first
        for (int j = 0; j < 32; j++) {
            h_hashes[i * 32 + j] = (unsigned char)strtol(
                hashed.substr(j * 2, 2).c_str(), nullptr, 16
            );
        }
    }
    
    unsigned char *d_hashes;
    CUDA_CHECK_STR(cudaMalloc(&d_hashes, (numHashes + 1) * 32)); // allocate memory on the GPU
    CUDA_CHECK_STR(cudaMemcpy(d_hashes, h_hashes, numHashes * 32, cudaMemcpyHostToDevice)); 
    
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    
    merkleParentKernel<<<1, 1>>>(d_hashes, numHashes); 
    CUDA_CHECK_KERNEL_STR();
    CUDA_CHECK_STR(cudaDeviceSynchronize()); 

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms;
    cudaEventElapsedTime(&ms, start, stop);
    
    if(verbose == 'v'){
        printf("\nGPU Merkle tree calculation time: %.5f s\n", ms / 1000.0f);
    }

    unsigned char h_merkle_root[32];
    CUDA_CHECK_STR(cudaMemcpy(h_merkle_root, d_hashes, 32, cudaMemcpyDeviceToHost)); 

    char rootHex[65];
    for (int i = 0; i < 32; i++){
        sprintf(rootHex + i * 2, "%02x", h_merkle_root[i]); 
    }
    rootHex[64] = '\0'; 
    
    CUDA_CHECK_STR(cudaFree(d_hashes)); 
    delete[] h_hashes; 
    
    return std::string(rootHex); 
}