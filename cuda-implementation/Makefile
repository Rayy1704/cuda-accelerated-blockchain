NVCC = nvcc
CXX = g++

# Separate flags: g++ handles host code, nvcc handles device code
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra -Wno-deprecated-declarations
NVCCFLAGS = -O3 -std=c++17 -rdc=true -Xcompiler -Wall,-Wextra,-Wno-deprecated-declarations

SRC_DIR = src
INC_DIR = include
TARGET = main

# List your CUDA source files
CU_SRCS = $(SRC_DIR)/gpu_mining.cu \
          $(SRC_DIR)/gpu_sha256.cu \
          $(SRC_DIR)/gpu_merkle.cu \
          $(SRC_DIR)/gpu_verification.cu

# List your C++ source files (Updated to point to src/)
CPP_SRCS = main.cpp $(SRC_DIR)/verificationLink.cpp

# Object files
CU_OBJS = $(CU_SRCS:.cu=.o)
CPP_OBJS = $(CPP_SRCS:.cpp=.o)

.PHONY: all clean run

all: $(TARGET)

# 1. Compile C++ host code with g++
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -I$(INC_DIR) -I. -c $< -o $@

# 2. Compile CUDA device code with nvcc
%.o: %.cu
	$(NVCC) $(NVCCFLAGS) -I$(INC_DIR) -I. -c $< -o $@

# 3. Link everything together using nvcc
$(TARGET): $(CU_OBJS) $(CPP_OBJS)
	$(NVCC) $(NVCCFLAGS) -o $@ $^ -lssl -lcrypto -lboost_system

clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET) $(CU_OBJS) $(CPP_OBJS)

run: $(TARGET)
	./$(TARGET)