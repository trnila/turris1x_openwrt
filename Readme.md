# Openwrt 18.06 on Turris 1.x
1) Update mac addresses in *./files/etc/init.d/set_mac*
2) Build sdcard image with:
```sh
  $ sudo ./build.sh
```
2) Copy it to your sdcard with: 
```sh
 $ sudo dd if=turris1x_openwrt.img of=/dev/mmcblk0 bs=4M status=progress oflag=sync
```

3) Insert sdcard to Turris under ram module

4) Connect usb cable to serial interface and open minicom
```sh
 $ minicom -D /dev/ttyUSB0 -b 115200
```

5) Enter Das U-Boot and add new boot entry, then make it default, save it and make a boot
```
 => setenv bootargs_sdcard root=/dev/mmcblk0p2 rootfstype=btrfs rootwait rw console=ttyS0,115200
 => setenv bootcmd_sdcard 'setenv bootargs $bootargs_sdcard; mmc rescan; fatload mmc 0:1 0x1000000 zImage; fatload mmc 0:1 0x02000000 fdt; max6370_wdt_off; bootm 0x01000000 - 0x02000000'
 => setenv bootcmd run bootcmd_sdcard
 => saveenv
 => bootd
```

6) Get network connection and make basic setup in /etc/config/{network,wireless}
ie:
```sh
 $ udhcpc -i eth2
```

7) Grow btrfs filesystem
```sh
 $ opkg update
 $ opkg install btrfs-progs fdisk cfdisk
```
Delete second partion of your sdcard and create it again with the remaining space with fdisk or cfdisk.
Then grow filesystem:
```sh
 $ btrfs filesystem resize max /
```



