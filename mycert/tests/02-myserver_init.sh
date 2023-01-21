#!/bin/sh

echo "1..2"

. ./config.bashrc

../myserver destroy -s $server_name -d $server_database
if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi

../myserver init -s $server_name -d $server_database
if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi


