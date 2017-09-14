#!/bin/bash  
#  
#
#  IMPORTANT !!!  
#  
# THIS SCRIPT MUST BE MODIFIED IN SOME WAY PRIOR TO  
# ANY FUTURE DEPLOY OR UPDATE TO THE OVERCLOUD THAT IT  
# INTITIALLY CONFIGURED.  THIS IS DUE TO THE FACT THAT  
# DIRECTOR SAVES AN MD5SUM ON THIS SCRIPT BEFORE IT'S  
# INITIAL RUN.  IF THAT MD5SUM DOESN'T CHANGE, DIRECTOR  
# WILL NOT RUN THIS AGAIN UPON FUTURE UPDATES TO THE   
# OVERCLOUD  
#  
# ALSO, IN ORDER FOR DIRECTOR UPDATES MADE TO THE OVERCLOUD  
# AFTER THE INTIAL DEPLOY, YOU MUST HAVE INSTALLED  
# THE openstack-puppet-modules 7.1.1 OR HIGHER OR THE   
# UPDATE WILL FAIL  
#  
#  
# VARIABLES  
# Overcloud node naming convention  
# Change these to match your hostnames
#
export LDAP_SERVER=uswinlb.vzwcorp.com
export LDAP_PORT=389

  
# Active Directory Domain Name  
#export AD_DOMAIN=lab.lan  
  
# Closest AD Domain Controller  
#AD_DC=$(dig -t SRV _ldap._tcp.dc._msdcs.$AD_DOMAIN|grep -A1 ANSWER\ SECTION|tail -1|cut -d " " -f6|sed 's/.$//')  
  
# SCRIPT  
if [ "TRUE" != "__ENABLE__" ] ; then  
        exit 0  
fi  
  
# SSL & Keystone Settings  
# Uncomment the lines below for secure LDAP.
#openssl s_client -connect $AD_DOMAIN:636 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > /etc/pki/ca-trust/source/anchors/$AD_DC.pem  
#update-ca-trust extract  
#cp /etc/openldap/ldap.conf /etc/openldap/ldap.conf.orig  
#sed -i 's/cacerts/certs/g' /etc/openldap/ldap.conf  
setsebool -P authlogin_nsswitch_use_ldap=on  
sudo /usr/bin/crudini --set /etc/keystone/keystone.conf identity domain_specific_drivers_enabled true
sudo /usr/bin/crudini --set /etc/keystone/keystone.conf identity domain_config_dir /etc/keystone/domains
sudo /usr/bin/crudini --set /etc/keystone/keystone.conf assignment driver keystone.assignment.backends.sql.Assignment  

# Create Domains Directory and keystone config for domain  
mkdir -p /etc/keystone/domains/  
cat > /etc/keystone/domains/keystone.__DOMAIN__.conf << EOF  
[ldap]  
url = ldap://$LDAP_SERVER:$LDAP_PORT  
user = CN=SVC-coronalab,OU=SVC,OU=FNA,DC=uswin,DC=ad,DC=vzwcorp,DC=com  
password = bH88@wI88bH88@wI  
query_scope = sub  
suffix = DC=uswin,DC=ad,DC=vzwcorp,DC=com  
user_tree_dn = DC=uswin,DC=ad,DC=vzwcorp,DC=com  
user_filter = (memberOf=CN=vcp-cloud-access-nonprod,OU=Groups,DC=uswin,DC=ad,DC=vzwcorp,DC=com)
#user_objectclass = organizationalPerson  
user_objectclass = person
user_name_attribute = sAMAccountName  
user_id_attribute = sAMAccountName  
user_mail_attribute = mail  
user_pass_attribute =  
user_enabled_attribute = userAccountControl  
user_enabled_mask = 2  
user_enabled_default= 512  
user_attribute_ignore = password,tenant_id,tenants  
user_allow_create = False  
user_allow_update = False  
user_allow_delete = False  
#group_tree_dn=DC=lab,DC=lan  
#group_objectclass=group  
#group_id_attribute=cn  
#group_name_attribute=name  
#group_member_attribute=member  
  
[identity]  
driver=keystone.identity.backends.ldap.Identity  
  
[assignment]  
driver=keystone.assignment.backends.sql.Assignment  
  
use_tls = False  
#tls_cacertfile = /etc/ssl/certs/ca.crt  
EOF
  
# Ensure newly created files have proper ownership  
chown -R keystone:keystone /etc/keystone/domains/  
restorecon -Rv /etc/keystone/domains/  

# Modify Horizon configuration to enable domain support  
	cat >>/etc/openstack-dashboard/local_settings <<EOF  
OPENSTACK_API_VERSIONS = {  
    "identity": 3  
}  
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True  
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'  
EOF
  
# Configure cinder to use keystone v3  
cinder_auth_uri=$(sudo /usr/bin/crudini --get /etc/cinder/cinder.conf keystone_authtoken auth_uri)  
new_cinder_auth_uri=$(echo $cinder_auth_uri | sed -e 's/v2.0/v3/')  
sudo /usr/bin/crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri $new_cinder_auth_uri  
sudo /usr/bin/crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_version v3  
sudo /usr/bin/crudini --set /etc/nova/nova.conf keystone_authentication auth_version v3  
sudo /usr/bin/crudini --set /etc/nova/nova.conf keystone_authtoken auth_version v3  

# Restart Services  
#systemctl restart openstack-keystone  
#systemctl restart openstack-cinder-api  
#systemctl restart httpd  
#systemctl restart openstack-nova-api.service  
#systemctl restart openstack-nova-cert.service  
#systemctl restart openstack-nova-conductor.service  
#systemctl restart openstack-nova-consoleauth.service  
#systemctl restart openstack-nova-novncproxy.service  
#systemctl restart openstack-nova-scheduler.service  

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
