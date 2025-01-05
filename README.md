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

Pack your data and install script named `run.sh` into `userdata.tar.gz`. See [installer/run.sh](./installer/run.sh).

- copy `userdata.tar.gz` into `installer` directory
- run `make`
- grab UPG files from `installer/<model>/` and `installer/walkmanOne`

Windows:

- pack uninstaller script named `run.sh` and other data into `userdata.uninstaller.tar.gz`
- copy `userdata.uninstaller.tar.gz` into `installer` directory
- run `make build win`
- grab Windows installer from `installer/windows/install.exe`

You can provide following arguments to `make`:

- `USERDATA_FILENAME`: custom name for `userdata.tar.gz` used in UPG files (not for Windows)
- `OUTFILE`: sets Windows installer name
- `APPNAME`: sets application name in installer
- `A40`: NW-A40 Windows support (default: on)
- `A30`: NW-A30 Windows support (default: on)

### Example:

Produces Walkman One, A50/40/30 `UPG` files:

```shell
$ make
...
tree -P "*.UPG" --noreport installer/
installer/
├── bin
├── nw-a30
│   └── NW_WM_FW.UPG
├── nw-a40
│   └── NW_WM_FW.UPG
├── nw-a50
│   └── NW_WM_FW.UPG
└──  walkmanOne
     └── NW_WM_FW.UPG
```

Produces Walkman One, A50/40/30 `UPG` files and Windows installer (A40 is disabled):

```shell
$ make build win OUTFILE=mybinary.exe APPNAME=uniqueApplication A40=0
...
Processed 1 file, writing output (x86-unicode):

Output: "mybinary.exe"
```

Produces `UPG` files using `test.tar.gz`:

```shell
$ make build USERDATA_FILENAME=test.tar.gz
```