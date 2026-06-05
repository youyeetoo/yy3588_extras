# YY3588 Debian rootfs builder

This directory builds a Debian-based rootfs for Youyeetoo YY3588 boards. The flow uses Linaro's `live-build` recipe to produce a base Debian image, then layers Rockchip's hardware-accelerated userspace stack (MPP, RGA, GStreamer integration, Wayland/X11, Chromium, Bluetooth, Wi-Fi firmware, fonts, locales) on top inside an `arm64` chroot.

These scripts are normally invoked indirectly by the top-level SDK builder:

```sh
# From sdk-bsp/
./compile.sh image debian       # full bootable image with Debian rootfs
./compile.sh debian             # rootfs only
```

The instructions below cover direct invocation for development and debugging.

## Supported releases and architectures

| Release   | Codename                | Architectures    |
| --------- | ----------------------- | ---------------- |
| Debian 10 | `buster`                | `arm64`, `armhf` |
| Debian 11 | `bullseye`              | `arm64`, `armhf` |
| Debian 12 | `bookworm` *(default)*  | `arm64`, `armhf` |

## Host requirements

These scripts run inside the SDK Docker image, which already provides every dependency. To run them directly on a host, install:

```sh
sudo apt-get install -y debootstrap qemu-user-static binfmt-support live-build sudo
```

`live-build` from Debian Bookworm or Trixie is required for `bookworm` support; older versions only know up to `bullseye`. The SDK Dockerfile pins `live-build` `1:20230131` from the Debian salsa repository for this reason.

## Building (direct invocation)

### Base system

Build a Debian base tarball via `live-build` from Linaro's recipe:

```sh
# arm64 desktop (default)
RELEASE=bookworm TARGET=desktop ARCH=arm64 ./mk-base-debian.sh

# armhf base
RELEASE=bookworm TARGET=base ARCH=armhf ./mk-base-debian.sh
```

The output is `linaro-<release>-alip-*.tar.gz` in this directory.

### Rockchip userspace overlay

Extract the base tarball and layer the Rockchip-specific packages:

```sh
RELEASE=bookworm ARCH=arm64 ./mk-rootfs.sh           # release build
VERSION=debug ARCH=arm64 ./mk-rootfs-bookworm.sh     # debug build
```

### Final image

Pack the rootfs into an `ext4` partition image:

```sh
./mk-image.sh    # produces linaro-rootfs.img
```

## Sibling builders

- [`../ubuntu/`](../ubuntu/) — Ubuntu LTS rootfs builder using the same overlay packages.

## Common issues

**`Permission denied` during debootstrap**: the working directory is mounted `noexec` or `nodev`. Remount with execute and device permissions and retry:

```sh
sudo mount -o remount,exec,dev <mountpoint>
```

**`Cannot install into target`**: the chroot was left in an inconsistent state by a previous interrupted run. Clean up with:

```sh
sudo rm -rf binary ubuntu-build-service/*/chroot
```

Or, from the SDK root, use `./compile.sh clean`.

## License

This directory derives from the [`rockchip-linux/rk-rootfs-build`](https://github.com/rockchip-linux/rk-rootfs-build) project. The Debian packages installed at runtime are subject to [Debian's licensing terms](https://www.debian.org/legal/licenses/).
