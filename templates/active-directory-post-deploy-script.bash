#!/bin/bash
#
# Note you will need to adjust your paths for your environment as you might 
# have overcloudrc and stackrc in /home/stack or /home/stack/templates

set -x

#Create Keystone API version 3 overcloudrc file
cp overcloudrc overcloudrc_v3  
sed -i 's/v2.0/v3\//g' overcloudrc_v3  

#commented out as was not working and had to run manually -cpaquin
cat <<'EOF' >> /home/stack/templates/overcloudrc_v3   
export OS_IDENTITY_API_VERSION=3  
export OS_PROJECT_DOMAIN_NAME=Default  
export OS_USER_DOMAIN_NAME=Default  
EOF
  
# Create Domain in Keystone  
source /home/stack/templates/overcloudrc_v3  
openstack domain create YOURDOMAIN 
  
# Allow default domain admin user to be admin in new Domain admin role  
domain_id=$(openstack domain show YOURDOMAIN |grep id |awk '{print $4;}')  
admin_id=$(openstack user list --domain default | grep admin |awk '{print $2;}')  
admin_role_id=$(openstack role list |grep admin |awk '{print $2;}')  
openstack role add --domain $domain_id --user $admin_id $admin_role_id  
  
# Variables  
unset OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME OS_NO_CACHE OS_IDENTITY_API_VERSION OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME  
source ~/stackrc  
controller_IP=$(nova list |grep ctrl |awk '{print $12;}'|awk -F'=' '{print $NF}')  
  
# Restart Keystone Services (httpd) on Controllers  
rm /home/stack/.ssh/known_hosts  
unset OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME OS_NO_CACHE OS_IDENTITY_API_VERSION OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME  
source /home/stack/stackrc  
for i in $controller_IP; do ssh -o StrictHostKeyChecking=no heat-admin@$i -C 'sudo systemctl restart httpd.service';done  
    
  
# Gather service account info  
source /home/stack/templates/overcloudrc_v3  
domain_id=$(openstack domain show YOURDOMAIN |grep id |awk '{print $4;}')  
admin_role_id=$(openstack role list |grep admin |awk '{print $2;}')  
member_role_id=$(openstack role list |grep member |awk '{print $2;}')  
  
set +x
