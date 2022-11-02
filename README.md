# chroot-android10

Minimal chroot for android 10 with a few static binaries for debugging

This may only be useful if you root your device or want to do other funny things to your device

## Getting started

Set the path you want to use as the CHROOT_PATH in the script.

The chroot.sh example uses `/data/data/com.termux/files` which is where termux put its binaries

Upload the sbin.tgz and the chroot to your android device:

```
adb push chroot.sh /data/local/tmp
adb push sbin.tgz /data/local/tmp
```

Start a shell on your computer, or use termux on your device:

```
adb shell
```

Move the chroot file and the static binaries wherever you want, for example on the Onyx Boox in /data/data/com.termux.files/:

```
cp /data/local/tmp/chroot.sh /data/local/tmp/sbin.tgz /data/data/com.termux.files/
```

Decompress the static binaries

```
cd /data/data/com.termux.files/
tar zxvf sbin.tgz
```

## Testing

Run the chroot script:

```
cd /data/data/com.termux.files/
sh chroot.sh
```

## Debugging

You are in a static shell, with a few static binaries (also accessible as their regular names), which should be enough to remotely connect and exchange data (adbd or dropbear), run a basic environment (busybox), debug (strace), test kernels (kexec) and repartition (gdisk, parted, sfdisk, sgdisk) your volumes.

- adbd_static
- busybox_static
- cgdisk_static
- dropbearmulti_static
- fdisk_static
- fixparts_static
- gdisk_static
- kexec_static
- parted_static
- sfdisk_static
- sgdisk_static
- strace_static

These static binaries are mostly the work of @evdenis and [adb_root](https://github.com/evdenis/adb_root/) is his most interesting one: it runs adbd as root, with no password!

I may enable basic auth in a future recompilation. In the meantime, adbd_static run as root in a chroot should be used with great caution.
