#!/bin/sh

rsa_pub="$HOME/.ssh/id_rsa.pub"

# see https://www.rfc-editor.org/rfc/rfc4716

# ---- BEGIN SSH2 PUBLIC KEY ----
# Comment: rsa Public Key

ssh-keygen -e -f $rsa_pub -m RFC4716 > for_cisco.pub

# paste above public key:
#   Security -> SSH Server -> SSH User Authentication

# add following configuration in $HOME/.ssh/config
#
# Host cisco
#  Hostname 192.168.0.XXX
#  KexAlgorithms +diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1,diffie-hellman-group14-sha1
#  HostKeyAlgorithms +ssh-rsa,ssh-dss

