# Variables
TARGET = main
CXX = g++
NVCC = nvcc

# Flags
# -O3 ensures your mining code is fast
# -rdc=true is used for CUDA relocatable device code
CXXFLAGS = -std=c++14 -Wall -O3
NVCCFLAGS = -std=c++14 -O3 -rdc=true -Xcompiler -Wall
LDFLAGS = -lssl -lcrypto -lboost_system -lcudart

# Files
SRCS_CPP = main.cpp
SRCS_CU  = gpu_mining.cu
SHA_CU   = sha256_gpu.cu
MERKLE_CU = gpu_merkle.cu
OBJS     = main.o gpu_mining.o sha256_gpu.o gpu_merkle.o
HDRS     = gpu_mining.h sha256_gpu.h cuda_error_check.h gpu_merkle.h

.PHONY: all clean

all: $(TARGET)

# Final Link: Combines everything into one main executable
$(TARGET): $(OBJS)
	$(NVCC) $(NVCCFLAGS) $(OBJS) $(LDFLAGS) -o $(TARGET)

# Rule for main.o
main.o: $(SRCS_CPP) $(HDRS)
	$(CXX) $(CXXFLAGS) -c $(SRCS_CPP) -o main.o

# Rule for gpu_mining.o
gpu_mining.o: $(SRCS_CU) $(HDRS)
	$(NVCC) $(NVCCFLAGS) -c $(SRCS_CU) -o gpu_mining.o

# Rule for sha256_gpu.o
sha256_gpu.o: $(SHA_CU) sha256_gpu.h
	$(NVCC) $(NVCCFLAGS) -c $(SHA_CU) -o sha256_gpu.o

gpu_merkle.o: $(MERKLE_CU) $(HDRS)
	$(NVCC) $(NVCCFLAGS) -c $(MERKLE_CU) -o gpu_merkle.o
clean:
	@rm -f *.o $(TARGET)
	@echo "All object files and the main executable have been removed."