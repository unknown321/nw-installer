VERSION=3.7.3
URL=https://github.com/libarchive/libarchive/releases/download/v$(VERSION)/libarchive-$(VERSION).tar.gz
PLATFORM=armv5-rpi-linux-gnueabihf

libarchive-$(VERSION).tar.gz:
	wget $(URL)

libarchive-$(VERSION): libarchive-$(VERSION).tar.gz
	tar -xf libarchive-$(VERSION).tar.gz

libarchive-$(VERSION)/bsdcpio: libarchive-$(VERSION)
	export PATH="$${PATH}:$(PWD)/build/x-tools/$(PLATFORM)/bin" && \
	export CC="$(PLATFORM)-gcc" && \
	export LDFLAGS="-s -static" && \
	cd libarchive-$(VERSION) && ./configure --host=arm-linux-gnueabihf --enable-static --enable-bsdcpio=static && \
	make

build: libarchive-$(VERSION)/bsdcpio