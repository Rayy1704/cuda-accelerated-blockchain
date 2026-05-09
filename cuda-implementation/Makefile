# Variables
TARGET = main
CXX = g++
NVCC = nvcc
SRC_DIR = src
INC_DIR = include

# Flags
# -O3 ensures your mining code is fast
# -rdc=true is used for CUDA relocatable device code
CXXFLAGS = -std=c++14 -Wall -O3 -I$(INC_DIR)
NVCCFLAGS = -std=c++14 -O3 -rdc=true -Xcompiler -Wall -I$(INC_DIR)
LDFLAGS = -lssl -lcrypto -lboost_system -lcudart

# Files
SRCS_CPP = main.cpp
SRCS_CU  = $(SRC_DIR)/gpu_mining.cu $(SRC_DIR)/gpu_sha256.cu $(SRC_DIR)/gpu_merkle.cu $(SRC_DIR)/gpu_verification.cu
OBJS     = main.o gpu_mining.o gpu_sha256.o gpu_merkle.o gpu_verification.o
HDRS     = $(INC_DIR)/gpu_mining.h $(INC_DIR)/gpu_sha256.h $(INC_DIR)/gpu_merkle.h $(INC_DIR)/gpu_verification.h $(INC_DIR)/cuda_error_check.h

.PHONY: all clean

all: $(TARGET)

# Final Link: Combines everything into one main executable
$(TARGET): $(OBJS)
	$(NVCC) $(NVCCFLAGS) $(OBJS) $(LDFLAGS) -o $(TARGET)

# Rule for main.o
main.o: $(SRCS_CPP) $(HDRS)
	$(CXX) $(CXXFLAGS) -c $(SRCS_CPP) -o main.o

# Rules for CUDA objects
gpu_mining.o: $(SRC_DIR)/gpu_mining.cu $(HDRS)
	$(NVCC) $(NVCCFLAGS) -c $(SRC_DIR)/gpu_mining.cu -o gpu_mining.o

gpu_sha256.o: $(SRC_DIR)/gpu_sha256.cu $(INC_DIR)/gpu_sha256.h
	$(NVCC) $(NVCCFLAGS) -c $(SRC_DIR)/gpu_sha256.cu -o gpu_sha256.o

gpu_merkle.o: $(SRC_DIR)/gpu_merkle.cu $(HDRS)
	$(NVCC) $(NVCCFLAGS) -c $(SRC_DIR)/gpu_merkle.cu -o gpu_merkle.o

gpu_verification.o: $(SRC_DIR)/gpu_verification.cu $(HDRS)
	$(NVCC) $(NVCCFLAGS) -c $(SRC_DIR)/gpu_verification.cu -o gpu_verification.o

clean:
	@rm -f *.o $(TARGET)
	@echo "All object files and the main executable have been removed."