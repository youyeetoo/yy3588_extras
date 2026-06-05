#!/bin/bash -e

# Ubuntu variant of debian/mk-base-debian.sh.
# Env: RELEASE={jammy,noble} ARCH={arm64,armhf} TARGET={desktop,base}

case "$RELEASE" in
	jammy|noble)
		;;
	"")
		RELEASE=jammy
		;;
	*)
		echo -e "\033[36m please input a supported Ubuntu suite: jammy, noble \033[0m"
		exit 1
		;;
esac

case "$ARCH" in
	armhf|arm64)
		;;
	"")
		ARCH=arm64
		;;
	*)
		echo -e "\033[36m please input arm64 or armhf for ARCH \033[0m"
		exit 1
		;;
esac

if [ ! "$TARGET" ]; then
	TARGET=desktop
fi

if [ -e linaro-$RELEASE-alip-*.tar.gz ]; then
	rm linaro-$RELEASE-alip-*.tar.gz
fi

cd ubuntu-build-service/$RELEASE-$TARGET-$ARCH

echo -e "\033[36m Starting Download...... \033[0m"

make clean
./configure
make

if [ -e linaro-$RELEASE-alip-*.tar.gz ]; then
	sudo chmod 0666 linaro-$RELEASE-alip-*.tar.gz
	mv linaro-$RELEASE-alip-*.tar.gz ../../
else
	echo -e "\e[31m Failed to run livebuild, please check your network connection. \e[0m"
	exit 1
fi
