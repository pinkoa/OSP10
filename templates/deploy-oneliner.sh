#to update script contents, otherwise scripts will not get run on subsequent deploys
for i in $(ls ~/templates/extraconfig/post_deploy/*.sh); do echo "#"$(date +%Y-%m-%d_%HH-%MM) >> $i; done

#including only all-nodes and post compute and also post controller
time openstack overcloud deploy --templates /usr/share/openstack-tripleo-heat-templates -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/inject-trust-anchor.yaml -e /home/stack/templates/enable-tls.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-ip.yaml -e /home/stack/templates/firstboot.yaml -e /home/stack/templates/controller_pre_config_env.yaml -e /home/stack/templates/storage-environment.yaml -e /home/stack/templates/cinder-dellsc-config.yaml -e /home/stack/templates/node_extra_config_post_allnodes.yaml -e /home/stack/templates/node_extra_config_post_compute.yaml -e /home/stack/templates/node_extra_config_post_controller.yaml --control-scale 3 --compute-scale 1 --ceph-storage-scale 0 --control-flavor control --compute-flavor compute --ntp-server 96.239.250.57 --neutron-disable-tunneling --neutron-network-type vlan --neutron-network-vlan-ranges 'datacentre:xxxx:xxxx,datacentre:xxx:xxx'  --libvirt-type kvm
