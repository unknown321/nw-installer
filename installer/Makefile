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
MODEL ?= nw-a50
A40MOD_ONLY ?= 0
EXEC_SUFFIX=linux-arm5
USER=$(shell whoami)
WALKMAN_DIR=/media/$(USER)/WALKMAN
USERDATA_FILENAME ?= userdata.tar.gz

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

$(MODEL)/NW_WM_FW.UPG:
	$(MAKE) OUTDIR=$(MODEL) MODEL=$(MODEL) upg

windows/$(MODEL)/NW_WM_FW.UPG:
	$(MAKE) OUTDIR=windows/$(MODEL) MODEL=$(MODEL) A40MOD_ONLY=$(A40MOD_ONLY) upgwindows

$(MODEL): $(MODEL)/NW_WM_FW.UPG windows/$(MODEL)/NW_WM_FW.UPG

walkmanOne:
	$(MAKE) OUTDIR=$@ W1FLAG=-w MODEL=nw-wm1a upg
	$(MAKE) OUTDIR=windows/$@ W1FLAG=-w MODEL=nw-wm1a upgwindows

a50z:
	$(MAKE) OUTDIR=$@ W1FLAG=--a50z MODEL=nw-a50z upg
	$(MAKE) OUTDIR=windows/$@ W1FLAG=--a50z MODEL=nw-a50z upgwindows

# file order is important
# see install.sh:unpack()
upg:
	mkdir -p $(OUTDIR) && \
	$(UPGTOOL) -c $(OUTDIR)/NW_WM_FW.UPG -m $(MODEL) $(W1FLAG) \
		install.sh \
		empty.txt \
		bin/cpiostrip-linux-arm5 \
		bin/mtkheader-linux-arm5 \
		bin/cpio-linux-arm5 \
		bin/gzip-linux-arm5 \
		bin/abootimg-linux-arm5 \
		bin/upgtool-linux-arm5 \
		update.sh \
		$(USERDATA_FILENAME)

# userdata is put on /contents to prevent duplication in exe
upgwindows:
	mkdir -p $(OUTDIR) && \
	$(UPGTOOL) -c $(OUTDIR)/NW_WM_FW.UPG -m $(MODEL) $(W1FLAG) \
		install.sh \
		empty.txt \
		bin/cpiostrip-linux-arm5 \
		bin/mtkheader-linux-arm5 \
		bin/cpio-linux-arm5 \
		bin/gzip-linux-arm5 \
		bin/abootimg-linux-arm5 \
		bin/upgtool-linux-arm5 \
		update.sh

#upgrade:
#	$(ADB) shell rm /contents/NW_WM_FW.UPG
#	$(ADB) push installer/stock/NW_WM_FW.UPG /contents/NW_WM_FW.UPG
#	$(ADB) shell nvpflag fup 0x70555766
#	$(ADB) shell reboot
#


clean:
	-rm -rf walkmanOne/ \
		nw* \
		a50z \
		windows/walkmanOne/ \
		windows/nw* \
		*.upx \
		userdata.tar.gz \
		userdata.uninstaller.tar.gz
	$(MAKE) -C windows clean

veryclean: clean
	-rm -rf ./bin/
	$(MAKE) -C windows veryclean

build: prepare

.DEFAULT_GOAL := $(MODEL)
.PHONY: prepare stock walkmanOne upg upgwindows a50z
