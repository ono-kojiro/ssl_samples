#!/bin/sh

nickname=MyServer

server=`echo $nickname | tr '[:upper:]' '[:lower:]'`

database_dir=./db
password=${password:-"secret"}

output_dir=./out
csrfile=${output_dir}/${server}.csr
crtfile=${output_dir}/${server}.crt
  
p12file=${output_dir}/${server}.p12
pemfile=${output_dir}/${server}.key.pem
keyfile=${output_dir}/${server}.key


help() {
	echo "usage : $0 <target>"
	echo " target :"
    echo "   clean"
    echo "   init"
	echo "   csr     create server.csr"
	echo "   import  import server.crt"
	echo "   save    export server.key"
}

clean() {
	rm -rf ${output_dir}
}

destroy()
{
	clean
	rm -rf ${database_dir}
}

list() {
	certutil -L -d ${database_dir}
}

init() {
  mkdir -p ${database_dir}
  rm -f ${database_dir}/cert8.db
  rm -f ${database_dir}/key3.db
  rm -f ${database_dir}/secmod.db

  echo create database ${database_dir}
  dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
  certutil -N -d ${database_dir} --empty-password
  rm -f noise.bin
}

csr()
{
	echo "create csr"
	mkdir -p ${output_dir}
	echo ${password} > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	
    certutil -R \
		-d ${database_dir} \
		-s "cn=$server" \
		-f password.txt \
		-z noise.bin \
		-o $csrfile \
		-a 

	rm -f password.txt noise.bin
}

import()
{
	echo "import $crtfile"
	certutil -A -d ${database_dir} \
		-n "${nickname}" \
		-t ",," \
		-i $crtfile
}

save()
{
	p12
	seckey
	#jks
}

p12()
{
  echo export $p12file
  pk12util -o $p12file \
    -n "${nickname}" \
    -d ${database_dir} \
    -W "${password}"
}

seckey()
{
	echo export $pemfile
	openssl pkcs12 \
		-in  $p12file \
		-nocerts \
		-out $pemfile \
		-password "pass:${password}" \
		-nodes

    openssl rsa -in  $pemfile -out $keyfile
}

jks()
{
	echo export $database_dir/$server.jks
	rm -f $database_dir/$server.jks
	LANG=C keytool -importkeystore \
		-srckeystore $database_dir/$server.p12 \
		-srcstoretype PKCS12 \
		-deststoretype JKS \
		-destkeystore $database_dir/$server.jks \
		-storepass "${password}" \
		-keypass "${password}" \
		-destkeypass "${password}" \
		-srcstorepass "${password}"

	# ubuntu:
	# edit /etc/default/jenkins
	#
	# HTTPS_PORT=8443
	# KEYSTORE=/var/lib/jenkins/jenkins.jks
	# PASSWORD=secret
	# JENKINS_ARGS="--webroot=/var/cache/$NAME/war --httpsPort=$HTTPS_PORT --https    KeyStore=$KEYSTORE --httpsKeyStorePassword=$PASSWORD --httpPort=$HTTP_PORT"
	#

}

vars()
{
  echo "csrfile : $csrfile"
}

destroy()
{
  rm -rf ${database_dir}
  rm -rf ${output_dir}
}

args=""
input=""
output=""

while [ "$#" != "0" ]; do
  case $1 in
    -c | --certname)
      shift
      certname=$1
      ;;
    -i | --input)
      shift
      input=$1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -s | --server)
      shift
      server=$1
      ;;
    -a | --address)
      shift
      address=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "${args}" ]; then
  help 
  exit 1
fi

for target in $args; do
  LANG=C type -t $target | grep 'function' > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    $target
  else
    echo target \"$target\" is not a function.
  fi
done

