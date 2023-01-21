#!/bin/sh

echo "1..1"

. ./config.bashrc

../myca crt -c $ca_name -d $ca_database -i $csrpath -o $crtpath $server_addr

if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi



