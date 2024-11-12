SHA256SUM=e4168395d19be53aa6466269c48a2f4b4afb48e626f39ff08a0685b84f890680
DEB=cpio_2.13+dfsg-7.1~deb11u1_armhf.deb
URL=http://ftp.us.debian.org/debian/pool/main/c/cpio/cpio_2.13+dfsg-7.1~deb11u1_armhf.deb
EXEC_SUFFIX=linux-arm5

$(DEB):
	wget $(URL)
	echo "$(SHA256SUM) $(DEB)" | sha256sum -c

data.tar.xz: $(DEB)
	ar x $(DEB)

bin/cpio: data.tar.xz
	tar -xf data.tar.xz

bin/cpio-$(EXEC_SUFFIX): bin/cpio
	cp bin/cpio bin/cpio-$(EXEC_SUFFIX)

build: bin/cpio-$(EXEC_SUFFIX)

clean:
	rm -rf bin debian_control $(DEB) usr *.xz debian-binary

.DEFAULT_GOAL := build
.PHONY: build