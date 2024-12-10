EXEC_SUFFIX=linux-arm5
PLATFORM=armv5-unknown-linux-gnueabihf
ZLIB_VERSION=1.3.1
CRYPTOPP_VERSION=890

ARCH = arm64
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    ARCH = amd64
endif

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PPATH=$${PATH}:/x-tools/$(PLATFORM)/bin

#make -f rockbox.mk
prepare:
	make -f zlib.mk
	make -f cryptopp.mk


UPGTOOL_DIR=rockbox/utils/nwztools/upgtools
UPGTOOL_DIR=./upgtools

upgtool-$(EXEC_SUFFIX): prepare
	$(MAKE) -C $(UPGTOOL_DIR) clean veryclean
	export PATH="$(PPATH)" && \
	$(MAKE) -C $(UPGTOOL_DIR) \
		PREFIX=$(PLATFORM)- \
		LDFLAGS="-s -static -L$(ROOT_DIR)/zlib-$(ZLIB_VERSION) -L$(ROOT_DIR)/cryptopp" \
		CXXFLAGS="-I$(ROOT_DIR)/" \
		CFLAGS="-I$(ROOT_DIR)/zlib-$(ZLIB_VERSION) -I$(ROOT_DIR)/cryptopp -std=c11" \
		LDLIBS="-lcryptopp -lz -lpthread"
	mv $(UPGTOOL_DIR)/upgtool upgtool-$(EXEC_SUFFIX)

upgtool-$(ARCH): prepare
	$(MAKE) -C $(UPGTOOL_DIR) clean veryclean
	$(MAKE) -C $(UPGTOOL_DIR) \
		CFLAGS="-std=c11" \
		LDFLAGS="-s -static -L$(ROOT_DIR)/zlib-$(ZLIB_VERSION) -L$(ROOT_DIR)/cryptopp"
	mv $(UPGTOOL_DIR)/upgtool upgtool-$(ARCH)

SCSITOOL_DIR=rockbox/utils/nwztools/scsitools
SCSITOOL_DIR=./scsitools
scsitool-$(ARCH):
	$(MAKE) -C $(SCSITOOL_DIR) clean 
	$(MAKE) -C $(SCSITOOL_DIR)
	mv $(SCSITOOL_DIR)/scsitool scsitool-$(ARCH)

build: upgtool-$(EXEC_SUFFIX) upgtool-$(ARCH) scsitool-$(ARCH)

#	-make -f rockbox.mk clean
clean:
	-make -f zlib.mk clean
	-make -f cryptopp.mk clean
	$(MAKE) -C $(UPGTOOL_DIR) clean veryclean
	$(MAKE) -C $(SCSITOOL_DIR) clean
	find . -name "*.o" -delete
	-rm upgtool-$(EXEC_SUFFIX)
	-rm upgtool-$(ARCH)
	-rm scsitool-$(ARCH)

.DEFAULT_GOAL := build
.PHONY: build
