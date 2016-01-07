# Init.bsd
Init.bsd provides BSD style boot scripts for Linux systems. It offers a fast, robust and simple way to boot your system, the boot process from bootloader to login prompt is often reduced to just a few seconds.

### Introduction
This GPL2 licensed boot system provides a fast, elegant and predictable way to boot a Linux system. Booting a system with Init.bsd is generally a lot faster compared to sysv init or systemd. Features include:
* Support for recent versions of (e)udev, static device nodes, saving/restoring a random seed and the creation of virtual filesystems
* Will work with or without an initramfs file 
* Full disk encryption support using dm-crypt
* /etc/crypttab support

### Installation
Installation is straightforward and simple. Download the latest release tarball and extract it. Depending on your current situation, backup you current /etc/rc.d directory, /etc/inittab and uninstall any present sysv init scripts, upstart or systemd programs.

    # install -vm644 etc/inittab /etc 
    # mv -v rc.d /etc
    # chown -Rv 0:0 /etc/rc.d

After installation, optionally generate an initramfs file or simply reboot to start using the new boot system.

### Initramfs
Note: if your distribution provides an initramfs file, like most Linux distributions do, this chapter can be skipped.

If your distro does not provide an [initramfs](https://en.wikipedia.org/wiki/Initramfs) you can create one using the scripts in the bin/ directory. The use of an initramfs is often optional but it is required when using full disk encryption. To use it, install the two initramfs generation scripts. The scripts support both unencrytped and fully encrypted root filesystems.

    install -vm0755 bin/mkinitramfs* /usr/bin

Next, generate the initramfs file:

    # mkinitramfs
Output will depend on your kernel version and be something like:

    Creating /boot/initramfs-4.1.10.cpio.gz...27351 blocks
    Done.

Copy the generated initramfs to your local boot partition and setup your bootloader. You can name the generated initramfs anything you like. For syslinux the boot entry for an encrypted filesystem with initramfs will be something like:

    LABEL Linux
      MENU LABEL Linux BSD Init
      LINUX ../vmlinuz
      APPEND root=/dev/mapper/cryptroot cryptdevice=/dev/sdb1:cryptroot ro quiet
      INITRD ../initramfs-4.1.10.cpio.gz

The initramfs file can be fairly large. Depending on your kernel config, you might want to limit the amount of kernel modules included in the image. To do this alter lines 61-65 in mkinitramfs to exclude certain modules from the initramfs file that are not needed to boot.

### Checkboot
Users with full disk encryption probably have an unencrypted boot partition. This can be combined with something like TPM or a script to check the unencrypted part of the disk for tampering. The file bin/checkboot.0.11.sh is a small script that detects /boot tampering and can be started at boot by installing it as /usr/bin/checkboot and adding it to rc.local. The script will create a warning file in case the unencrypted boot partition is different from the last boot. This can be a kernel update, a change in the bootloader files or something else that needs investigating.

### Autologin
With a system using full disk encryption it might be desirable to automatically login to a console after boot so you only have to enter one password after booting. To do this modify the line in /etc/inittab that reads:

    c1:2345:respawn:/sbin/agetty --noclear tty1 38400 linux

Change it to (replace *willie* with your username):

    c1:2345:respawn:/sbin/agetty --noclear -a willie tty1 38400 linux

After boot you will automatically login as the user *willie* on the first tty.

### Comparison to sysv init
Compared to traditional sysv init scripts, using Init.bsd feels similar but will probably be faster. Init.bsd provides a less modular and simpler setup. Failed boot processes are visible on the console from the error message instead of a *fail* state on the boot step. For example, during a boot with sysv init scripts you may encounter something like:

    [FAIL] Starting ALSA

The Init.bsd scripts will in this case report the acutal alsa error message:

    alsactl: load_state:1683: Cannot open /var/lib/alsa/asound.state for reading: No such file or directory

### Comparison to systemd
The Init.bsd scripts are a lot simpler compared to systemd. Systemd offers lots of features besides a boot manager, for example it has a service manager and logging capabilities. Init.bsd is built around the traditional Unix way of partitioning functionality into small semi-independent parts each doing a single job. It leaves the other tasks to the better suited programs which are especially build for this like the syslog daemon to log kernel messages or acpid to handle hibernate. It also avoids function creep and dependency on tools like D-Bus, PAM or PolicyKit.

### Copyright
The Init.bsd scripts are open source and provided under the GPL2 license. Parts of these scripts are based on the LFS bootscripts and the bsd-init hint from the [LFS project](http://www.linuxfromscratch.org). 

