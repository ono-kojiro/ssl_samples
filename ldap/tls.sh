#!/bin/sh

cat - << 'EOS' > tls.ldif
dn: cn=config
changetype: modify
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/certs/server.crt
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/certs/server.key
EOS

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f tls.ldif

rm -f tls.ldif

ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" olcTLSCertificateFile | grep TLS

ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=config" olcTLSCertificateKeyFile | grep TLS

