NVCC = nvcc
NVCCFLAGS = -O3 -rdc=true --expt-relaxed-constexpr --expt-extended-lambda -Xcompiler -Wall,-Wextra
SRC_DIR = src
INC_DIR = include
TARGET = main

SRCS = main.cpp \
       $(SRC_DIR)/gpu_mining.cu \
       $(SRC_DIR)/gpu_sha256.cu \
       $(SRC_DIR)/gpu_merkle.cu \
       $(SRC_DIR)/gpu_verification.cu

HDRS = $(INC_DIR)/gpu_mining.h \
       $(INC_DIR)/gpu_sha256.h \
       $(INC_DIR)/gpu_merkle.h \
       $(INC_DIR)/gpu_verification.h \
       $(INC_DIR)/cuda_error_check.h

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(SRCS) $(HDRS)
	$(NVCC) $(NVCCFLAGS) -I$(INC_DIR) -I. -o $@ $(SRCS) -lssl -lcrypto -lboost_system

clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)
