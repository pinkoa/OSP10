#!/bin/bash
#
# description:
    # run commands on all controller nodes using heat post deployment to backport dell cinder driver patches
#
# post_deploy script
#
# Verizon
# Jay Cromer
#
# Borrowed from:
#
# Redhat
# Jason Woods   jwoods@redhat.com
# 2016-05-17

# backup config file before making changes to it
function backup_file() {
  bkup_orig="${1}.$(date +"%F_%T.%N")"
  if [ -n "${1}" ] ; then
    # if arg1 sent to function, use that as file to backup
    bkup_file="${1}"
  else
    # if arg1 is null default to using FILE variable
    bkup_file="${FILE}"
  fi
  if [ -e "${bkup_file}" ] ; then
    cp -fva "${bkup_file}" "${bkup_orig}"
  else
    touch "${bkup_file}" "${bkup_orig}"
  fi
}

# post_heat_dell_patches_cinder_conf
function post_heat_dell_patches_cinder_conf() {
  LOG="/root/post_heat_dell_patches_cinder_conf.log"
  {

    # run commands on all controller nodes using heat post deployment to backport dell cinder driver patches
    FILE_CHK="/etc/neutron/dnsmasq-neutron.conf"
    if [ -e "${FILE_CHK}" ] ; then
    FILE="/etc/cinder/cinder.conf"
    backup_file "${FILE}"
      #crudini --set "${FILE}" tripleo_dellsc excluded_domain_ip 172.20.25.15
      #crudini --set "${FILE}" tripleo_dellsc excluded_domain_ip 172.20.33.15
#These setting fixes bug related to discovery when multiple fault domains are configured (https://bugs.launchpad.net/cinder/+bug/1616499) and is supposed to be fixed in Openstack Newton release.
      grep -qs "excluded_domain_ip=172.20.25.15" "${FILE}"
      if [[ $? != 0 ]]; then
	echo "excluded_domain_ip=172.20.25.15" >> "${FILE}";
      fi
      grep -qs "excluded_domain_ip=172.20.33.15" "${FILE}"
      if [[ $? != 0 ]]; then
	echo "excluded_domain_ip=172.20.33.15" >> "${FILE}";
      fi
      crudini --set "${FILE}" tripleo_dellsc secondary_san_ip 10.75.15.125
      crudini --set "${FILE}" tripleo_dellsc secondary_san_password Dellsvcs1
      crudini --set "${FILE}" tripleo_dellsc secondary_san_login Admin
      crudini --set "${FILE}" tripleo_dellsc secondary_sc_api_port 3033
    else
      echo "## Found not file: \"${FILE_CHK}\""
      echo "## System appears to be a compute"
    fi
  } >> "${LOG}"
}

# functions to execute below
# comment out as needed
post_heat_dell_patches_cinder_conf
#2017-02-13_15H-21M
#2017-02-13_15H-23M
#2017-02-13_15H-57M
#2017-02-13_17H-04M
#2017-02-13_17H-11M
#2017-02-13_17H-12M
#2017-02-13_17H-32M
#2017-02-13_18H-44M
#2017-02-13_18H-46M
#2017-02-13_18H-47M
#2017-02-13_18H-55M
#2017-02-13_19H-15M
#2017-02-13_19H-37M
#2017-02-13_19H-39M
#2017-02-13_19H-40M
#2017-02-13_21H-23M
#2017-02-13_22H-10M
#2017-02-13_22H-24M
#2017-02-13_22H-33M
#2017-02-13_22H-57M
#2017-02-13_23H-06M
#2017-02-13_23H-27M
#2017-02-13_23H-43M
#2017-02-14_10H-16M
#2017-02-14_10H-18M
#2017-02-14_11H-53M
#2017-02-14_18H-20M
#2017-02-14_18H-24M
#2017-02-14_19H-56M
#2017-02-14_22H-52M
#2017-02-15_09H-11M
#2017-02-15_09H-36M
#2017-02-15_09H-44M
#2017-02-15_11H-27M
#2017-02-15_14H-28M
#2017-02-15_15H-54M
#2017-02-16_10H-27M
#2017-02-16_11H-30M
#2017-02-16_12H-35M
#2017-02-16_12H-48M
#2017-02-16_13H-36M
#2017-02-16_14H-34M
#2017-02-16_15H-38M
#2017-02-16_15H-40M
#2017-02-16_15H-43M
#2017-02-16_16H-54M
#2017-02-16_23H-22M
#2017-02-16_23H-24M
#2017-02-17_09H-12M
#2017-02-17_15H-23M
#2017-02-17_17H-14M
#2017-02-20_10H-19M
#2017-02-20_11H-48M
#2017-02-20_12H-56M
#2017-02-21_15H-01M
#2017-02-21_15H-05M
#2017-02-22_09H-48M
#2017-02-22_09H-53M
