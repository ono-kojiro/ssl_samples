#!/bin/sh

echo "1..1"

. ./config.bashrc

../myserver save -s $server_name -d $server_database

if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi



