#!/bin/bash

CUR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

if [ ! $OUT_DIR ] ; then
	OUT_DIR=$(dirname $CUR_DIR)/out
fi

[ -z $_TARGET_PLATFORM ] && echo 'source build/envsetup.sh' && exit -1
[ -z $_TARGET_BOARD ] && echo 'source build/envsetup.sh' && exit -1

if [ ! $targetdir ] ; then
	targetdir=$OUT_DIR/$_TARGET_PLATFORM/$_TARGET_BOARD/$_TARGET_OS/target
fi

rootfs_image=${OUT_DIR}/$_TARGET_PLATFORM/$_TARGET_BOARD/rootfs.ext4
rootfs_size=3072
mount_point=${OUT_DIR}/$_TARGET_PLATFORM/$_TARGET_BOARD/rootfs

# If mount point is mounted, umount it
mount | grep $mount_point > /dev/null
[ $? -eq 0 ] && sudo umount $mount_point

set -e

rm -rf $mount_point
mkdir $mount_point

dd if=/dev/zero of=$rootfs_image bs=1M count=0 seek=$rootfs_size

finish()
{
	sudo umount $mount_point
	echo "Make rootfs failed"
	exit -1
}

echo "Format rootfs to ext4"
mkfs.ext4 -F $rootfs_image

echo "Mount rootfs to mount point"
sudo mount $rootfs_image $mount_point
trap finish ERR

echo "Copy rootfs to mount point"
sudo cp -rfp $targetdir/* $mount_point

echo "Umount rootfs"
sudo umount $mount_point

e2fsck -p -f $rootfs_image
# resize2fs -M $rootfs_image
