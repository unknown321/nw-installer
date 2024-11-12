VERSION=890
ZIP=cryptopp$(VERSION).zip
URL=https://github.com/weidai11/cryptopp/releases/download/CRYPTOPP_8_9_0/$(ZIP)

PLATFORM=armv5-unknown-linux-gnueabihf
PPATH=$${PATH}:/x-tools/$(PLATFORM)/bin

$(ZIP):
	wget $(URL)

cryptopp: $(ZIP)
	unzip -d cryptopp cryptopp$(VERSION).zip

cryptopp/libcryptopp.a: cryptopp
	cd cryptopp && \
	export PATH="$(PPATH)" && \
	export CC="$(PLATFORM)-gcc" && \
	export CXX="$(PLATFORM)-g++" && \
	export LDFLAGS="-s" && \
	export CROSS_PREFIX=$(PLATFORM)- && \
	make libcryptopp.a

build: cryptopp/libcryptopp.a

clean:
	-rm -rf $(ZIP) cryptopp

.DEFAULT_GOAL := build
.PHONY: build
