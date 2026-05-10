#pragma once
#include <string>
#include <vector>

struct VerificationRecord {
    int  index;
    char previousHash[65];
    char hash[65];
    char header[256];
    int  headerLen;
};

bool verifyChainGPU(class BlockChain& blockchain);

