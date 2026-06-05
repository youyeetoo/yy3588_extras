#!/bin/bash -e

# Ubuntu 22.04 (jammy) variant of mk-rootfs-bookworm.sh.

TARGET_ROOTFS_DIR="binary"

case "${ARCH:-$1}" in
	arm|arm32|armhf)
		ARCH=armhf
		;;
	*)
		ARCH=arm64
		;;
esac

echo -e "\033[36m Building for $ARCH \033[0m"

if [ ! $VERSION ]; then
	VERSION="release"
fi

echo -e "\033[36m Building for $VERSION \033[0m"

if [ ! -e linaro-jammy-alip-*.tar.gz ]; then
	echo "\033[36m Run mk-base-ubuntu.sh first \033[0m"
	exit -1
fi

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf linaro-jammy-alip-*.tar.gz

# packages/ is symlinked to debian/ — same .deb work on Ubuntu 22.04.
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rpf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

if [ "$VERSION" == "debug" ]; then
	sudo cp -rpf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

echo -e "\033[36m Change root.....................\033[0m"

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

if [ "$ID" -ne 0 ]; then
       find / -user $ID -exec chown -h 0:0 {} \;
fi
for u in \$(ls /home/); do
	chown -h -R \$u:\$u /home/\$u
done

echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 127.0.0.53" >> /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

cat > /etc/apt/sources.list << 'SRC'
deb http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse
SRC

apt-get update
apt-get upgrade -y

export APT_INSTALL="apt-get install -fy --allow-downgrades"

sed -i "s~\(^ExecStart=.*\)~# \1\nExecStart=-/bin/sh -c '/bin/bash -l </dev/%I >/dev/%I 2>\&1'~" /usr/lib/systemd/system/serial-getty@.service

\${APT_INSTALL} pm-utils triggerhappy bsdmainutils
cp /etc/Powermanager/triggerhappy.service /lib/systemd/system/triggerhappy.service
sed -i "s/#HandlePowerKey=.*/HandlePowerKey=ignore/" /etc/systemd/logind.conf

\${APT_INSTALL} /packages/rga2/*.deb
\${APT_INSTALL} gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-plugins-base-apps
\${APT_INSTALL} /packages/mpp/*
\${APT_INSTALL} /packages/gst-rkmpp/*.deb
\${APT_INSTALL} /packages/gstreamer/*.deb
\${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb
\${APT_INSTALL} cheese v4l-utils
\${APT_INSTALL} /packages/libv4l/*.deb
\${APT_INSTALL} /packages/cheese/*.deb
\${APT_INSTALL} /packages/xserver/*.deb
apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy
\${APT_INSTALL} /packages/weston/*.deb
\${APT_INSTALL} /packages/wayland/*.deb
\${APT_INSTALL} /packages/chromium/*.deb
\${APT_INSTALL} /packages/libdrm/*.deb
\${APT_INSTALL} /packages/libdrm-cursor/*.deb

\${APT_INSTALL} blueman
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
\${APT_INSTALL} blueman
rm -f /usr/sbin/policy-rc.d
\${APT_INSTALL} /packages/blueman/*.deb
\${APT_INSTALL} /packages/rkwifibt/*.deb
mkdir -p /vendor/etc
ln -sf /system/etc/firmware /vendor/etc/ 2>/dev/null || true

if [ "$VERSION" == "debug" ]; then
\${APT_INSTALL} /packages/glmark2/*.deb
fi

if [ -e "/usr/lib/aarch64-linux-gnu" ]; then
mv /packages/rknpu2/rknpu2.tar  /
fi

\${APT_INSTALL} /packages/rktoolkit/*.deb

sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
echo "LANG=zh_CN.UTF-8" >> /etc/default/locale
locale-gen
\${APT_INSTALL} fonts-wqy-zenhei fonts-aenigma xfonts-intl-chinese

\${APT_INSTALL} pipewire pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
\${APT_INSTALL} /packages/pipewire/*.deb || true
\${APT_INSTALL} /packages/wireplumber/*.deb || true
find /usr/lib/systemd/ -name "wireplumber*.service" 2>/dev/null | xargs -r sed -i "/Environment/s/$/ DISPLAY=:0/"

cp /packages/libmali/libmali-*-x11*.deb / 2>/dev/null || true
cp -rf /packages/rkisp/*.deb / 2>/dev/null || true
cp -rf /packages/rkaiq/*.deb / 2>/dev/null || true
cp -rf /usr/lib/firmware/rockchip/ / 2>/dev/null || true

rm -rf /usr/lib/firmware
mkdir -p /usr/lib/firmware/
mv /rockchip /usr/lib/firmware/ 2>/dev/null || true

apt list --installed 2>/dev/null | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm -f /lib/systemd/system/wpa_supplicant@.service

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/

EOF
