VERSION=1.13
URL=https://ftp.gnu.org/gnu/gzip/gzip-$(VERSION).zip
ZIP=gzip-$(VERSION).zip

EXEC_SUFFIX=linux-arm5
PLATFORM=armv5-unknown-linux-gnueabihf
PPATH=$${PATH}:/x-tools/$(PLATFORM)/bin

$(ZIP):
	wget $(URL)

gzip-$(VERSION): $(ZIP)
	unzip $(ZIP)

gzip-$(VERSION)/gzip: gzip-$(VERSION)
	export PATH="$(PPATH)" && \
	export CC="$(PLATFORM)-gcc" && \
	export LDFLAGS="-s -static" && \
	cd gzip-$(VERSION) && ./configure --host=arm-linux-gnueabihf && \
	make

gzip-$(EXEC_SUFFIX): gzip-$(VERSION)/gzip
	cp gzip-$(VERSION)/gzip gzip-$(EXEC_SUFFIX)

build: gzip-$(EXEC_SUFFIX)

clean:
	rm -rf gzip-*


.DEFAULT_GOAL := build
.PHONY: build
