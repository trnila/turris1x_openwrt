#!/bin/sh
set -ex

TURRIS_ROOTFS_URL=https://api.turris.cz/openwrt-repo/turris/openwrt-mpc85xx-p2020-nand-TURRISNAND-rootfs.tar.gz
OPENWRT_IMAGE_BUILDER_URL=https://downloads.openwrt.org/releases/18.06.1/targets/mpc85xx/generic/openwrt-imagebuilder-18.06.1-mpc85xx-generic.Linux-x86_64.tar.xz

DST_IMAGE=turris1x_openwrt.img

mkdir -p tmp

# download turris kernel + modules in their rootfs
if [ ! -f "tmp/turris-rootfs.tar.gz" ]; then
  wget "$TURRIS_ROOTFS_URL" -O tmp/turris-rootfs.tar.gz --no-check-certificate
  mkdir tmp/turris-rootfs
  (cd tmp/turris-rootfs && tar -xf ../turris-rootfs.tar.gz)
fi

# prepare openwrt rootfs
if [ ! -f "tmp/imagebuilder.tar.xz" ]; then
  wget "$OPENWRT_IMAGE_BUILDER_URL" -O tmp/imagebuilder.tar.xz 
  (cd tmp && tar -xf imagebuilder.tar.xz && mv openwrt-imagebuilder-* imagebuilder)
fi

make -C tmp/imagebuilder image FILES=$PWD/files/
rootfs="tmp/imagebuilder/build_dir/target-powerpc_8540_musl/root-mpc85xx/"


# prepare sdcard image
rm -f "$DST_IMAGE"
truncate -s 256M "$DST_IMAGE"
(
  echo o # create dos partion table
  echo -e "n\np\n1\n\n+64M" # add primary partion 1
  echo -e "n\np\n2\n\n\n"   # add primary partion 2 with rest of space
  echo w # save table
) | fdisk "$DST_IMAGE"

dev=$(losetup --partscan --show --find "$DST_IMAGE")
trap "umount tmp/mnt/boot; umount tmp/mnt/rootfs; losetup -d $dev;" EXIT
mkfs.fat "$dev"p1
mkfs.btrfs "$dev"p2

mkdir -p tmp/mnt/{boot,rootfs}
mount "$dev"p1 tmp/mnt/boot
mount "$dev"p2 tmp/mnt/rootfs


# copy rootfs
cp -a "$rootfs/." tmp/mnt/rootfs/
rm -rf tmp/mnt/rootfs/lib/modules

# copy kernel and fdt to fat32
cp -L tmp/turris-rootfs/boot/{zImage,fdt} tmp/mnt/boot

# copy kernel modules
cp -a tmp/turris-rootfs/lib/modules tmp/mnt/rootfs/lib/

echo "SDcard built."
