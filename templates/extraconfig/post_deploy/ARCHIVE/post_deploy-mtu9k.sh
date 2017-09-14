#!/bin/bash
#
# description:
# post_deploy script
# mtu 9000 setup for tenants
#
# created using Ben Schmaus instructions in:
# https://c.na7.visual.force.com/apex/Case_View?id=500A000000TRJ0H
#
# Red Hat
# Jason Woods	jwoods@redhat.com
# 2016-05-25

# unalias command aliases that could cause trouble
unalias mv cp rm

# MTU size to use for tenants (allow some from max for vlan use)
MTU="8950"

# setup_nova
function setup_nova() {
  LOG="/root/postdeploy_setup_nova.log"
  {
    # increase the MTU on nova
    FILE="/etc/nova/nova.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i "/^network_device_mtu=.*/d;" "${FILE}"
    echo "network_device_mtu=${MTU}" >> "${FILE}"
    echo "## updated nova MTU: \"${FILE}\""
    diff "${FILE}.orig" "${FILE}"
  } >> "${LOG}"
}

# setup_neutron
function setup_neutron() {
  LOG="/root/postdeploy_setup_neutron.log"
  {
    # increase the MTU on neutron
    FILE="/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i "/veth_mtu = ${MTU}/d;" "${FILE}"
    echo "veth_mtu = ${MTU}" >> "${FILE}"
    echo "## updated neutron openvswitch MTU: \"${FILE}\""
    diff "${FILE}.orig" "${FILE}"
    # increase the MTU on anything that boots up in our cloud, on the controllers only
    FILE="/etc/neutron/dnsmasq-neutron.conf"
    if [ -e "${FILE}" ] ; then
      cp -fva "${FILE}" "${FILE}.orig"
      sed -i "/^dhcp-option-force=26,.*/d;" "${FILE}"
      echo "dhcp-option-force=26,${MTU}" >> "${FILE}"
      echo "## updated neutron dnsmasq MTU: \"${FILE}\""
      diff "${FILE}.orig" "${FILE}"
      # restart neutron dhcp ater change to config file
      systemctl restart neutron-dhcp-agent
    else
      echo "## Not found file: \"${FILE}\""
      echo "## System appears to not be a controller"
    fi
  } >> "${LOG}"
}

# restart_openstack
function restart_neutron() {
  LOG="/root/postdeploy_restart_openstack.log"
  {
    echo "## stopping openstack services"
    openstack-service stop
    sleep 2
    echo "## starting openstack services"
    openstack-service start
  } >> "${LOG}"
}

# functions below for post_deploy
setup_nova
setup_neutron
restart_openstack

