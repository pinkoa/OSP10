# Compute Node specific settings

#Cinder Config
cinder_auth_uri=$(sudo grep auth_uri /etc/puppet/hieradata/service_configs.yaml | awk '{print $2}')
new_cinder_auth_uri=$(echo $cinder_auth_uri | sed -e 's/v2.0/v3/')  
/usr/bin/crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri $new_cinder_auth_uri  
/usr/bin/crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_version v3  

#Nova Config
/usr/bin/crudini --set /etc/nova/nova.conf keystone_authtoken auth_version v3  

# Commented out for testing. May not be needed in OSP 10
#/usr/bin/crudini --set /etc/nova/nova.conf keystone_authentication auth_version v3  

# Restart Services  
systemctl restart openstack-nova-compute.service  
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
