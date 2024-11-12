SCSITOOL_SHA256=71893c46299d0465cad41c8dcd4fcf630e003e578648b32512760ef4a43e284a
SCSITOOL=scsitool-nwz-v27.exe
SCSITOOL_URL=https://www.rockbox.org/realwiki/pub/Main/SonyNWDestTool/$(SCSITOOL)
APPNAME ?= test
OUTFILE ?= install.exe

$(SCSITOOL):
	wget $(SCSITOOL_URL)
	echo "$(SCSITOOL_SHA256) $(SCSITOOL)" | sha256sum --check --status

$(OUTFILE):
	makensis -DAPPNAME=$(APPNAME) -DOUTFILE=$(OUTFILE) script.nsh

clean:
	-rm -f $(OUTFILE)

veryclean: clean
	-rm -f $(SCSITOOL)

build: $(SCSITOOL) $(OUTFILE)

.DEFAULT_GOAL := build
.PHONY: $(OUTFILE)
