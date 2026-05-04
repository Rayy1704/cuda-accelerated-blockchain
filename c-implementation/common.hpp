// author: tko
#ifndef COMMON_H
#define COMMON_H

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <ctime>
#include <iomanip>

void print_hex(const char *label, const uint8_t *v, size_t len) {
    size_t i;

    printf("%s: ", label);
    for (i = 0; i < len; ++i) {
        printf("%02x", v[i]);
    }
    printf("\n");
}

string getMerkleRoot(const vector<string> &merkle) {
    clock_t start = clock();
    if (merkle.empty()){
        clock_t end = clock();
        double elapsedSeconds = static_cast<double>(end - start) / CLOCKS_PER_SEC;
        std::cout << fixed << setprecision(5) << "CPU Merkle tree calculation time size was 0: " << elapsedSeconds << " s" << endl;
        return "";
    }else if (merkle.size() == 1){
        clock_t end = clock();
        double elapsedSeconds = static_cast<double>(end - start) / CLOCKS_PER_SEC;
        std::cout << fixed << setprecision(5) << "CPU Merkle tree calculation time size was 1: " << elapsedSeconds << " s" << endl;
        return sha256(merkle[0]);
    }

    vector<string> new_merkle = merkle;

    while (new_merkle.size() > 1) {
        if ( new_merkle.size() % 2 == 1 )
            new_merkle.push_back(merkle.back());

        vector<string> result;
            
        for (int i=0; i < new_merkle.size(); i += 2){
            string var1 = sha256(new_merkle[i]);
            string var2 = sha256(new_merkle[i+1]);
            string hash = sha256(var1+var2);
            result.push_back(hash);
        }
        new_merkle = result;
    }
        clock_t end = clock();
        double elapsedSeconds = static_cast<double>(end - start) / CLOCKS_PER_SEC;
        cout << fixed << setprecision(5) << "CPU Merkle tree calculation time: size was " << new_merkle.size() << ": " << elapsedSeconds << " s" << endl;
    return new_merkle[0];

}
pair<string,string> findHash(int index, string prevHash, vector<string> &merkle) {
    string header = to_string(index) + prevHash + getMerkleRoot(merkle);
    unsigned int nonce = 0;
    string minedHash;
    clock_t start = clock();
    
    for (nonce = 0; nonce < 100000000000; nonce++ ) {
        string blockHash = sha256(header + to_string(nonce));
        if (blockHash.substr(0,6) == "000000"){
            minedHash = blockHash;
            break;
        }
    }
    clock_t end = clock();
    double elapsedSeconds = static_cast<double>(end - start) / CLOCKS_PER_SEC;
    cout << "CPU mining time: " << elapsedSeconds << " s" << endl;

    if (!minedHash.empty()) {
        return make_pair(minedHash, to_string(nonce));
    }
    return make_pair("fail", "fail");
}
// int addBlock(int index, string prevHash, vector<string> &merkle, vector<unique_ptr<Block> > &blockchain) {
//     string header = to_string(index) + prevHash + getMerkleRoot(merkle);
//     auto pair = findHash(header);
    
//     blockchain.push_back(std::make_unique<Block>(index,prevHash,pair.first,pair.second,merkle));
//     return 1;
// }
#endif