upgtool/scsitool from rockbox

deps: zlib, cryptopp

Patched with custom aes key and iv used by walkmanOne firmware. Patch already applied.

Unpacking any Walkman One firmware, model must be `nw-wm1a`:

```shell
mkdir stockRevert
./upgtool-amd64 -m nw-wm1a -w -o stockRevert/ -e -z 6 StockRevert_Walkman_One_A40.UPG
```

You can get full rockbox source and apply patch by running `make -f rockbox.mk`.
