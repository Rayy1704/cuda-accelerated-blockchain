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

