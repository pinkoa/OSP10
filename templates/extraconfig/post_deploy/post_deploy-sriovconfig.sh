#!/bin/bash

# Update multiple settings in /etc/neutron/plugins/ml2/ml2_conf.ini
function edit_neutron_ml2_conf_ini() {
  LOG="/root/edit_neutron_ml2_conf_ini.log"
  {
    FILE="/etc/neutron/plugins/ml2/ml2_conf.ini"
    cp -fva "${FILE}" "${FILE}.orig"
    # Update mechanism_drivers to include sriovnicswitch
    crudini --set --existing /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,bsn_ml2,sriovnicswitch
    # Update type_drivers to include vlan
    crudini --set --existing /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
    # Set tenant_network_type to vlan
    crudini --set --existing /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vlan
    # Modify flat_networks to allow for the creation of sriov_p1p1 and sriov_p3p1 networks
    crudini --set --existing /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks datacentre,sriov_p1p1,sriov_p3p1
    # Update vlan ranges to include above flat netorks and vlan id ranges
    crudini --set --existing /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges datacentre:3500:3749,datacentre:112:112,sriov_p1p1:3750:3999,sriov_p3p1:3750:3999
  } >>  "${LOG}"
}

# Update pci_vendor_devs in /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
function edit_neutron_ml2_conf_sriov_ini() {
  LOG="/root/edit_neutron_ml2_conf_sriov_ini.log"
  {
    FILE="/etc/neutron/plugins/ml2/ml2_conf_sriov.ini"
    cp -fva "${FILE}" "${FILE}.orig"    
    # Update supported_pci_vendor_devs with product_id of intel 10G nics
    crudini --set /etc/neutron/plugins/ml2/ml2_conf_sriov.ini ml2_sriov supported_pci_vendor_devs 8086:10ed
  } >>  "${LOG}"
}

# Add ml2_conf_sriov.ini as a config file for neutron-server service
function modify_neutron_server_service() {
  LOG="/root/modify_neutron_server_service.log"
  {
    FILE="/usr/lib/systemd/system/neutron-server.service"
    cp -fva "${FILE}" "${FILE}.orig"    
    # Modify neutron server service to add ml2_conf_sriov.ini as a config file    
    crudini --set --existing /usr/lib/systemd/system/neutron-server.service Service ExecStart "/usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_sriov.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log"
  } >>  "${LOG}"
}

# modify scheduler_default_filters and available_filters in nova.conf
function modify_nova_conf() {
  LOG="/root/modify_nova_conf.log"
  {
    FILE="/etc/nova/nova.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    # Modify scheduler_defualt_filters in nova.conf to add PciPassthrouchFilter
    crudini --set /etc/nova/nova.conf DEFAULT scheduler_default_filters "RetryFilter, AvailabilityZoneFilter, RamFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter, PciPassthroughFilter"
    # Modify scheduler_available_filters in nova.conf to add additional line for nova.scheduler.filters.pci_passthrough_filter.PciPassthroughFilter
    sed -i '/^scheduler_available_filters=nova.scheduler.filters.all_filters/a scheduler_available_filters=nova.scheduler.filters.pci_passthrough_filter.PciPassthroughFilter' /etc/nova/nova.conf
  }  >>  "${LOG}"
}

# configure nova_pci_whitelist
function edit_nova_pci_whitelist() {
  LOG="/root/edit_nova_pci_whitelist.log"
  {
    FILE="/etc/nova/nova.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    crudini --set /etc/nova/nova.conf DEFAULT pci_passthrough_whitelist "[{\"vendor_id\":\"8086\",\"product_id\":\"154d\"}][{\"devname\":\"p1p1\",\"physical_network\":\"sriov_p1p1\"},{\"devname\":\"p3p1\",\"physical_network\":\"sriov_p3p1\"}]"
  } >>  "${LOG}"
}

# install and configure sriov_nic_agent
#function install_sriov_nic_agent() {
#  LOG="/root/install_sriov_nic_agent.log"
#  {
#     FILE="/etc/neutron/plugins/ml2/ml2_conf_sriov.ini"
#     cp -fva "${FILE}" "${FILE}.orig"
#     #yum -y install openstack-neutron-sriov-nic-agent
#     rpm -ivh /root/openstack-neutron-sriov-nic-agent-7.1.1-7.el7ost.noarch.rpm
#     crudini --set /etc/neutron/plugins/ml2/ml2_conf_sriov.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
#     crudini --set /etc/neutron/plugins/ml2/ml2_conf_sriov.ini sriov_nic physical_device_mappings sriov_p1p1:p1p1,sriov_p3p1:p3p1
#      systemctl enable neutron-sriov-nic-agent.service
#      systemctl start neutron-sriov-nic-agent.service
#  } >>  "${LOG}"
#}

# Test to see if pacemaker is running, use the status to determine which functions to run.
pacemaker_status=$(systemctl is-active pacemaker || :)

if [ "$pacemaker_status" = "active" ]; then
   # pacemaker is active, this is a controller, perform the following functions
   edit_neutron_ml2_conf_ini
   edit_neutron_ml2_conf_sriov_ini
   modify_neutron_server_service
   modify_nova_conf

else
   # pacemaker is not running, this is a compute node,  perform the following functions
   edit_nova_pci_whitelist
 #  install_sriov_nic_agent

fi
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
