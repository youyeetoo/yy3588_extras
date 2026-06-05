# yy3588_extras

Board-specific assets for the Youyeetoo YY3588 SDK: rootfs builders, prebuilt Rockchip userspace packages, vendor scripts, and reference documentation. This repository is consumed by [`yy3588_sdk-bsp`](https://github.com/youyeetoo/yy3588_sdk-bsp) — there is no standalone build flow here.

## Contents

| Directory     | Purpose                                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `debian/`     | Debian rootfs builder (bookworm / bullseye / buster) — see [`debian/readme.md`](debian/readme.md)                        |
| `ubuntu/`     | Ubuntu LTS rootfs builder (jammy) — see [`ubuntu/readme.md`](ubuntu/readme.md)                                           |
| `prebuilts/`  | Pre-compiled vendor binaries the build flow consumes verbatim (signing keys, ramdisk templates, …)                       |
| `external/`   | Userspace components merged into the SDK build tree at build time (RGA, GStreamer-Rockchip integration, recovery glue, …) |
| `app/`        | Reference applications shipped by Rockchip / Youyeetoo for the platform                                                  |
| `tools/`      | Vendor host tools used by the build (image packers, signing helpers, …)                                                  |
| `docs/`       | Rockchip-distributed documentation (mirrored verbatim from the upstream BSP release)                                     |

## Usage

The intended entry point is `yy3588_sdk-bsp/compile.sh`, which stitches this repository into the build tree alongside `yy3588_linux`, `yy3588_u-boot`, `yy3588_rkbin` and `yy3588_buildroot`. Most users should never invoke the scripts in this repository directly.

For development on the rootfs builders themselves, the per-directory READMEs describe direct invocation.

## License

Contents inherit their upstream licenses:

- `debian/`, `ubuntu/` — derive from [`rockchip-linux/rk-rootfs-build`](https://github.com/rockchip-linux/rk-rootfs-build); package selection and overlay materials are Rockchip / Youyeetoo additions distributed under the SDK terms.
- `prebuilts/`, `external/` — vendor binaries and userspace components; each subdirectory's `LICENSE` or `COPYING` file is authoritative.
- `docs/` — copyright Rockchip Electronics Co., Ltd., redistributed under the SDK terms.

### Vendor blob provenance

`external/` mirrors components that Rockchip publishes through its public mirrors. Authoritative upstream sources:

| Component | Upstream mirror |
| --- | --- |
| `rockit`, `iva`/rockiva, `rk_tee_user`, `rkaiq`, `rockchip-test`, `rktoolkit`, `rkupdate`, `rkwifibt`, `rkscript`, `rk_pcba_test`, `common_algorithm`, `minilogger`, `alsa-config`, `uvc_app`, `uac_app`, `ipcweb-backend`, `rkfsmk` | [`github.com/Caesar-github`](https://github.com/Caesar-github) (Rockchip developer mirror) |
| `rknn-toolkit2`, `rknpu2`, `mpp`, `kernel`, `u-boot`, `rkbin` | [`github.com/rockchip-linux`](https://github.com/rockchip-linux) (Rockchip official) |
| `libmali`, `drm-cursor`, `meta-rockchip` | [`github.com/JeffyCN/mirrors`](https://github.com/JeffyCN/mirrors) (Jeffy Chen / Rockchip) |

`external/libmali/` is licensed under the **ARM Mali userspace driver EULA** (see `external/libmali/END_USER_LICENCE_AGREEMENT.txt`). Redistribution is permitted per clause 1.1(ii) provided the EULA is shipped alongside, all copyright notices are preserved, and ARM trademarks are not used for marketing.
