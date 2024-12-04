ECHO=/bin/echo
IMAGE=nw-crosstool
DOCKER=docker run -t --rm -v `pwd`:`pwd` -w `pwd` $(IMAGE)

veryclean: clean
	$(MAKE) -C tools clean
	$(MAKE) -C installer veryclean

clean:
	$(MAKE) -C installer clean

prepare: LICENSE_3rdparty.txt
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

build: prepare
	$(MAKE) -C installer stock
	$(MAKE) -C installer walkmanOne
	$(DOCKER) $(MAKE) -C installer/windows

.DEFAULT_GOAL := build
