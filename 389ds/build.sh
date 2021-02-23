#!/bin/sh

set -e

if [ -e "config.bashrc" ]; then
  . ./config.bashrc
else
  echo "no config.bashrc file"
  exit 1
fi

help()
{
  echo "usage : $0 <target>"
  echo "   target : clean init"
}

all()
{
  clean
  init
  start
  csr
  crt
  dirsrv_import
  dirsrv_enable_ssl
  restart
}

check()
{
  systemctl status dirsrv.target | cat
  ldapsearch -H ldap://127.0.0.1 -x -w $rootpw -D $rootdn | wc -l
  ldapsearch -H ldaps://127.0.0.1 -x -w $rootpw -D $rootdn | wc -l
}

test()
{
  ldapmodify -a -D $rootdn -w $rootpw \
    -H ldap://localhost -x -f userdata.ldif
}


clean()
{
  rm -f server.csr
  #rm -f server.key
  #rm -f server.p12
  #rm -f server.crt

  rm -f password.txt

  rm -f modify_config.ldif
  rm -f modify_encryption.ldif
  #rm -f cacert.crt
  rm -f install.inf
}

mclean()
{
  clean
  sh setup-dirsrv.sh clean
  sh setup-ca.sh clean
}


init()
{
  sh setup-ca.sh     init
  sh setup-dirsrv.sh init
}

start()
{
  sh setup-dirsrv.sh start
}

csr()
{
  sh setup-dirsrv.sh csr
}

crt()
{
  sh setup-ca.sh crt
}

dirsrv_import()
{
  sh setup-dirsrv.sh import
}

dirsrv_enable_ssl()
{
  sh setup-dirsrv.sh ssl
}

restart()
{
  sh setup-dirsrv.sh restart
}

if [ -z "$@" ]; then
  all
fi

for target in $@; do
	LANG=C type $target | grep function > /dev/null 2>&1
	res=$?
	if [ "x$res" = "x0" ]; then
		$target
	else
		echo "$target is not a shell function"
	fi
done


