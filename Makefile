# ===== CONFIG =====
GO_DIR=go

OCTAVE_SRC_DIR=octave/src
LIB_DIR=lib
BUILD_DIR=build

LIB_NAME=libk8s.so

# ===== TARGETS =====

.PHONY: all clean dirs gosdk octmod test rebuild

all: dirs gosdk octmod

# Full rebuild: clean, build everything, and test
rebuild: clean dirs gosdk octmod test

# Create directories if they don't exist
dirs:
	mkdir -p $(LIB_DIR)
	mkdir -p $(BUILD_DIR)

# ===== Build Go shared library =====
gosdk:
	@echo "==> Building Go shared library"
	cd $(GO_DIR) && \
	go build -buildmode=c-shared -o ../$(LIB_DIR)/$(LIB_NAME) main.go

# ===== Build Octave modules =====
octmod: $(BUILD_DIR)/kJob.oct $(BUILD_DIR)/kPod.oct $(BUILD_DIR)/kConfigMap.oct $(BUILD_DIR)/kNamespace.oct

$(BUILD_DIR)/kJob.oct: $(OCTAVE_SRC_DIR)/kJob.cpp
	@echo "==> Building kJob.oct"
	mkoctfile $< \
		-L$(CURDIR)/$(LIB_DIR) -lk8s \
		-Wl,-rpath,$(CURDIR)/$(LIB_DIR) \
		-o $@

$(BUILD_DIR)/kPod.oct: $(OCTAVE_SRC_DIR)/kPod.cpp
	@echo "==> Building kPod.oct"
	mkoctfile $< \
		-L$(CURDIR)/$(LIB_DIR) -lk8s \
		-Wl,-rpath,$(CURDIR)/$(LIB_DIR) \
		-o $@

$(BUILD_DIR)/kConfigMap.oct: $(OCTAVE_SRC_DIR)/kConfigMap.cpp
	@echo "==> Building kConfigMap.oct"
	mkoctfile $< \
		-L$(CURDIR)/$(LIB_DIR) -lk8s \
		-Wl,-rpath,$(CURDIR)/$(LIB_DIR) \
		-o $@

$(BUILD_DIR)/kNamespace.oct: $(OCTAVE_SRC_DIR)/kNamespace.cpp
	@echo "==> Building kNamespace.oct"
	mkoctfile $< \
		-L$(CURDIR)/$(LIB_DIR) -lk8s \
		-Wl,-rpath,$(CURDIR)/$(LIB_DIR) \
		-o $@
# ===== Test =====
test:
	@echo "==> Testing Octave can see functions"
	@octave --path $(BUILD_DIR) --eval "disp('Available functions:'); which kJob; which kPod; which kConfigMap; which kNamespace"

# ===== Clean =====
clean:
	@echo "==> Cleaning build artifacts"
	rm -rf $(LIB_DIR)/*
	rm -rf $(BUILD_DIR)/*
	