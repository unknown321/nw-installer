COMMIT=c8dd31aab79a5a470c95b6253f147e919f8422bc

rockbox:
	git clone git://git.rockbox.org/rockbox
	cd rockbox && git checkout $(COMMIT)
	cd rockbox && git apply ../w1.patch

rockbox-old:
	mkdir rockbox
	cd rockbox && \
	git init . && \
	git remote add origin git://git.rockbox.org/rockbox && \
	git fetch --depth 1 origin $(COMMIT) && \
	git checkout $(COMMIT)
	cd rockbox && git apply ../w1.patch

clean:
	-rm -rf rockbox


.DEFAULT_GOAL := rockbox
