# CUDA-Accelerated High-Throughput Blockchain Framework

**Contributors:** Rayyan Hassan Salman, Ahmad Ibrahim Ahmed
**Institution:** Ghulam Ishaq Khan Institute of Engineering Sciences and Technology (GIKI)
**Project Status:** 100% Completed | Final Project Milestone

---

## 🛠 Tech Stack & Environment

| Category | Technologies |
| :--- | :--- |
| **Languages** | ![C++](https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white) ![CUDA](https://img.shields.io/badge/CUDA-76B900?style=for-the-badge&logo=nvidia&logoColor=white) |
| **Hardware** | ![NVIDIA](https://img.shields.io/badge/NVIDIA_RTX-76B900?style=for-the-badge&logo=nvidia&logoColor=white) ![Intel](https://img.shields.io/badge/Intel_Xeon-0071C5?style=for-the-badge&logo=intel&logoColor=white) |
| **Environment** | ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white) |
| **Editors** | ![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white) ![Vim](https://img.shields.io/badge/Vim-199147?style=for-the-badge&logo=vim&logoColor=white) |

### 💻 Hardware Configuration
All benchmarks and validations for this project were conducted on a high-performance workstation to ensure consistent data and maximize GPU utilization:
* **CPU**: Intel(R) Xeon(R) W-2275 CPU @ 3.30GHz (14 Cores / 28 Threads)
* **GPU**: NVIDIA RTX A2000 12GB (3328 CUDA Cores)
* **CUDA Toolkit**: Version 11.5
* **OS**: Linux-based environment optimized for low-level systems programming

---

## 📊 Final Performance Benchmarks

The transition from a sequential CPU model to a massively parallelized CUDA environment resulted in the following performance shifts, significantly improving block processing times.

| Function | CPU Baseline (Avg) | GPU Accelerated (Avg) | Speedup Factor |
| :--- | :--- | :--- | :--- |
| **Proof-of-Work Mining** | 90.00000 s | 0.08000 s | **1,125x** |
| **Merkle Root Generation** | 0.02336 s | 0.00085 s | **27.5x** |
| **Chain Verification** | 0.02500 s | 0.00070 s | **35.7x** |

---

## 💎 Core Technical Improvements & Code Implementation

### 1. Massively Parallel Proof-of-Work (PoW) Miner
The mining engine was completely re-engineered to utilize the 3,328 cores of the RTX A2000. In a standard CPU model, nonces are tested sequentially, which is the primary bottleneck in block discovery. By migrating this to the GPU, we launch millions of threads in batches, with each thread testing a unique nonce calculated via the block and thread indices. To eliminate the overhead of repeated Global Memory accesses, the block header is stored in `__constant__ unsigned char d_header[256]`. This allows the hardware to perform zero-latency broadcast reads, where the header data is fetched once and provided to all threads in a warp simultaneously, effectively removing memory bandwidth as a limiting factor.

The kernel itself, `mineKernel`, performs a high-speed integer-to-ASCII conversion on the device to append the numeric nonce to the header string. This is a critical custom implementation, as standard C++ libraries like `std::to_string` are unavailable in the CUDA device space. Once the full input string is constructed in a local buffer, the `sha256_device` function is invoked to compute the hash. We achieved the **1,125x speedup** by optimizing for register pressure and using `atomicCAS`. This atomic operation ensures that only the first thread to find a valid hash writes the result back to the host, preventing data races while maintaining an average mining time of just 0.08 seconds.

### 2. Merkle Root Generation via CUDA Dynamic Parallelism (CDP)
Traditional Merkle tree generation is a recursive process that is highly taxing on the CPU when dealing with large transaction batches. Our implementation utilizes an $O(\log N)$ parallel reduction strategy that collapses the transaction list level by level. A standout feature of this component is the use of **CUDA Dynamic Parallelism (CDP)**, implemented via the `merkleParentKernel`. This "driver" kernel is launched and is responsible for managing the reduction process entirely on the GPU. It autonomously spawns child `merkelKernel` grids to process each level of the tree, which eliminates the significant latency associated with returning control to the CPU to launch a new kernel for every tree level.

The worker kernel, `merkelKernel`, handles the heavy lifting by combining consecutive pairs of 32-byte hashes into 64-byte buffers and hashing them into a single 32-byte parent. If a level has an odd number of hashes, the logic automatically duplicates the last hash to maintain a balanced reduction. This sophisticated architecture achieved a **27.5x speedup** for blocks with 1,000 transactions, reducing the time from 0.02336s to 0.00085s. As the transaction count grows—reaching the 4,000+ transactions common in networks like Bitcoin—the speedup factor is expected to grow even further due to the logarithmic scaling of the GPU-based reduction.

### 3. Embarrassingly Parallel Chain Verification
Chain verification is typically a linear $O(N)$ process on the CPU, where each block is verified sequentially to ensure the link to the previous hash is intact. Our framework treats the entire blockchain as a flat data structure, enabling simultaneous verification across thousands of blocks. The `verifyChainKernel` maps each block index directly to a CUDA thread. Each thread independently recalculates the SHA-256 hash of its assigned block's header and performs a string comparison using a custom `stringsEqual` device function to validate both the current hash and its link to the predecessor.

We achieved a **35.7x speedup** by verifying 1,000 blocks in a mere 0.0007s, down from a 0.025s CPU baseline. To ensure absolute integrity, we utilized the `__restrict__` keyword on the `VerificationRecord` pointers. This provides a hint to the compiler that the data buffers do not alias, enabling the hardware to coalesce memory reads and reorder instructions for maximum throughput. If any thread detects a mismatch or a link break, it uses `atomicExch` to instantly signal a global failure flag back to the host. This "fail-fast" mechanism allows the entire chain's validity to be determined in the time it takes to verify the single most complex block.

We achieved a **35.7x speedup** by verifying 1,000 blocks in a mere 0.0007s, down from a 0.025s CPU baseline. To ensure absolute integrity, we utilized the `__restrict__` keyword on the `VerificationRecord` pointers. This provides a hint to the compiler that the data buffers do not alias, enabling the hardware to coalesce memory reads and reorder instructions for maximum throughput.

> **Note on Scale:** These metrics were captured within a sandbox auto-miner environment for initial testing. In a production scenario with significantly higher block volumes, the parallel efficiency of the GPU would scale further, likely resulting in even greater speedup ratios.

If any thread detects a mismatch or a link break, it uses `atomicExch` to instantly signal a global failure flag back to the host. This "fail-fast" mechanism allows the entire chain's validity to be determined in the time it takes to verify the single most complex block.

---

## 🏗 Structural Engineering: The Bridge Implementation

A key technical challenge was integrating complex C++ objects with low-level CUDA kernels without causing compilation errors or memory misalignment. To solve this, we developed **`verificationLink.cpp`** as a dedicated bridge layer. This file is responsible for iterating through the high-level `BlockChain` and `Block` objects and "flattening" their state into a vector of simple `VerificationRecord` structs. These structs use fixed-size C-style arrays to store hashes and headers, ensuring that the data layout is perfectly compatible with the GPU's memory architecture.

This bridge layer serves two critical purposes:
1.  **Compiler Decoupling**: By isolating the bridge logic in a `.cpp` file, we ensure that `g++` handles the heavy C++ standard library headers and object-oriented logic, while `nvcc` is restricted to the specialized device code. This prevents the symbol conflicts and performance overhead often associated with `nvcc` attempting to parse complex C++ templates.
2.  **Optimized Data Marshalling**: The bridge flattens the blockchain into a contiguous raw memory buffer. This allows the `runVerifyKernel` wrapper to perform a single, high-speed `cudaMemcpy` of the entire chain to the device, maximizing PCIe bus efficiency and ensuring the GPU kernels have immediate access to all validation data.

---

## 🛠 Build System & Makefile Logic

Our **`Makefile`** is engineered to handle a hybrid compilation pipeline that manages both host and device code. We define separate flags for each compiler: `CXXFLAGS` for `g++` and `NVCCFLAGS` for `nvcc`. A critical addition is the `-rdc=true` (Relocatable Device Code) flag in the `NVCCFLAGS`. This is a mandatory requirement for **CUDA Dynamic Parallelism**, as it allows the compiler to generate the necessary metadata for kernels to spawn child execution grids directly from the device.

The final linking stage is performed by `nvcc`, which combines the object files from both compilers. We explicitly link the `-lcudadevrt` library, which provides the device-side runtime required for the Merkle tree's dynamic kernel launches, as well as `-lssl -lcrypto` for standard cryptographic support and `-lboost_system` for the networking framework. This integrated build system ensures that all performance-critical CUDA kernels are perfectly linked with the robust C++ server infrastructure.

---

## ⚙️ Low-Level Optimization Glossary

We meticulously utilized specific CUDA keywords and hardware-aware primitives to extract maximum performance from the RTX A2000 hardware:
* **`__constant__`**: Allocated in the constant cache for block headers and SHA-256 constants, ensuring identical data is broadcast to all threads at once.
* **`__restrict__`**: A pointer decoration that guarantees no memory aliasing, enabling the compiler to use specialized load instructions.
* **`__launch_bounds__(256)`**: A kernel-level hint that informs the compiler of the exact thread count, allowing for optimized register allocation per multiprocessor.
* **`extern "C"`**: Leveraged within the bridge layer to ensure C-linkage compatibility between the C++ host logic and low-level CUDA functions.
* **`__device__`**: Declares functions like `sha256_device` that reside entirely in the device space and are optimized for execution within high-throughput mining loops.
* **`atomicCAS` / `atomicExch`**: These hardware-level primitives provide lock-free, thread-safe updates to global status variables, ensuring zero race conditions in the parallel miner and verifier.

---

## 🚀 Build & Run Instructions
1.  **Dependencies**: Ensure NVIDIA Driver, CUDA Toolkit 11.5+, OpenSSL, and Boost are installed.
2.  **Compile**: Run `make` to trigger the hybrid compilation pipeline.
3.  **Run**: Execute `./main` to start the blockchain node.
4.  **Verification**: Follow the command-line prompts to initialize the node. The system will report precise GPU execution times for mining, Merkle generation, and verification in real-time.

---

## 📝 Conclusion
By offloading the most expensive cryptographic and data-structure operations to the GPU's 3,328 cores, we have successfully reduced block discovery and validation latency from **minutes to milliseconds**. This project proves that high-performance hardware acceleration is the definitive path to scaling the next generation of decentralized networks.
