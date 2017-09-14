#!/bin/bash
#
# description:
# update overcloud systems to comply with openscap
# not that pretty, but functional
#
# disk_config script
#
# created using requirements given by Rob Fisher @Verizon
#
# Red Hat
# Jason Woods	jwoods@redhat.com
# 2016-05-17

# unalias command aliases that could cause trouble
unalias mv cp rm

# directories that will be moved to their own filesystems
MOUNT_DIRS="home tmp var"

# lvm_config:
#  This will be used to add the following partitions:
#  /home 5G
#  /tmp 5G
#  / 50G
#  swap 4G
#  /var 50% of whatever is left
function lvm_config() {
  LOG="/root/firstboot_LVM.log"
  {
    if [ -b "/dev/sdb" ] ; then
      DEVICE=sdb
    elif [ -b "/dev/vdb" ] ; then
      DEVICE=vdb
    else
      echo "ERROR: unknown disk device"
      exit
    fi
    echo "## using device \"${DEVICE}\""
    echo "# pre-change /partitions"
    cat /proc/partitions
    for v_partition in $(parted -s "/dev/${DEVICE}" print|awk '/^ / {print $1}')
    do
      parted -s "/dev/${DEVICE}" rm ${v_partition}
    done
    echo "# post change /partitions"
    cat /proc/partitions
    pvcreate -f "/dev/${DEVICE}"
    pvs
    vgcreate /dev/vgroot "/dev/${DEVICE}"
    vgs
    lvcreate -L 5g -n lvhome vgroot
    lvcreate -L 5g -n lvtmp vgroot
    lvcreate -L 4g -n lvswap vgroot
    lvcreate -l 50%FREE -n lvvar vgroot
    lvs
    mkfs.ext4 /dev/vgroot/lvhome -L lvhome
    mkfs.ext4 /dev/vgroot/lvtmp -L lvtmp
    mkfs.ext4 /dev/vgroot/lvvar -L lvvar
    mkswap /dev/vgroot/lvswap -L lvswap
  } >> "${LOG}"
}

# mount_move:
# copy files from original directories to new filesytems in temp mount points
function mount_move() {
  LOG="/root/firstboot_copy.log"
  {
    df -h 
    for DIR in ${MOUNT_DIRS}
    do
      mkdir -v "/b${DIR}"
      mount -v "/dev/vgroot/lv${DIR}" "/b${DIR}"
    done
#    mkdir -v /bhome 
#    mkdir -v /btmp 
#    mkdir -v /bvar 
#    mount -v /dev/vgroot/lvhome /bhome 
#    mount -v /dev/vgroot/lvtmp /btmp 
#    mount -v /dev/vgroot/lvvar /bvar 
    df -h 
    # ALT way to do this and to make sure we grab any .files or .dirs:
    #   # find all entries in DIR that are a single depth (exist in the DIR, but nothing beyond)
    #   # then cp -ar those files/dirs to new /bDIR location
    #   # this is less efficient than using cp -ar on the directory/*, but will catch exceptions
    #   # in this case, the only likely entries with .file or .dir would be /tmp
    # for DIR in ${MOUNT_DIRS}
    # do
    #   find /${DIR} -maxdepth 1 -mindepth 1 -exec echo cp -ar '{}' /b${DIR} ';'
    # done
    #cp -ra /var/* /bvar
    #cp -ra /home/* /bhome
    #cp -ra /tmp/* /btmp
    for DIR in ${MOUNT_DIRS}
    do
      if mountpoint "/b${DIR}" ; then
        cd "/${DIR}"
        find . -depth | cpio -pmdv "/b${DIR}"
      else
        echo "WARNING: \"/b${DIR}\" is not a mountpoint"
      fi
    done
    df -h
  } >> "${LOG}"
}

# fstab_set
# configure fstab with new filesystems
function fstab_set() {
  LOG="/root/firstboot_fstab.log"
  {
    FILE="/etc/fstab"
    cp -fva "${FILE}" "${FILE}.orig"
    # add new swap
    # new /home needs nodev
    # new /tmp needs nodev, nosuid, noexec
    # new /var uses defaults
    # bind /var/tmp to /tmp
    cat << EOF >> "${FILE}"
/dev/vgroot/lvswap   swap        swap    defaults    0 0
/dev/vgroot/lvhome   /home       ext4    nodev       0 0
/dev/vgroot/lvtmp    /tmp        ext4    nodev,nosuid,noexec    0 0
/dev/vgroot/lvvar    /var        ext4    defaults    0 0
/tmp                 /var/tmp    none    bind        0 0
EOF
    cat "${FILE}" 
  } >> "${LOG}"
}

# mount_remount:
function mount_remount() {
  LOG="/root/firstboot_remount.log"
  {
    for DIR in ${MOUNT_DIRS}
    do
      umount "/b${DIR}"
      mv "/${DIR}" "/${DIR}.orig"
      mkdir "/${DIR}"
      mount "/${DIR}"
      restorecon -vr "/${DIR}"
    done
    df -h
  } >> "${LOG}"
}

# selinux_reset
# request selinux relabel on next boot
function selinux_reset() {
  LOG="/root/firstboot_selinux.log"
  {
    touch /.autorelabel 
    ls -l /.autorelabel 
  } >> "${LOG}"
}

# setup_kernel
function setup_kernel() {
  LOG="/root/firstboot_setup_kernel.log"
  {
    FILE="/etc/security/limits.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "*	hard	core	0" >> "${FILE}"
    FILE="/etc/sysctl.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "fs.suid_dumpable = 0" >> "${FILE}"
    #echo "net.ipv4.conf.default.rp_filter = 2" >> "${FILE}"
    #echo "net.ipv4.conf.all.rp_filter = 2"  >> "${FILE}"
    FILE="/etc/sysconfig/init"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "umask 027" >> "${FILE}"
  } >> "${LOG}"
}

# setup_grub
function setup_grub() {
  LOG="/root/firstboot_setup_grub.log"
  {
    FILE="/etc/default/grub"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "audit=1" >> "${FILE}"
    grub2-mkconfig -o /boot/grub2/grub.cfg
  } >> "${LOG}"
}

# reboot_svr
# reboot the server after changes are complete
#function reboot_svr() {
#  LOG="/root/firstboot_reboot.log"
#  {
#    echo "Shutting down for clean reboot"
#    shutdown -r 0  >> /root/firstboot_reboot.log
#  } >> "${LOG}"
#}

# functions below for disk_config
lvm_config
mount_move
fstab_set
mount_remount
selinux_reset
setup_kernel
setup_grub
#reboot_svr
