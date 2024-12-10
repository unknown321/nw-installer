build:
	$(MAKE) -C abootimg
	$(MAKE) -C cpio
	$(MAKE) -C gzip
	$(MAKE) -C upx
	$(MAKE) -C upgtool
	GOCACHE=/tmp $(MAKE) -C mtkheader release
	GOCACHE=/tmp GOMODCACHE=/tmp $(MAKE) -C cpiostrip release

clean:
	$(MAKE) -C abootimg clean
	$(MAKE) -C cpio clean
	$(MAKE) -C gzip clean
	$(MAKE) -C upx clean
	$(MAKE) -C upgtool clean
	$(MAKE) -C mtkheader clean
	$(MAKE) -C cpiostrip clean

.DEFAULT_GOAL := build
