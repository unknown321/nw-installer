Installation
============

### Windows:

- Download `nw-scrob.exe`, run as administrator. Connect device when prompted, enable USB Mass storage, click `next`.

- Select firmware currently installed on your device - WalkmanOne or stock, click `next`.

- Make sure installation proceeds using correct drive, click `next`.

- Black window pops to start upgrade process, device reboots.

- Wait for updates to finish, enjoy.


### Linux:

##### Without adb (regular install):

  - copy corresponding `NW_WM_FW.UPG` to root directory on device (the one with MUSIC directory)
  - use [scsitool](https://www.rockbox.org/wiki/SonyNWDestTool.html)
    - `scsitool list_devices`
    - choose your device, I use `/dev/sg4`
    - `scsitool -d -s nw-a50 /dev/sg4 do_fw_upgrade` (may require root)
  - device reboots, upgrades a little, reboots again and upgrades again (fully)

##### With adb:

Your device has adb on, no need for scsitool.

Copy `NW_WM_FW.UPG` to root directory on device (the one with MUSIC directory).

Run on your computer:

```shell
adb shell nvpflag fup 0x70555766
adb shell reboot
```

Device reboots, upgrades a little, reboots again and upgrades again (fully).


### Mac:

No native installer.

See Linux section. You'll have to build `scsitool` yourself, good luck!

Usage
=====
Before you start, `Device Settings -> Beep Settings` option __must__ be turned off:

<img src="images/beep.png" height="400">

Why? Beeps are inserted in playing queue as regular tracks; it resets currently played track.

After that just play some tracks and check for `.scrobbler.log` in root directory on your device.