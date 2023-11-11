#!/usr/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

servername=$(basename $0 .sh)
basename=$(echo $servername | tr '[:upper:]' '[:lower:]')
  
csrfile=$HOME/.local/share/${servername}/${basename}.csr
crtfile=$HOME/.local/share/${servername}/${basename}.crt
keyfile=$HOME/.local/share/${servername}/${basename}.key

cd server
servername="$servername" sh myserver.sh init csr
cd $top_dir

cd ca
input=$csrfile \
  output=$crtfile \
  sh mylocalca.sh crt 192.168.0.98
cd $top_dir

cd server
servername="$servername" sh myserver.sh load save
cd $top_dir
  
cp -f $crtfile .
cp -f $keyfile .

