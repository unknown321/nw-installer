SCSITOOL_SHA256=71893c46299d0465cad41c8dcd4fcf630e003e578648b32512760ef4a43e284a
SCSITOOL=scsitool-nwz-v27.exe
SCSITOOL_URL=https://www.rockbox.org/realwiki/pub/Main/SonyNWDestTool/$(SCSITOOL)
APPNAME ?= test
OUTFILE ?= install.exe
ECHO=/bin/echo
A50 ?= 1
A30 ?= 1
A40 ?= 1
A50Z ?= 1
WM1A ?= 1
WM1Z ?= 1
ZX300 ?= 1
DMPZ1 ?= 1
A40MOD_ONLY ?= 0

$(SCSITOOL):
	wget $(SCSITOOL_URL)
	$(ECHO) "$(SCSITOOL_SHA256) $(SCSITOOL)" | sha256sum --check --status

$(OUTFILE): LICENSE.txt
	makensis -DAPPNAME=$(APPNAME) -DOUTFILE=$(OUTFILE) \
		-DA50=$(A50) \
		-DA40=$(A40) \
		-DA30=$(A30) \
		-DA50Z=$(A50Z) \
		-DWM1A=$(WM1A) \
		-DWM1Z=$(WM1Z) \
		-DZX300=$(ZX300) \
		-DDMPZ1=$(DMPZ1) \
		-DA40MOD_ONLY=$(A40MOD_ONLY) \
		script.nsh

clean:
	-rm -f $(OUTFILE) LICENSE.txt
	-rm -rf a50z dmp-z1 nw-a30 nw-a40 nw-a50 nw-wm1a nw-wm1z nw-zx300 walkmanOne

veryclean: clean
	-rm -f $(SCSITOOL)

LICENSE.txt:
	test -f LICENSE.txt.user || $(ECHO) "License goes here" > LICENSE.txt.user
	cat LICENSE.txt.user > $@
	$(ECHO) -e "\n***\nInstaller license:\n" >> $@
	cat ../../LICENSE >> $@
	$(ECHO) -e "\n***\nInstaller 3rd party licenses:\n" >> $@
	cat ../../LICENSE_3rdparty.txt >> $@

build: $(SCSITOOL) $(OUTFILE)

.DEFAULT_GOAL := build
.PHONY: $(OUTFILE)
