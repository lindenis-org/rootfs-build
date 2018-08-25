#!/bin/bash -e

CUR_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

if [ ! $OUT_DIR ] ; then
	OUT_DIR=$(dirname $CUR_DIR)/out
fi

if [ ! $DEVICE_DIR ] ; then
	DEVICE_DIR=$(dirname $CUR_DIR)/device
fi

[ -z $_TARGET_PLATFORM ] && echo 'source build/envsetup.sh' && exit -1
[ -z $_TARGET_BOARD ] && echo 'source build/envsetup.sh' && exit -1

dev_out_dir=$OUT_DIR/$_TARGET_PLATFORM/$_TARGET_BOARD

# target rootfs
if [ ! $targetdir ] ; then
	targetdir=$dev_out_dir/debian/target
fi

if [ ! -d $targetdir ] ; then
	mkdir -p $targetdir
fi

finish() {
	mount | grep $targetdir/dev > /dev/null
	if [ $? -eq 0 ] ; then
		sudo umount $targetdir/dev
	fi
	exit -1
}
trap finish ERR

if [ ! -f $targetdir/tmp/.stamp_extracted ] ; then
	echo 'Extrace basic rootfs'
	sudo tar -xzpf stretch-alip.tar.gz -C $targetdir
	touch $targetdir/tmp/.stamp_extracted
else
	echo 'Skip extract basic rootfs'
fi

echo 'Copy modules'
sudo cp -rf ${dev_out_dir}/kernel/lib/modules $targetdir/lib

echo 'Copy overlay'
sudo cp -rf overlay/* $targetdir

if [ -d ${DEVICE_DIR}/${_TARGET_PLATFORM}/rootfs ] ; then
	sudo cp -rf ${DEVICE_DIR}/${_TARGET_PLATFORM}/rootfs/* $targetdir
fi

if [ -d ${DEVICE_DIR}/${_TARGET_PLATFORM}/boards/${_TARGET_BOARD}/rootfs ] ; then
	sudo cp -rf ${DEVICE_DIR}/${_TARGET_PLATFORM}/boards/${_TARGET_BOARD}/rootfs/* $targetdir
fi

echo 'Change root'
sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin
sudo mount -o bind /dev $targetdir/dev

cat <<EOF | sudo LC_ALL=C LANGUAGE=C LANG=C chroot $targetdir

export DEBIAN_FRONTEND=noninteractive

error()
{
	echo ""
	echo "Error occur"
	echo ""
	exit -1
}
trap error ERR

if [ ! -f /etc/systemd/system/multi-user.target.wants/depmod.service ] ; then
systemctl enable depmod.service
fi

apt-get update

if ! dpkg -s locales > /dev/null 2>&1 ; then
apt-get install -y locales
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/default/locale
dpkg-reconfigure -f noninteractive locales
update-locale LANG=en_US.UTF-8
fi

apt-get install -y insserv zlib1g libgoogle-glog0v5 libasound2
if insserv -s | grep mpp > /dev/null ; then
insserv /etc/init.d/mpp
fi

if insserv -s | grep bt > /dev/null ; then
insserv /etc/init.d/bt
fi

apt-get install -y bash-completion

apt-get install -y lxde-core gpicview leafpad lxterminal
apt-get --purge remove -y xscreensaver

apt-get install -y net-tools wicd wicd-curses wicd-gtk

if ! groups ai | grep netdev > /dev/null ; then
gpasswd -a ai netdev
fi

apt-get install -y openssh-server

apt-get install -y firefox-esr

apt-get install -y bluez pulseaudio-module-bluetooth bluetooth bluez-firmware

apt-get install -y python python-pip idle-python2.7 python-pyaudio python-opencv python-usb python-pyqt5 python-bluez 

apt-get install -y xfonts-intl-chinese xfonts-wqy

apt-get install -y alsa-utils lxmusic

if ! groups ai | grep audio > /dev/null ; then
gpasswd -a ai audio
fi

apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-alsa

touch /tmp/.stamp_installed

apt-get autoclean
apt-get clean
apt-get autoremove -y

EOF

sudo umount $targetdir/dev

if [ ! -f $targetdir/tmp/.stamp_installed ] ; then
	echo ""
	echo "Some unknown error occurred when installed packages"
	echo "Please re-run build script again"
	echo ""
	exit -1
fi
