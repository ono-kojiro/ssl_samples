#!/bin/sh

sudo slapcat -n 0 -F /etc/ldap/slapd.d > config.ldif
sudo slapcat -n 1 -F /etc/ldap/slapd.d > userdata.ldif


