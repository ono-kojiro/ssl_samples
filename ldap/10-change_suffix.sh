#!/bin/sh

change_suffix()
{
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
EOF

}

show_suffix()
{
  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
    -LLL -b "olcDatabase={1}mdb,cn=config" olcSuffix
}

show_suffix
change_suffix
show_suffix

