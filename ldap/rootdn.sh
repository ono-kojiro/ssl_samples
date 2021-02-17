#!/bin/sh

cat - << 'EOS' > rootdn.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com
EOS

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f ./rootdn.ldif

rm -f rootdn.ldif

ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
	-LLL -b "olcDatabase={1}mdb,cn=config" olcRootDN

