## flasher.sh
SBC image writer script with media verification and compressed image support.

### Installation
```
bash <(wget -o /dev/null -qO- https://raw.githubusercontent.com/foundObjects/sbc-flasher/master/install.sh)

# Debian/Ubuntu users:
sudo apt install -y pv

# Other distributions, install pv from your distro repository
```
Note: The installer will call sudo to install to /usr/local/sbin when needed, there's no need to run it with sudo or as root.

### Use
```
Usage: ./flasher.sh (--flags) image(.img|.xz) /dev/target_block_device

Flags:
  -W | --write-only  | --write    Write pass only, no verification
  -V | --verify-only | --verify   Verify only
  -x | --debug                    Extremely verbose output (like bash -x ...)
       --no-pv                    Don't use pipeviewer
```

#### Writing and verifying a compressed image:
```
root@pinebookpro:/data/images# flasher.sh pinebookpro-debian-mrfixit-191127.img.xz /dev/mmcblk0
writing xz compressed image to /dev/mmcblk0
5.01GiB 0:02:46 [30.8MiB/s] [==================================================================>] 100%
0+574861 records in
0+574861 records out
5377097728 bytes (5.4 GB, 5.0 GiB) copied, 181.469 s, 29.6 MB/s
Write successful
Verifying xz image
5.01GiB 0:03:37 [23.6MiB/s] [==================================================================>] 100%
Image verified successfully
```

#### Media verification:
```
root@pinebookpro:/data/images# flasher.sh --verify pinebookpro-debian-mrfixit-191127.img.xz /dev/mmcblk0
Verifying xz image
 546MiB 0:00:23 [18.4MiB/s] [=====>                                                              ] 10% ETA 0:03:12

```
