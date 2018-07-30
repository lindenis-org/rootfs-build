#!/bin/bash -e

CUR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

if [ ! $OUT_DIR ] ; then
	OUT_DIR=$(dirname $CUR_DIR)/out
fi

[ -z $_TARGET_PLATFORM ] && echo 'source build/envsetup.sh' && exit -1
[ -z $_TARGET_BOARD ] && echo 'source build/envsetup.sh' && exit -1

if [ ! $targetdir ] ; then
	targetdir=$OUT_DIR/$_TARGET_PLATFORM/$_TARGET_BOARD/debian/target
fi

sudo LC_ALL=C LANGUAGE=C LANG=C chroot $targetdir /bin/su -
