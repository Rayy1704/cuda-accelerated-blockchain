#include "gpu_parallel_verification.h"
#include "sha256_gpu.h"
#include "gpu_merkle.h"
#include "BlockChain.hpp"
#include "Block.hpp"
bool BlockChain::isChainValid() {
    for (int i = 1; i < blockchain.size(); i++) {
        Block* b = blockchain[i].get();
        vector<string> data = b->getData();
        string header = to_string(b->getIndex()) + b->getPreviousHash() + getMerkleRoot(data) + b->getNonce();
        if (sha256(header) != b->getHash()) return false;
        if (b->getHash().substr(0,6) != "000000") return false;
        if (b->getPreviousHash() != blockchain[i-1]->getHash()) return false;
    }
    return true;
}

__global__ void verifyChain(Block** d_blockchain, int size, bool* d_result) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size - 1) {
        Block* b = d_blockchain[idx + 1];
        vector<string> data = b->getData();
        string header = to_string(b->getIndex()) + b->getPreviousHash() + getMerkleRootGPU(data) + b->getNonce();
        if (sha256(header) != b->getHash() || b->getHash().substr(0,6) != "000000" || b->getPreviousHash() != d_blockchain[idx]->getHash()) {
            *d_result = false;
        }else {
            *d_result = true;
        }   
    }
}