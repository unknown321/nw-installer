SCSITOOL_SHA256=71893c46299d0465cad41c8dcd4fcf630e003e578648b32512760ef4a43e284a
SCSITOOL=scsitool-nwz-v27.exe
SCSITOOL_URL=https://www.rockbox.org/realwiki/pub/Main/SonyNWDestTool/$(SCSITOOL)
APPNAME ?= test
OUTFILE ?= install.exe
ECHO=/bin/echo

$(SCSITOOL):
	wget $(SCSITOOL_URL)
	$(ECHO) "$(SCSITOOL_SHA256) $(SCSITOOL)" | sha256sum --check --status

$(OUTFILE): LICENSE.txt
	makensis -DAPPNAME=$(APPNAME) -DOUTFILE=$(OUTFILE) script.nsh

clean:
	-rm -f $(OUTFILE) LICENSE.txt

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
