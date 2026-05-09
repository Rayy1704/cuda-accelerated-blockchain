#ifndef GPU_SHA256_H
#define GPU_SHA256_H

#include <stdint.h>
#include <cstring>
#include <cuda_runtime.h>

#define ROTR(x, n)  (((x) >> (n)) | ((x) << (32 - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z)(((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x)      (ROTR(x,  2) ^ ROTR(x, 13) ^ ROTR(x, 22))
#define EP1(x)      (ROTR(x,  6) ^ ROTR(x, 11) ^ ROTR(x, 25))
#define SIG0(x)     (ROTR(x,  7) ^ ROTR(x, 18) ^ ((x) >>  3))
#define SIG1(x)     (ROTR(x, 17) ^ ROTR(x, 19) ^ ((x) >> 10))

extern __constant__ uint32_t K[64];

__device__ void sha256_device(const unsigned char* input, int len, unsigned char* output);

#endif // GPU_SHA256_H
