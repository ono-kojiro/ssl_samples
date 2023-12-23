#!/bin/sh

addr=`ip addr show br0 | grep 'inet ' | gawk -F' +|/' '{ print $3 }'`

ldapsearch -H ldaps://$addr -D cn=Manager,dc=example,dc=com -W

