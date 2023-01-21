#!/bin/sh

echo "1..2"

. ./config.bashrc

../myca destroy -c ${ca_name} -d ${ca_database}

if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi

../myca init -c ${ca_name} -d ${ca_database}
if [ "$?" -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi


