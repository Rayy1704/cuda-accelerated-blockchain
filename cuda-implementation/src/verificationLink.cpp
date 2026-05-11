#include <vector>
#include <string>
#include <cstring>

#include "Block.hpp"
#include "BlockChain.hpp"
#include "gpu_verification.h"
#include "gpu_merkle.h"       
using namespace std;
bool verifyChainGPU(BlockChain& bc) {
    if (bc.getNumOfBlocks() < 2) {
        return true; 
    }

    std::vector<VerificationRecord> h_blockChain;
    
    // Iterate through the blockchain to build the flat array of records
    for (int i = 0; i < bc.getNumOfBlocks(); ++i) {
        Block temp = bc.getBlock(i);
        std::vector<std::string> data = temp.getData();
        std::string merkleRoot = getMerkleRootGPU(data,'n');
        std::string header = std::to_string(temp.getIndex()) + temp.getPreviousHash() + merkleRoot + temp.getNonce();
        
        VerificationRecord record;
        record.index = temp.getIndex();
        record.headerLen = (int)header.size();
        
        // Safely copy strings into the fixed-size C-style char arrays
        std::memset(record.previousHash, 0, 65);
        std::strncpy(record.previousHash, temp.getPreviousHash().c_str(), 64);
        
        std::memset(record.hash, 0, 65);
        std::strncpy(record.hash, temp.getHash().c_str(), 64);
        
        std::memset(record.header, 0, 256);
        std::memcpy(record.header, header.c_str(), header.size());
        
        h_blockChain.push_back(record);
    }
    
    // Pass the raw memory pointer to the CUDA wrapper
    return runVerifyKernel(h_blockChain.data(), h_blockChain.size());
}