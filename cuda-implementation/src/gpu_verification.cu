#include "gpu_verification.h"

#include <cuda_runtime.h>
#include <cstdio>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gpu_sha256.h"
#include "gpu_merkle.h"
#include "Block.hpp"
#include "hash.hpp"

struct VerificationRecord {
    int index;
    char previousHash[65];
    char hash[65];
    char nonce[65];
    char expectedHash[65];
};

__device__ bool stringsEqual(const char* lhs, const char* rhs) {
    for (int i = 0; i < 65; ++i) {
        if (lhs[i] != rhs[i]) {
            return false;
        }
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
    if (idx >= size - 1 || *result == 0) {
        return;
    }

    const VerificationRecord& previous = records[idx];
    const VerificationRecord& current = records[idx + 1];

    bool valid = (current.index == previous.index + 1) &&stringsEqual(current.previousHash, previous.hash) &&stringsEqual(current.hash, current.expectedHash);

    if (!valid) {
        atomicExch(result, 0);
    }
}






// __global__ void verifyChain(Block** d_blockchain, int size, bool* d_result) {
//     int idx = blockIdx.x * blockDim.x + threadIdx.x;
//     if (idx < size - 1) {
//         Block* b = d_blockchain[idx + 1];
//         vector<string> data = b->getData();
//         string header = to_string(b->getIndex()) + b->getPreviousHash() + getMerkleRootGPU(data) + b->getNonce();
//         if (sha256(header) != b->getHash() || b->getHash().substr(0,6) != "000000" || b->getPreviousHash() != d_blockchain[idx]->getHash()) {
//             *d_result = false;
//         }else {
//             *d_result = true;
//         }
//     }
// }

