# chroot-android10

Minimal chroot for android 10 with a few static binaries for debugging

This is a **VERY** simple script to allow you to run any binary you want, static or dynamic, inside a chroot on android 10 devices like the Onyx Boox Nova Air C.

The script does a minimal number of bind mounts for the linker and the libraries, and explains what it does, and why, with specific error codes in case some specific step fails, so it may only be useful if you root your device and want to do other funny things to your device.

## Design goals and plans

Eventually, you should be able to just give a path of your choice, a program you want to run, and you will get everything needed to run this program binary inside this path, no more, no less, by inspecting the dependencies of the binary like how you do with ldd for dynamic libraries.

I'm still working on the linker part that I don't fully understand yet, as I eventually want to do with just 1 custom directory instead of the separate /system and /linkerconfig (and /apex in the newest android, and whatever else they may add in the future...) that exposes too much of Android internals.

This is to voluntarily "break" anything that has hardcoded paths, exposing what they need and why, because using chroot is about control: I want to exert a fine control on the apps I decide to run inside a chroot on my device.

Also, I don't want to give to these apps too much of the vanilla android system in case they try to do bad things from the chroot, or even simply things I don't want. So they will just be spoonfed with what is needed for them to run the way I want, no more no less.

However, this requires granularity:

- At the bare minimum, a static binary gets just the usual directories (/dev /proc /sys ...) and ways for you to debug it (adb, busybox, strace...)

- A dynamic linked binary gets just the above + a linker + the specific libraries it needs to run

- A little extra would be some system libraries I feed the apps

- And for those apps that behave well or that I trust, they will get even more - up to whole dirs!

Eventually, I plan to do that not just with libraries, but also to take snapshots to gain visibility of the changes applied to the filesystems thanks to overlayfs, to firewall and control what is run inside the chroot with the use cgroups etc, and with cascading dependency management through systemd.

The goal is to "control" Google apps, as I don't trust Google much: for example if I start Google Voice to make a call, then stop it, I want to also stop all the Google Play Services and all the other daemons it may depend on or have started.

And by stop I don't mean to just cut their network access: I mean to fully stop every executable it depends on (which will save memory), and unmount the filesystems, so that I can inspect the changes running Google Voice may have made to the chrooted system (ex: install new libraries, update some settings), to historicize these changes in a system of snapshots (a bit like ZFS) and decide which ones are allowed to persist in the future.

Personally, I don't trust Google, but if you don't trust Onyx, you should be able to do the same with the Onyx apps. 

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
