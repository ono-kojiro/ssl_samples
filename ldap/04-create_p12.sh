#!/bin/sh

certutil -A -d /etc/ssl/server \
        -n MyServer -t ",," -i /etc/ssl/server/server.crt
pk12util \
        -d /etc/ssl/server \
        -n MyServer \
        -o /etc/ssl/server/server.p12
openssl pkcs12 \
        -in /etc/ssl/server/server.p12 \
        -nocerts \
        -out /etc/ssl/server/server.key \
        -nodes

