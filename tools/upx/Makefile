VERSION=4.2.4
OS=amd64_linux
XZ=upx-$(VERSION)-$(OS).tar.xz
URL=https://github.com/upx/upx/releases/download/v$(VERSION)/$(XZ)

$(XZ):
	wget $(URL)

upx-$(VERSION)-$(OS): $(XZ)
	tar -xf $(XZ)

upx/upx: upx-$(VERSION)-$(OS)
	mv -v upx-$(VERSION)-$(OS) upx

build: upx/upx

clean:
	rm -rfv upx*

.DEFAULT_GOAL := build
.PHONY: build
