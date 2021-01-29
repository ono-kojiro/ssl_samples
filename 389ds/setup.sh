#!/bin/sh

set -e
	
rootdn="cn=Manager,dc=my-domain,dc=com"
rootpw=secret

help()
{
	echo "setup.sh <target>"
	
}

create()
{

	echo stop dirsrv.target
	systemctl stop dirsrv.target

	echo remove directories
	rm -rf /etc/dirsrv/slapd-localhost
	rm -rf /var/log/dirsrv/slapd-localhost
	rm -rf /var/lock/dirsrv/slapd-localhost
	rm -rf /var/lib/dirsrv/*

	echo make directories
	mkdir -p /var/lock/dirsrv/slapd-localhost
	chown dirsrv.dirsrv /var/lock/dirsrv/slapd-localhost

	echo setup
	setup-ds.pl -s -f install.inf

	echo copy schema
	cp -f /usr/share/dirsrv/schema/*.ldif \
		/etc/dirsrv/slapd-localhost/schema/

	cp -f \
		/usr/share/doc/samba/LDAP/samba-schema-FDS.ldif \
		/etc/dirsrv/slapd-localhost/schema/60schema.ldif

	echo start dirsrv
	systemctl start dirsrv.target

	ss -lnt

	systemctl status dirsrv.target > status.log
	cat status.log
}

enable_ssl()
{
	echo enable ssl
	certutil -A -d /etc/dirsrv/slapd-localhost/ \
		-n "ca_cert" -t "C,," \
		-i /etc/pki/tls/cacert.crt

	certutil -A -d /etc/dirsrv/slapd-localhost/ \
		-n "Server-Cert" -t ",," \
		-i /etc/pki/tls/localhost/localhost.crt

	echo copy p12
	pk12util \
		-i /etc/pki/tls/localhost/private/localhost.p12 \
		-d /etc/dirsrv/slapd-localhost/

	echo "Internal (Software) Token:secret" > pin.txt
	cp -f pin.txt /etc/dirsrv/slapd-localhost/
	chmod 400 /etc/dirsrv/slapd-localhost/pin.txt

	ldapmodify -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f ssl_enable.ldif

	systemctl restart dirsrv.target

}

enable_samba()
{
	echo ldapadd
	ldapadd -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f sambaGroups.ldif

	systemctl restart dirsrv.target
	ldapadd -H ldap://localhost \
		-D ${rootdn} -w ${rootpw} -f sambaDomainName.ldif

	systemctl restart dirsrv.target

	systemctl status dirsrv.target

	ss -lnt
}

check()
{
	echo check
	echo check ldap without ssl
	ldapsearch -H ldap://localhost \
		-x -w $rootpw -D "cn=Manager,dc=my-domain,dc=com"

	echo check ldap with ssl
	ldapsearch -H ldaps://localhost \
		-x -w $rootpw -D "cn=Manager,dc=my-domain,dc=com"
}

build()
{
	echo build
}

logfile=""

while getopts hvl: option
do
        case "$option" in
                h)
                        help
			exit 0;;
                v)
                        verbose=1;;
                l)
                        logfile=$OPTARG;;
                *)
                        echo unknown option "$option";;
        esac
done

shift $(($OPTIND-1))

if [ "x$logfile" != "x" ]; then
        echo logfile is $logfile
fi

for target in "$@" ; do
	type=`LC_ALL=C type -t $target || true`

	if [ "$type" = "function" ]; then
		$target
	else
		echo ERROR : target "$target" is not function, ignored.
		exit 1
	fi
done

