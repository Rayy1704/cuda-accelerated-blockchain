#ifndef MINING_GPU_H
#define MINING_GPU_H

#include <stdio.h>
#include <string>
#include <stdint.h>
#include <utility> // Required for std::pair

// Declaration of the GPU mining wrapper function
std::pair<std::string, std::string> findHashGPU(char* header);

#endif // MINING_GPU_H