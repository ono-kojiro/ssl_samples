#!/bin/sh

rm -rf /etc/ssl/ca
mkdir -p /etc/ssl/ca
certutil -N -d /etc/ssl/ca --empty-password
dd if=/dev/urandom of=/tmp/noise.bin bs=1 count=2048 > /dev/null 2>&1
certutil -S -x -d /etc/ssl/ca -z /tmp/noise.bin \
  -n MyCA -s "cn=MyCA" -t "CT,C,C" -k rsa -g 2048 -Z SHA256 -2
certutil -L -d /etc/ssl/ca -n MyCA -a > /etc/ssl/certs/cacert.crt

