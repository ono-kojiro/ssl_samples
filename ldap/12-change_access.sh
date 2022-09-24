#!/bin/sh

add_access()                                                            [4/1920]
{  
  ldapadd -Q -Y EXTERNAL -H ldapi:/// << EOF
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,givenName,sn,photo  by self write  by an
 onymous auth  by dn.base="cn=Manager,dc=example,dc=com" write  by * none
-                                                                               
add: olcAccess
olcAccess: {1}to *  by self read  by dn.base="cn=Manager,dc=example,dc=com
 " write  by * read
EOF       
                    
}
                    
show_access()
{
  ldapsearch -Q -LLL -Y EXTERNAL \
        -H ldapi:/// -b "olcDatabase={-1}frontend,cn=config"
}

show_access
add_access
show_access

