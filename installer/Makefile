PLATFORM=armv5-unknown-linux-gnueabihf

ADB=adb wait-for-device

ARCH = arm64
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    ARCH = amd64
endif

UPGTOOL=../tools/upgtool/upgtool-$(ARCH)
SCSITOOL=./tools/upgtool/scsitool-$(ARCH)
UPX=../tools/upx/upx/upx
MODEL=nw-a50
EXEC_SUFFIX=linux-arm5
USER=$(shell whoami)
WALKMAN_DIR=/media/$(USER)/WALKMAN

bin:
	mkdir -p bin

bin/cpiostrip-$(EXEC_SUFFIX):
	cp ../tools/cpiostrip/cpiostrip-$(EXEC_SUFFIX) bin/cpiostrip-$(EXEC_SUFFIX)

bin/mtkheader-$(EXEC_SUFFIX):
	cp ../tools/mtkheader/mtkheader-$(EXEC_SUFFIX) bin/mtkheader-$(EXEC_SUFFIX)

bin/cpio-$(EXEC_SUFFIX):
	cp ../tools/cpio/bin/cpio-$(EXEC_SUFFIX) bin/cpio-$(EXEC_SUFFIX)

bin/gzip-$(EXEC_SUFFIX):
	cp ../tools/gzip/gzip-$(EXEC_SUFFIX) bin/gzip-$(EXEC_SUFFIX)

bin/abootimg-$(EXEC_SUFFIX):
	cp ../tools/abootimg/abootimg-$(EXEC_SUFFIX) bin/abootimg-$(EXEC_SUFFIX)

bin/upgtool-$(EXEC_SUFFIX):
	cp ../tools/upgtool/upgtool-$(EXEC_SUFFIX) bin/upgtool-$(EXEC_SUFFIX)

prepare: bin \
	bin/cpiostrip-$(EXEC_SUFFIX) \
	bin/mtkheader-$(EXEC_SUFFIX) \
	bin/cpio-$(EXEC_SUFFIX) \
	bin/gzip-$(EXEC_SUFFIX) \
	bin/abootimg-$(EXEC_SUFFIX) \
	bin/upgtool-$(EXEC_SUFFIX)
	find ./bin -type f -executable -exec $(UPX) -qqq --best {} \;

stock:
	$(MAKE) OUTDIR=$@ MODEL=nw-a50 upg

walkmanOne:
	$(MAKE) OUTDIR=$@ W1FLAG=-w MODEL=nw-wm1a upg

# file order is important
# see install.sh:unpack()
upg:
	mkdir -p $(OUTDIR) && \
	$(UPGTOOL) -c $(W1FLAG) $(OUTDIR)/NW_WM_FW.UPG -m $(MODEL) \
		install.sh \
		empty.txt \
		bin/cpiostrip-linux-arm5 \
		bin/mtkheader-linux-arm5 \
		bin/cpio-linux-arm5 \
		bin/gzip-linux-arm5 \
		bin/abootimg-linux-arm5 \
		bin/upgtool-linux-arm5 \
		userdata.tar \
		update.sh

#upgrade:
#	$(ADB) shell rm /contents/NW_WM_FW.UPG
#	$(ADB) push installer/stock/NW_WM_FW.UPG /contents/NW_WM_FW.UPG
#	$(ADB) shell nvpflag fup 0x70555766
#	$(ADB) shell reboot
#


clean:
	-rm -rf stock/ walkmanOne/ *.upx userdata.tar
	$(MAKE) -C windows clean

veryclean: clean
	-rm -rf ./bin/
	$(MAKE) -C windows veryclean

build: prepare

.DEFAULT_GOAL := prepare
.PHONY: prepare stock walkmanOne upg
