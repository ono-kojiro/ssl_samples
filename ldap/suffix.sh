#!/bin/sh

cat - << 'EOS' > suffix.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
EOS

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f ./suffix.ldif

rm -f ./suffix.ldif


ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
  -LLL -b "olcDatabase={1}mdb,cn=config" olcSuffix

