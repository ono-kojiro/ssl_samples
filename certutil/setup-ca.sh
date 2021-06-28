#!/bin/sh

set -e

certname=MyLocalCA
nickname=MyLocalCA
database_dir=/etc/ssl/mylocalca
password=secret

cacert=/etc/ssl/certs/mylocalca.crt

server=jenkins
server_addr=192.168.0.98

help() {
	echo "usage : $0 <target>"
	echo " target"
	echo "   init   init database"
	echo "   ca     create CA"
	echo "   crt    create server.crt"
	echo ""
	echo "   clean  remove database"
}

clean() {
	echo clean database
	rm -rf ${database_dir}
	rm -f ${cacert}
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
	certutil -N -d ${database_dir} --empty-password
}

ca() {
	echo make a certificate
	echo $password > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	echo initialize CA
	printf 'y\n0\ny\n' | \
	certutil -S \
		-x \
		-d ${database_dir} \
		-z noise.bin \
		-n "$certname" \
		-s "cn=MyUbuntuCA" \
		-t "CT,C,C" \
		-m $RANDOM \
		-k rsa \
		-g 2048 \
		-Z SHA256 \
		-f password.txt \
		-2
	echo export ${cacert}
	certutil -L -d ${database_dir} \
		-n "$certname" -a > ${cacert}
	rm -f password.txt
	rm -f noise.bin
}

crt() {
	echo CA: create /etc/ssl/$server/$server.crt
	echo $password > password.txt
		
	#-x \
	certutil -C \
		-c "$certname" \
		-i /etc/ssl/$server/$server.csr \
		-a \
		-o /etc/ssl/$server/$server.crt \
		-f password.txt \
		--extSAN dns:localhost,ip:$server_addr,ip:127.0.0.1 \
		-v 120 \
		-d ${database_dir}
	echo CA: generated /etc/ssl/$server/$server.crt

	rm -f password.txt
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

