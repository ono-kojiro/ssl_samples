#!/bin/sh

apt -y install slapd ldap-utils samba
apt -y install libnss3-tools

apt -y install smbldap-tools

apt -y install sssd sssd-ldap sssd-tools
