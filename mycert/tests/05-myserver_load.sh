#!/bin/sh

echo "1..2"

. ./config.bashrc

csrfile=${server_name}.csr
csrfile=`echo $csrfile | tr '[:upper:]' '[:lower:]'`

crtfile=${server_name}.crt
crtfile=`echo $crtfile | tr '[:upper:]' '[:lower:]'`

csrpath=${server_database}/${csrfile}
crtpath=${server_database}/${crtfile}

../myserver load -s $server_name -d $server_database

if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi

../myserver list -s $server_name -d $server_database

if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi





