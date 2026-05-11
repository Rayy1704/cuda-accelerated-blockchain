#ifndef BLOCKCHAIN_H
#define BLOCKCHAIN_H

#include <iostream>
#include <string>
#include "hash.hpp"
#include <vector>
#include <memory>
#include <stdexcept>
#include "gpu_mining.h"
#include "common.hpp"
#include "Block.hpp"
#include "gpu_merkle.h"

#include "json.hh"
using json = nlohmann::json;
using namespace std;

class BlockChain {
public:
    BlockChain(int genesis = 1);
    Block getBlock(int index);
    int getNumOfBlocks(void);
    int addBlock(int index, string prevHash, string hash, string nonce, vector<string> &merkle);
    string getLatestBlockHash(void);
    string toJSON(void);
    int replaceChain(json chain);
private:
    vector<unique_ptr<Block>> blockchain;
};

inline BlockChain::BlockChain(int genesis) {
    if (genesis == 0) {
        vector<string> v;
        v.push_back("Genesis Block!");
        string merkleRoot = getMerkleRootGPU(v,'v');
        string header = to_string(0) + string("00000000000000") + merkleRoot;
        auto hash_nonce_pair = findHashGPU(const_cast<char*>(header.c_str()));
        this->blockchain.push_back(std::make_unique<Block>(0, string("00000000000000"), hash_nonce_pair.first, hash_nonce_pair.second, v));
        printf("Created blockchain!\n");
    }
}

inline Block BlockChain::getBlock(int index) {
    for (size_t i = 0; i < blockchain.size(); i++) {
        if (blockchain[i]->getIndex() == index) {
            return *(blockchain[i]);
        }
    }
    throw invalid_argument("Index does not exist.");
}

inline int BlockChain::getNumOfBlocks(void) {
    return this->blockchain.size();
}

inline int BlockChain::addBlock(int index, string prevHash, string hash, string nonce, vector<string> &merkle) {
    string header = to_string(index) + prevHash + getMerkleRootGPU(merkle,'v') + nonce;
    if ((!sha256(header).compare(hash)) && (hash.substr(0, 6) == "000000") && ((size_t)index == blockchain.size())) {
        printf("\nInitializing Block: %d ---- Hash: %s \n", index, hash.c_str());
        printf("Block hashes match --- Adding Block %s \n", hash.c_str());
        this->blockchain.push_back(std::make_unique<Block>(index, prevHash, hash, nonce, merkle));
        return 1;
    }
    cout << "Hash doesn't match criteria\n";
    return 0;
}

inline string BlockChain::getLatestBlockHash(void) {
    return this->blockchain[blockchain.size() - 1]->getHash();
}

inline string BlockChain::toJSON() {
    json j;
    j["length"] = this->blockchain.size();
    for (size_t i = 0; i < this->blockchain.size(); i++) {
        j["data"][this->blockchain[i]->getIndex()] = this->blockchain[i]->toJSON();
    }
    return j.dump(3);
}

inline int BlockChain::replaceChain(json chain) {
    while (this->blockchain.size() > 1) {
        this->blockchain.pop_back();
    }
    for (int a = 1; a < chain["length"].get<int>(); a++) {
        auto block = chain["data"][a];
        vector<string> data = block["data"].get<vector<string>>();
        this->addBlock(block["index"], block["previousHash"], block["hash"], block["nonce"], data);
    } 
    return 1;
}

#endif