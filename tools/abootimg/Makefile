VERSION=0.6
GZ=abootimg_$(VERSION).orig.tar.gz
URL=https://deb.debian.org/debian/pool/main/a/abootimg/$(GZ)

EXEC_SUFFIX=linux-arm5
PLATFORM=armv5-unknown-linux-gnueabihf
PPATH=$${PATH}:/x-tools/$(PLATFORM)/bin

$(GZ):
	wget $(URL)

abootimg-$(VERSION): $(GZ)
	tar -xf $(GZ)

abootimg-$(VERSION)/abootimg: abootimg-$(VERSION)
	export PATH="$(PPATH)" && \
	cd abootimg-$(VERSION) && \
	make  CC="$(PLATFORM)-gcc" CPPFLAGS="" LDLIBS="" LDFLAGS="-static -s" all

abootimg-$(EXEC_SUFFIX): abootimg-$(VERSION)/abootimg
	cp abootimg-$(VERSION)/abootimg abootimg-$(EXEC_SUFFIX)

build: abootimg-$(EXEC_SUFFIX)

clean:
	rm -rfv abootimg*

.DEFAULT_GOAL := build
.PHONY: build
