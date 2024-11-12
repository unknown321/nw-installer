VERSION=1.3.1
GZ=zlib-$(VERSION).tar.gz
URL=https://zlib.net/fossils/$(GZ)

PLATFORM=armv5-unknown-linux-gnueabihf
PPATH=$${PATH}:/x-tools/$(PLATFORM)/bin

$(GZ):
	wget $(URL)

zlib-$(VERSION): $(GZ)
	tar -xf $(GZ)

zlib-$(VERSION)/libz.a: zlib-$(VERSION)
	cd zlib-$(VERSION) && \
	export PATH="$(PPATH)" && \
	export CC="$(PLATFORM)-gcc" && \
	export LDFLAGS="-s" && \
	export CROSS_PREFIX=$(PLATFORM)- && \
	./configure && \
	make libz.a

build: zlib-$(VERSION)/libz.a

clean:
	-rm -rf zlib-*

.DEFAULT_GOAL := build
.PHONY: build
