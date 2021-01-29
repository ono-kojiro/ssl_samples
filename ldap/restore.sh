#!/bin/sh

#sudo slapadd -n 0 -F /etc/ldap/slapd.d -l config.ldif
sudo slapadd -n 1 -F /etc/ldap/slapd.d -l userdata.ldif

