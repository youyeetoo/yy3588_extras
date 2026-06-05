# YY3588 Ubuntu rootfs builder

This directory builds an Ubuntu LTS rootfs for Youyeetoo YY3588 boards. It mirrors the [Debian builder](../debian/) and shares its `packages/`, `overlay/`, `overlay-firmware/` and `overlay-debug/` directories via symlinks — the Rockchip userspace `.deb` packages (MPP, RGA, GStreamer integration, libmali, Chromium, …) are binary-compatible with Ubuntu 22.04 LTS.

These scripts are normally invoked indirectly by the top-level SDK builder:

```sh
# From sdk-bsp/
./compile.sh image ubuntu       # full bootable image with Ubuntu rootfs
./compile.sh ubuntu             # rootfs only
```

The instructions below cover direct invocation for development and debugging.

## Supported releases and architectures

| Release          | Codename            | Architectures    |
| ---------------- | ------------------- | ---------------- |
| Ubuntu 22.04 LTS | `jammy` *(default)* | `arm64`, `armhf` |
| Ubuntu 24.04 LTS | `noble`             | *experimental — no overlay script shipped yet* |

## Host requirements

These scripts run inside the SDK Docker image, which already provides every dependency. To run them directly on a host, install:

```sh
sudo apt-get install -y debootstrap qemu-user-static binfmt-support live-build sudo
```

The same `live-build 1:20230131` pin used for Debian `bookworm` is needed here — Ubuntu 22.04's stock `live-build` (3.0~a57) doesn't know `jammy` as a recognised suite via its parent-distribution machinery.

## Building (direct invocation)

### Base system

Build an Ubuntu base tarball via `live-build`:

```sh
RELEASE=jammy TARGET=desktop ARCH=arm64 ./mk-base-ubuntu.sh
```

The output is `linaro-jammy-alip-*.tar.gz` in this directory. The archive layout matches Linaro's Debian flow so the shared overlay step works without modification.

### Rockchip userspace overlay

Extract the base tarball and layer the Rockchip-specific packages:

```sh
ARCH=arm64 ./mk-rootfs-jammy.sh                # release build
VERSION=debug ARCH=arm64 ./mk-rootfs-jammy.sh  # debug build (adds glmark2)
```

The overlay script rewrites `/etc/apt/sources.list` to `http://ports.ubuntu.com/ubuntu-ports`, installs the Rockchip `.deb`s from `packages/`, holds the X.Org and pinned packages, configures `pipewire`, enables `zh_CN.UTF-8` and installs CJK fonts, then strips APT cache and `/var/cache`.

### Final image

Pack the rootfs into an `ext4` partition image:

```sh
./mk-image.sh    # produces linaro-rootfs.img
```

`mk-image.sh` is a symlink to the Debian builder's script — the two distributions produce interchangeable `linaro-rootfs.img` artifacts so the top-level SDK can treat them uniformly.

## Differences from the Debian flow

- Mirror: `ports.ubuntu.com/ubuntu-ports` instead of `deb.debian.org`.
- Distribution areas: `main restricted universe multiverse` (Ubuntu) instead of `main contrib non-free non-free-firmware` (Debian).
- `live-build` mode: `--mode ubuntu` instead of `--mode debian`.
- Package list customisation: Debian-only packages (`acpi-support-base`, `firmware-linux-free`, `initscripts`, `rcconf`, `debian-keyring`, `debian-faq`) are commented out — they don't exist in the Ubuntu archive.
- Default user: `ubuntu` instead of `linaro`.

Everything else — the Rockchip overlay packages, the firmware copy, the `systemd` mask list, the locale and font installation — is identical.

## Sibling builders

- [`../debian/`](../debian/) — Debian rootfs builder (bookworm, bullseye, buster).

## Common issues

See the [Debian builder README](../debian/readme.md#common-issues) — the failure modes are identical (debootstrap `Permission denied`, chroot left in inconsistent state, etc.). The fix `./compile.sh clean` works from the SDK root for both distributions.

## License

This directory derives from the [`rockchip-linux/rk-rootfs-build`](https://github.com/rockchip-linux/rk-rootfs-build) project. The Ubuntu packages installed at runtime are subject to [Canonical's Ubuntu licensing terms](https://ubuntu.com/legal/intellectual-property-policy).
