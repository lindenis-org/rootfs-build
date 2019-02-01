#!/bin/bash -e

CUR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

if [ ! $OUT_DIR ] ; then
	OUT_DIR=$(dirname $CUR_DIR)/out
fi

[ -z $_TARGET_PLATFORM ] && echo 'source build/envsetup.sh' && exit -1
[ -z $_TARGET_BOARD ] && echo 'source build/envsetup.sh' && exit -1

if [ ! $targetdir ] ; then
	targetdir=$OUT_DIR/$_TARGET_PLATFORM/$_TARGET_BOARD/$_TARGET_OS/target
fi

while mount | grep $targetdir/dev > /dev/null
do
	echo 'Umount dev'
	sudo umount $targetdir/dev
done

echo 'Cleaning'
cat <<EOF | sudo LC_ALL=C LANGUAGE=C LANG=C chroot $targetdir /bin/su -
cd /
rm -rf *
EOF

echo 'Done.'
