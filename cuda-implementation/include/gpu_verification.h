#ifndef GPU_VERIFICATION_H
#define GPU_VERIFICATION_H

// Do NOT #include "BlockChain.hpp" here!

struct VerificationRecord {
    int index;
    int headerLen;
    char previousHash[65];
    char hash[65];
    char header[256];
};

// 1. Declare the pure CUDA wrapper function
bool runVerifyKernel(VerificationRecord* h_records, int numRecords);

// 2. Forward declare BlockChain
class BlockChain;

// 3. Declare your new host wrapper function
bool verifyChainGPU(BlockChain& bc);

#endif