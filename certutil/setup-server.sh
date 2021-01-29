#!/bin/sh

set -e

nickname=Server-Cert

database_dir=/etc/ssl/server
password=secret

cacert=/etc/ssl/certs/cacert.pem

help() {
	echo "usage : $0 <target>"
	echo " target : clean init"
	echo "          import_pem    import cacert.pem"
	echo "          import_crt    import server.crt"
	echo "          export_key    export server.key"
}

clean() {
	echo clean database
	rm -rf ${database_dir}
	echo /etc/ssl/server.{csr,crt,key,p12}
	rm -f /etc/ssl/server.csr
	rm -f /etc/ssl/server.crt
	rm -f /etc/ssl/server.key
	rm -f /etc/ssl/server.p12
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

import_pem(){
	certutil -d ${database_dir} \
		-A -n "My Local CA" \
		-t "CT,," \
		-a -i ${cacert}
}

csr()
{
	echo create csr
	echo ${password} > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	#-s "cn=localhost,O=Personal,L=Yokohama,ST=Kanagawa,C=JP" 
	certutil -R \
		-s "cn=MyUbuntuServer" \
		-f password.txt \
		-z noise.bin \
		-o server.csr \
		-a \
		-d ${database_dir}
		
	# -extSAN dns:localhost,192.168.0.6,ip:127.0.0.1

	cat server.csr
	rm -f password.txt noise.bin
}

import_crt(){
	echo import server.crt
	certutil -A -d ${database_dir} \
		-n "${nickname}" \
		-t ",," \
		-i ./server.crt
}

export_key(){
	echo export server.p12
	pk12util -o server.p12 \
       		-n "${nickname}" \
		-d ${database_dir} \
		-W "${password}"

	echo export server.key
	openssl pkcs12 \
		-in server.p12 \
		-nocerts \
		-out server.key \
		-password "pass:${password}" \
		-nodes
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

