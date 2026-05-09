#ifndef GPU_VERIFICATION_H
#define GPU_VERIFICATION_H

#include <memory>
#include <vector>

class Block;

bool verifyChainGPU(std::vector<std::unique_ptr<Block>>& blockchain);

#endif // GPU_VERIFICATION_H
