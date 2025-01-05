ECHO=/bin/echo
IMAGE=nw-crosstool
DOCKER=docker run -t --rm -v `pwd`:`pwd` -w `pwd` $(IMAGE)
A40 ?= 1
A30 ?= 1

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
	$(MAKE) -C installer MODEL=nw-a50
	$(MAKE) -C installer MODEL=nw-a40
	$(MAKE) -C installer MODEL=nw-a30
	$(MAKE) -C installer walkmanOne
	$(DOCKER) $(MAKE) -C installer/windows OUTFILE=$(OUTFILE) APPNAME=$(APPNAME) A40=$(A40) A30=$(A30)

.DEFAULT_GOAL := build
