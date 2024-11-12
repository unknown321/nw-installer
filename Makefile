veryclean: clean
	$(MAKE) -C tools clean
	$(MAKE) -C installer veryclean

clean:
	$(MAKE) -C installer clean

prepare:
	$(MAKE) -C crosstool
	docker run -it --rm -v `pwd`:`pwd` -w `pwd` nw-crosstool bash -c "cd tools && make"
	$(MAKE) -C installer prepare

build: prepare
	$(MAKE) -C installer stock
	$(MAKE) -C installer walkmanOne
	$(MAKE) -C installer/windows

.DEFAULT_GOAL := build
