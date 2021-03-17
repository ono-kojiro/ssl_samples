#!/bin/sh

certutil -C \
        -d /etc/ssl/ca \
        -c MyCA -i /etc/ssl/server/server.csr \
        -a -o /etc/ssl/server/server.crt \
        --extSAN dns:localhost,ip:192.168.0.7,ip:127.0.0.1 \
        -v 120

