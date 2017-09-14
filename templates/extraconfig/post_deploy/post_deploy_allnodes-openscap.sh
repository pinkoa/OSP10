#!/bin/bash
#
# description:
# update overcloud systems to comply with openscap
# not that pretty, but functional
#
# post_deploy script
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

# setup_ntp
function setup_ntp() {
  LOG="/root/firstboot_setup_ntp.log"
  {
    FILE="/etc/ntp.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    cat << EOF > "${FILE}"
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
server 96.239.250.57
server 96.239.250.58
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF
    FILE="/etc/sysconfig/ntpd"
    cp -fva "${FILE}" "${FILE}.orig"
    if [ -e "${FILE}" ] ; then
      sed -i 's/^OPTIONS=.*/OPTIONS="-g -u ntp:ntp"/;' "${FILE}"
    else
      echo 'OPTIONS="-g -u ntp:ntp"' >> "${FILE}"
      restorecon -v "${FILE}"
    fi
  } >> "${LOG}"
}

# setup_audit
function setup_audit() {
  LOG="/root/firstboot_setup_audit.log"
  {
    FILE="/etc/audit/rules.d/audit.rules"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '/max_log_file_action.*/d' "${FILE}"
    echo "max_log_file_action = keep_logs" >> "${FILE}"
    cat << EOF >> "${FILE}"
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod -a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts -a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-w /etc/sudoers -p wa -k scope
-w /var/log/sudo.log -p wa -k actions
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
-e 2
EOF
    pkill -P 1 -HUP auditd
  } >> "${LOG}"
}

# setup_fileperms
function setup_fileperms() {
  LOG="/root/firstboot_setup_fileperms.log"
  {
    # modify permissions on specific files
    chown -v root:root /var/log/*log
    chmod -v 600 /var/log/*log
    chown -v root:root /etc/cron.*ly
    chmod -v og-rwx /etc/cron.*ly
    chown -v root:root /etc/crontab
    chmod -v og-rwx /etc/crontab
    # Fix at/cron daemon permissions:
    rm -vf /etc/at.deny
    touch /etc/at.allow
    chown -v root:root /etc/at.allow
    chmod -v og-rww /etc/at.allow
    rm -vf /etc/cron.deny
    touch /etc/cron.allow
    chmod -v og-rwx /etc/cron.allow
    chown -v root:root /etc/cron.allow
  } >> "${LOG}"
}

# setup_sshd
function setup_sshd() {
  LOG="/root/firstboot_setup_sshd.log"
  {
    FILE="/etc/ssh/sshd_config"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
/^Protocol\ /d;
/^Ciphers\ /d;
/^LogLevel\ /d;
/^PermitRootLogin\ /d;
/^MaxAuthTries\ /d;
/^HostbaseAuthentication\ /d;
/^IgnoreRhosts\ /d;
/^PermitEmptyPasswords\ /d;
/^PermitUserEnvironment\ /d;
/^Banner\ /d;
' "${FILE}"
    cat << EOF >> /etc/ssh/sshd_config
Protocol 2
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
LogLevel INFO
PermitRootLogin no
MaxAuthTries 4
HostbasedAuthentication no
IgnoreRhosts yes
PermitEmptyPasswords no
PermitUserEnvironment no
Banner /etc/verizonbanner
EOF
    systemctl restart sshd
  } >> "${LOG}"
}

# create_banner
function create_banner() {
  LOG="/root/firstboot_create_banner.log"
  {
    FILE="/etc/verizonbanner"
    cat << EOF > "${FILE}"
 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************

This system is intended to be used solely by authorized users in the course of
legitimate corporate business.  Users are monitored to the extent necessary to
properly administer the system, to identify unauthorized users or users operating
beyond their proper authority, and to investigate improper access or use. By
accessing the system, you are consenting to this monitoring.  Additionally, users
accessing this system agree that they understand and will comply with all Verizon
Information Security and Privacy policies, including policy statements, instructions,
standards and guidelines.

 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************
EOF
    restorecon -v "${FILE}"
    FILE="/etc/issue"
    cat << EOF > "${FILE}"
 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************

This system is intended to be used solely by authorized users in the course of
legitimate corporate business.  Users are monitored to the extent necessary to
properly administer the system, to identify unauthorized users or users operating
beyond their proper authority, and to investigate improper access or use. By
accessing the system, you are consenting to this monitoring.  Additionally, users
accessing this system agree that they understand and will comply with all Verizon
Information Security and Privacy policies, including policy statements, instructions,
standards and guidelines.

 ************ WARNING: UNAUTHORIZED PERSONS, DO NOT PROCEED ************
EOF
    restorecon -v "${FILE}"
  } >> "${LOG}"
}

# setup_passpolicy
function setup_passpolicy() {
  LOG="/root/firstboot_setup_passpolicy.log"
  {
    FILE="/etc/pam.d/system-auth"
    cp -fva "${FILE}" "${FILE}.orig"
    cat << EOF >> "${FILE}"
password    sufficient    pam_unix.so remember=5
EOF
    # modify pwqualityconf
    FILE="/etc/security/pwquality.conf"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
      /^minlen\ /d;
      /^dcredit\ /d;
      /^ucredit\ /d;
      /^lcredit\ /d;
      /^ocredit\ /d;
' "${FILE}"
    cat << EOF >> "${FILE}"
# openscap settings
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
EOF
  } >> "${LOG}"
}

# setup_su
function setup_su() {
  LOG="/root/firstboot_setup_su.log"
  {
    FILE="/etc/group"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i 's/^wheel:.*/wheel:x:10:corona,stack/;' "${FILE}"
    FILE="/etc/pam.d/su"
    cp -fva "${FILE}" "${FILE}.orig"
    # uncomment the following line in /etc/pam.d/su
    sed -i '/#\(auth.*required.*pam_wheel.so\ use_uid\)/s/\#//;' /etc/pam.d/su
  } >> "${LOG}"
}

# setup_login
function setup_login() {
  LOG="/root/firstboot_setup_login.log"
  {
    FILE="/etc/login.defs"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
      s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/;
      s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/;
' "${FILE}"
  } >> "${LOG}"
}

# setup_umask
function setup_umask() {
  LOG="/root/firstboot_setup_umask.log"
  {
    FILE="/etc/profile.d/corona.sh"
    cp -fva "${FILE}" "${FILE}.orig"
    echo "umask 077" > "${FILE}"
    restorecon -v "${FILE}"
  } >> "${LOG}"
}

# setup_useradd
function setup_useradd() {
  LOG="/root/firstboot_setup_useradd.log"
  {
    FILE="/etc/default/useradd"
    cp -fva "${FILE}" "${FILE}.orig"
    sed -i '
      s/^INACTIVE=.*/INACTIVE=35/;
' "${FILE}"
  } >> "${LOG}"
}

# functions below for post_deploy
setup_ntp
setup_audit
setup_fileperms
setup_sshd
create_banner
setup_passpolicy
setup_su
setup_login
setup_umask
setup_useradd


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
