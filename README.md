nw-installer
============

Generic service installer for Walkman NW-A50Series.

### Requirements:

  - Linux
  - Docker
  - ~8GB free space

### Build:

Build toolchain + tools (~20 minutes on i7 7700, ~1 hour on i3 7100):

```shell
make prepare
```

UPG files + windows installer:

```shell
make
```

Rebuilding UPG

```shell
make clean && make
```

Rebuilding UPG with tools

```shell
make veryclean && make
```

Rebuilding toolchain

```shell
docker image rm nw-crosstool && make prepare
```

### Usage:

Pack your data and install script named `run.sh` into `userdata.tar`. See [installer/run.sh](./installer/run.sh).

  - copy `userdata.tar` into `installer` directory
  - run `make`
  - grab UPG files from `installer/stock/` and `installer/walkmanOne`
  - grab Windows installer from `installer/windows/install.exe`

You can provide following arguments to `make`:

  - `OUTFILE`: sets Windows installer name
  - `APPNAME`: sets application name in installer

### Example:

```shell
$ make OUTFILE=mybinary.exe APPNAME=uniqueApplication
...
Processed 1 file, writing output (x86-unicode):

Output: "mybinary.exe"
```
