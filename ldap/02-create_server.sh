#!/bin/sh

rm -rf /etc/ssl/server
mkdir /etc/ssl/server
certutil -N -d /etc/ssl/server --empty-password
dd if=/dev/urandom of=/tmp/noise.bin bs=1 count=2048 > /dev/null 2>&1
certutil -R -s "cn=MyServer" -z /tmp/noise.bin \
        -o /etc/ssl/server/server.csr -a -d /etc/ssl/server

