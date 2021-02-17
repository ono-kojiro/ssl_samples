#!/bin/sh

#cp -f /usr/share/doc/samba/examples/LDAP/samba.schema.gz .
cp -f /usr/share/doc/samba/examples/LDAP/samba.ldif.gz .

gunzip -k -f samba.ldif.gz

rm -f samba.ldif.gz

ldapadd -Q -Y EXTERNAL -H ldapi:/// -f samba.ldif

#rm -f samba.schema

# check
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn


