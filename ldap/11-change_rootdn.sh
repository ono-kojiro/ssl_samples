#!/bin/sh

change_rootdn()
{
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com
EOF

}

show_rootdn()
{
  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
    -LLL -b "olcDatabase={1}mdb,cn=config" olcRootDN
}
 
show_rootdn
change_rootdn
show_rootdn

