#!/bin/bash
 set -x ;
 set -o functrace

# setup_grub
function setup_grub_sriov() {
  LOG="/root/setup_grub_sriov.log"
  {
    FILE="/etc/default/grub"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i 's/rhgb quiet/rhgb quiet intel_iommu=on/g' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
  } >> "${LOG}"
}

# edit rc.local
function edit_rc_local() {
  LOG="/root/edit_rc_local.log"
  {
    FILE="/etc/rc.d/rc.local"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "echo 32 > /sys/class/net/p1p1/device/sriov_numvfs" >> /etc/rc.d/rc.local
    echo "echo 32 > /sys/class/net/p3p1/device/sriov_numvfs" >> /etc/rc.d/rc.local
    restorecon -R -v /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local
  } >> "${LOG}"
}

setup_grub_sriov
edit_rc_local
