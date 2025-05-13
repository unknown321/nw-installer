ECHO=/bin/echo
IMAGE=nw-crosstool
DOCKER=docker run -t --rm -v `pwd`:`pwd` -w `pwd` $(IMAGE)
A50 ?= 1
A30 ?= 1
A40 ?= 1
A50Z ?= 1
WM1AZ ?= 1
ZX300 ?= 1
DMPZ1 ?= 1
A40MOD_ONLY ?= 0
A30MOD_ONLY ?= 0
USERDATA_FILENAME ?= userdata.tar.gz

veryclean: clean
	$(MAKE) -C tools clean
	$(MAKE) -C installer veryclean

clean:
	$(MAKE) -C installer clean

prepare_deps:
	$(MAKE) -C crosstool
	docker run -it --rm -v `pwd`:`pwd` -w `pwd` nw-crosstool bash -c "cd tools && make"
	$(MAKE) -C installer prepare

LICENSE_3rdparty.txt:
	@$(ECHO) -e "\n***\nupgtools, scsitools:\n" >> $@
	@head -n 20 tools/upgtool/upgtools/mg.cpp >> $@
	@$(ECHO) -e "\n***\ncryptopp:\n" >> $@
	@cat tools/upgtool/cryptopp/License.txt >> $@
	@$(ECHO) -e "\n***\nzlib:\n" >> $@
	@cat tools/upgtool/zlib-1.3.1/LICENSE >> $@
	@$(ECHO) -e "\n***\ngzip, cpio, abootimg:\n" >> $@
	@cat tools/gzip/gzip-1.13/COPYING >> $@

prepare: prepare_deps LICENSE_3rdparty.txt

build: prepare
	$(MAKE) -C installer MODEL=nw-a50 USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer MODEL=nw-a40 A40MOD_ONLY=$(A40MOD_ONLY) USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer MODEL=nw-a30 A30MOD_ONLY=$(A30MOD_ONLY) USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer MODEL=nw-zx300 USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer MODEL=nw-wm1a USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer MODEL=dmp-z1 USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer walkmanOne USERDATA_FILENAME=$(USERDATA_FILENAME)
	$(MAKE) -C installer a50z USERDATA_FILENAME=$(USERDATA_FILENAME)

win:
	$(DOCKER) $(MAKE) -C installer/windows OUTFILE=$(OUTFILE) APPNAME=$(APPNAME) A40=$(A40) A30=$(A30) A40MOD_ONLY=$(A40MOD_ONLY) A30MOD_ONLY=$(A30MOD_ONLY) A50=$(A50) A50Z=$(A50Z) WM1A=$(WM1A) ZX300=$(ZX300) DMPZ1=$(DMPZ1) USERDATA_FILENAME=$(USERDATA_FILENAME)

.DEFAULT_GOAL := build
