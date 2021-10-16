#!/bin/sh

set -e

nickname=MyServer

server=myserver
#server=server

#database_dir=/etc/ssl/server
database_dir=/etc/ssl/$server
password=secret

help() {
	echo "usage : $0 <target>"
	echo " target : clean init"
	echo "          csr           create csr"
	echo "          import    import server.crt"
	echo "          export_key    export server.key"
}

clean() {
	echo clean database
	rm -rf ${database_dir}
	echo /etc/ssl/$server/$server.{csr,crt,key,p12}
	rm -f /etc/ssl/$server/$server.csr
	rm -f /etc/ssl/$server/$server.crt
	rm -f /etc/ssl/$server/$server.key
	rm -f /etc/ssl/$server/$server.p12
	rm -f /etc/ssl/$server/$server.jks
}

list() {
	certutil -L -d ${database_dir}
}

init() {
	mkdir -p ${database_dir}
	rm -f ${database_dir}/cert8.db
	rm -f ${database_dir}/key3.db
	rm -f ${database_dir}/secmod.db

	echo create database
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	certutil -N -d ${database_dir} --empty-password
}

csr()
{
	echo create csr
	echo ${password} > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	#-s "cn=localhost,O=Personal,L=Yokohama,ST=Kanagawa,C=JP" 
	certutil -R \
		-s "cn=$server" \
		-f password.txt \
		-z noise.bin \
		-o /etc/ssl/$server/$server.csr \
		-a \
		-d ${database_dir}
		
	# -extSAN dns:localhost,192.168.0.6,ip:127.0.0.1

	cat /etc/ssl/$server/$server.csr
	rm -f password.txt noise.bin
}

import(){
	echo import /etc/ssl/$server/$server.crt
	certutil -A -d ${database_dir} \
		-n "${nickname}" \
		-t ",," \
		-i /etc/ssl/$server/$server.crt
}

export_key()
{
	p12
	seckey
	jks
}

p12()
{
	echo export $database_dir/$server.p12
	pk12util -o $database_dir/$server.p12 \
       		-n "${nickname}" \
		-d ${database_dir} \
		-W "${password}"
}

seckey()
{
	echo export $database_dir/$server.key
	openssl pkcs12 \
		-in $database_dir/$server.p12 \
		-nocerts \
		-out $database_dir/$server.key \
		-password "pass:${password}" \
		-nodes
}

jks()
{
	echo export $database_dir/$server.jks
	rm -f $database_dir/$server.jks
	keytool -importkeystore \
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


for target in $@; do
	#type=`type -t $target || true`
	cnt=`type $target | grep 'function' | wc -l || true`
	if [ "x$cnt" = "x1" ]; then
		$target
	else
		echo target \"$target\" is not a function.
	fi
done

