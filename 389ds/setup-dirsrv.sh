#!/bin/sh

set -e

if [ -e "config.bashrc" ]; then
  source ./config.bashrc
else
  echo "create config.bashrc and set rootdn and rootpw"
  exit 1
fi

addr=192.168.0.98
instance_name=rhel8
instance_dir=/etc/dirsrv/slapd-${instance_name}

stop()
{
	echo stop dirsrv.target
	systemctl stop dirsrv.target
}

status()
{
  systemctl status dirsrv.target | cat
}

clean()
{
	echo stop dirsrv and clean dirsrv instance
	stop
	rm -rf $instance_dir
	rm -rf /var/log/dirsrv/slapd-${instance_name}
	rm -rf /var/lock/dirsrv/slapd-${instance_name}
	rm -rf /var/lib/dirsrv/*
}

init()
{
	echo make directories
	mkdir -p /var/lock/dirsrv/slapd-${instance_name}
	chown dirsrv.dirsrv /var/lock/dirsrv/slapd-${instance_name}

	cat - << EOS > install.inf
[General]
Name=389 Directory Suite
Components=slapd

FullMachineName= rhel8.localdomain
SuiteSpotUserID= dirsrv
ServerRoot= /usr/lib64/389-ds

[slapd]
Name= 389 Directory Server
InstanceNamePrefix= Directory Server
NickName= slapd
Version= 1.4.2.9
BaseVersion= 1.2
Compatible= 1.0
BuildNumber= 2020.076.197
Description= 389 Directory Server
ProductName=Directory Server
Vendor= 389 Project

Expires= 0
Security= domestic
IsDirLite=false
PreInstall= ns-config
PostInstall= bin/slapd/admin/bin/ns-update
PreUninstall= bin/slapd/admin/bin/uninstall
PostUninstall=
Checked=True
Mandatory=False
IsLdap=True

ServerPort=389
ServerIdetifier= localhost
Suffix= dc=example,dc=com
RootDN= cn=Manager,dc=example,dc=com
RootDNPwd= $passwd

EOS

	echo setup
	setup-ds.pl -s -f install.inf --logfile setup-ds.log

	echo import CA cert
	certutil -d ${instance_dir} \
				-A -n "My Local CA" -t "CT,," \
				-a -i cacert.crt

	_copy_schema
}

_copy_schema()
{
	echo copy schema
	cp -f /usr/share/dirsrv/schema/*.ldif \
		${instance_dir}/schema/

	cp -f \
		/usr/share/doc/samba/LDAP/samba-schema-FDS.ldif \
		${instance_dir}/schema/60schema.ldif
}

start()
{
	echo start dirsrv
	systemctl start dirsrv.target
}

enable()
{
	echo enable dirsrv
	systemctl enable dirsrv.target
}

ldap_add()
{
	cat - << EOS > sambaGroups.ldif
dn: cn=Domain Admins,ou=Groups,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: Domain Admins
userPassword: {crypt}x
gidNumber: 2512

dn: cn=Domain Users,ou=Groups,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: Domain Users
userPassword: {crypt}x
gidNumber: 2513

dn: cn=Domain Guests,ou=Groups,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: Domain Guests
userPassword: {crypt}x
gidNumber: 2514

dn: cn=Domain Computers,ou=Groups,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: Domain Computers
userPassword: {crypt}x
gidNumber: 2515

EOS

	echo ldapadd
	ldapadd -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f sambaGroups.ldif

	cat - << EOS > sambaDomainName.ldif
dn: sambaDomainName=SAMBA,dc=example,dc=com
objectclass: sambaDomain
objectclass: sambaUnixIdPool
objectclass: top
sambaDomainName: SAMBA
sambaSID: S-1-5-21-1370597949-98365694-265993044
uidNumber: 550
gidNumber: 550

EOS

	systemctl restart dirsrv.target
	ldapadd -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f sambaDomainName.ldif
}

ldap()
{
	ldapsearch -H ldap://localhost -x -w ${rootpw} \
		-D "cn=Manager,dc=example,dc=com"
}

restart()
{
	systemctl restart dirsrv.target
}

ldaps()
{
	ldapsearch -H ldaps://localhost -x -w ${rootpw} \
		-D "cn=Manager,dc=example,dc=com"
}

list()
{
	certutil -L -d ${instance_dir}
}

csr()
{
	echo create csr
	echo $rootpw > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048
	#-s "cn=localhost,O=Personal,L=Yokohama,ST=Kanagawa,C=JP" 
	certutil -R \
		-s "cn=localhost" \
		-f password.txt \
		-z noise.bin \
		-o server.csr \
		-a \
		-extSAN dns:localhost,$addr,ip:127.0.0.1 \
		-d ${instance_dir}


	cat server.csr
	rm -f password.txt noise.bin
}

import()
{
  echo import server.crt
  certutil -A -d ${instance_dir} \
    -n "Server-Cert" \
    -t ",," -i server.crt

  pk12util -n "Server-Cert" -o server.p12 -W $rootpw -d ${instance_dir}
  openssl pkcs12 -in server.p12 -nocerts \
    -passin pass:$rootpw -out server.key -nodes
  chmod 600 server.key

  cp -f server.crt /etc/pki/tls/certs/
  cp -f server.key /etc/pki/tls/private/
}

ssl()
{
	cat - << EOS > modify_encryption.ldif
dn: cn=encryption,cn=config
changetype: modify
replace: nsSSL3
nsSSL3: off
-
replace: nsSSLClientAuth
nsSSLClientAuth: allowed
-
add: nsSSL3Ciphers
nsSSL3Ciphers: +all
EOS
	ldapmodify -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f modify_encryption.ldif

	cat - << EOS > modify_config.ldif
dn: cn=config
changetype: modify
add: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-ssl-check-hostname
nsslapd-ssl-check-hostname: off

EOS
	
	ldapmodify -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f modify_config.ldif
	
	cat - << EOS > modify_rsa.ldif
dn: cn=RSA,cn=encryption,cn=config
changetype: modify
replace: nsSSLPersonalitySSL
nsSSLPersonalitySSL: Server-Cert
-
replace: nsSSLToken
nsSSLToken: internal (software)
-
replace: nsSSLActivation
nsSSLActivation: on
EOS
	ldapmodify -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f modify_rsa.ldif
	
	rm -f modify_rsa.ldif

}

all()
{
	stop
	remove
	init

	start
	enable
	ldap_add

	csr
}

help()
{
	echo "setup.sh <target>"
	echo "target :"
	echo "  stop    stop dirsrv"
	echo "  remove  remove dirsrv instance"
	echo "  init    initialize dirsrv instance"
	echo "  _copy_schema    copy_schema"
	echo "  start"
	echo "  add"
}

for target in $@; do
	type=`type -t $target || true`
	if [ "x$type" = "xfunction" ]; then
		$target
	fi
done


