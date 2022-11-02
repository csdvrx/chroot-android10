#!/bin/sh
# Copyright (c) CSDVRX, 2022, 

################################################################
# This is the bare mininum for a functional chroot with debugs #
################################################################

# The system chroot command
CHROOT_COMMAND=`which chroot`       || exit -1

# The chroot path which can be anything you want
CHROOT_PATH=/data/data/com.termux/files

# The statically compiled utilities live in sbin
ls $CHROOT_PATH/sbin  >/dev/null    || exit -2

# A minimal set of tools is present to help debug and fix problems
# Show them, and if they don't exit, exit
ls $CHROOT_PATH/sbin/busybox_static || exit -3
ls $CHROOT_PATH/sbin/adbd_static    || exit -4
ls $CHROOT_PATH/sbin/strace_static  || exit -5

# List what's also packaged: kexec dropbear and some disk utils with more basic tools to come
ls $CHROOT_PATH/sbin/*_static |grep -v busybox_static |grep -v adbd_static |grep -v strace_static

# Create the symlinks from the static binaries name to the usual names if necessary
ls $CHROOT_PATH/sbin/sh > /dev/null \
      || ( cd $CHROOT_PATH/sbin && sh ./symlinks.sh      || exit -6 )

# Most tools require some basic directories, create them and bind them as needed
ls $CHROOT_PATH/card >/dev/null \
      || ( mkdir $CHROOT_PATH/card                       || exit -7  )
ls $CHROOT_PATH/dev >/dev/null \
      || ( mkdir $CHROOT_PATH/dev                        || exit -8  )
ls $CHROOT_PATH/dev/pts >/dev/null \
      || ( mkdir $CHROOT_PATH/dev/pts                    || exit -9  )
ls $CHROOT_PATH/proc >/dev/null \
      || ( mkdir $CHROOT_PATH/proc                       || exit -10 )
ls $CHROOT_PATH/sys >/dev/null \
      || ( mkdir $CHROOT_PATH/sys                        || exit -11 )
ls $CHROOT_PATH/tmp >/dev/null \
      || ( mkdir $CHROOT_PATH/tmp                        || exit -12 )
mount | grep $CHROOT_PATH/card      >/dev/null \
      || ( mount --bind /sdcard  $CHROOT_PATH/card       || exit -13 )
mount | grep $CHROOT_PATH/dev\      >/dev/null \
      || ( mount --bind /dev     $CHROOT_PATH/dev        || exit -14 )
mount | grep $CHROOT_PATH/dev/pts\  >/dev/null \
      || ( mount --bind /dev/pts $CHROOT_PATH/dev/pts    || exit -15 )
mount | grep $CHROOT_PATH/proc      >/dev/null \
      || ( mount --bind /proc    $CHROOT_PATH/proc       || exit -16 )
mount | grep $CHROOT_PATH/sys\      >/dev/null \
      || ( mount --bind /sys     $CHROOT_PATH/sys        || exit -17 ) 
mount | grep $CHROOT_PATH/tmp       >/dev/null \
      || ( mount --bind /data/local/tmp $CHROOT_PATH/tmp || exit -18 ) 

# Also create the configuration directories if they don't exist: so far only /linkerconfig and /etc
ls $CHROOT_PATH/linkerconfig >/dev/null \
  || ( mkdir $CHROOT_PATH/linkerconfig                   || exit -19 )

ls $CHROOT_PATH/etc >/dev/null \
  || ( mkdir $CHROOT_PATH/etc                            || exit -20 )

################################################################
# This only matters if you want to use dynamic linked binaries #
################################################################

# Android 9+ has a bizzare linker namespace isolation policy
#https://source.android.com/docs/core/architecture/vndk/linker-namespace

# Symptoms: inside a chroot, dynamic binaries fail even if you provide the libraries, strace shows ENOENT
#https://unix.stackexchange.com/questions/146059/why-does-chroot-get-enoent-on-an-existing-file
#https://stackoverflow.com/questions/70056765/chroot-no-such-file-or-directory-prints-wrong-missing-file

# Solution: you must provide the linker to execute dynamically linked binaries
# /system/bin/linker64 is necessary: on Android 10, symlinked to /apex/com.android.runtime/bin/linker64
# /linkerconfig/ld.config.txt seem to also be necessary: to define the paths and the policies
#
# TODO: both paths seem hardcoded but might be redefinable using a file in a
# magic path or a sysctl call, or a kernel cmdline parameter, which could allow
# /apx or /ndk or something else very "android specific" to be used to put all
# the android linker and apex related stuff

echo "
# /system/bin/linker64 is needed to execute non static binaries
# (yes, you need it even if you provide all the dynamic libraries your chroot needs)

# map the other binaries executed from
dir.system=/system/bin
# to the system section
[system]
# as the libc, libm etc can be found in the ndk
namespace.default.search.paths = /system/${LIB}
# with "${LIB}" replaced by "lib64" on 64bit targets or by "lib" on 32bit ones
namespace.default.permitted.paths = /system/${LIB}
# and let other things access them
namespace.default.isolated = false

# also map the binaries executed from
dir.usr_bin = /usr/bin/
# into a specific section
[usr_bin]
# so they will use libraries from
namespace.default.search.paths = /usr/${LIB}
# that may have symlinks, so for the AddressSANintizer use the same path
namespace.default.asan.search.paths = /usr/${LIB}
# the system libraries may also be used, and they are found in
namespace.default.permitted.paths = /system/${LIB}
# along with their symlinks from this same place for the ASAN
namespace.default.asan.permitted.paths = /system/${LIB}
" > $CHROOT_PATH/linkerconfig/ld.config.txt || exit -21

# Add basic networking by populating the dns server iff there's a network connectivity
# FIXME: this currently requires the genuine ip tool, not busybox ip which doesn't understand -br a
/bin/ip -br a | grep UP > /dev/null \
  && ( \
      echo nameserver `getprop net.dns1` | grep [0-9] >  $CHROOT_PATH/etc/resolv.conf ; \
      echo nameserver `getprop net.dns2` | grep [0-9] >> $CHROOT_PATH/etc/resolv.conf ; \
     ) \
  || rm -f $CHROOT_PATH/etc/resolv.conf

ls $CHROOT_PATH/system >/dev/null       || mkdir $CHROOT_PATH/system            || exit -21
ls $CHROOT_PATH/system/bin >/dev/null   || mkdir $CHROOT_PATH/system/bin        || exit -22
ls $CHROOT_PATH/system/lib >/dev/null   || mkdir $CHROOT_PATH/system/lib        || exit -23
ls $CHROOT_PATH/system/lib64 >/dev/null || mkdir $CHROOT_PATH/system/lib64      || exit -24

mount | grep $CHROOT_PATH/apex/bin   >/dev/null \
      || ( mount --bind /apex/com.android.runtime/bin $CHROOT_PATH/system/bin   || exit -25 )
mount | grep $CHROOT_PATH/system/lib\  >/dev/null \
      || ( mount --bind /system/lib                   $CHROOT_PATH/system/lib   || exit -26 )
mount | grep $CHROOT_PATH/system/lib64 >/dev/null \
      || ( mount --bind /system/lib64                 $CHROOT_PATH/system/lib64 || exit -27 )

#################################################################
# This only matters if you don't want to run everything as root #
#################################################################

## Android reserves UIDs in range 1000-9999 for system use
# https://android.stackexchange.com/questions/208523/how-androids-permissions-mapping-with-uids-gids-works
# https://github.com/guardianproject/lildebi/issues/6

# In case regular users are created and used, they can get network access with:
#groupadd -g 3001 aid_bt
#groupadd -g 3002 aid_bt_net
#groupadd -g 3003 aid_inet
#groupadd -g 3004 aid_net_raw
#groupadd -g 3005 aid_admin
#usermod -a -G aid_bt,aid_bt_net,aid_inet,aid_net_raw,aid_admin thisusername

# In case running su gets segkilled
#mount -o remount,dev,suid /data

# Finally, what to run in chroot, here just a shell for example
PATH=/sbin $CHROOT_COMMAND $CHROOT_PATH /sbin/ash

# Cleanup
umount $CHROOT_PATH/sys
umount $CHROOT_PATH/proc
umount $CHROOT_PATH/dev/pts
umount $CHROOT_PATH/dev
umount $CHROOT_PATH/card
umount $CHROOT_PATH/system/bin
umount $CHROOT_PATH/system/lib
umount $CHROOT_PATH/system/lib64
umount $CHROOT_PATH/tmp
