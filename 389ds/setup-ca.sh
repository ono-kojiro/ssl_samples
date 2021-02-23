#!/bin/sh

set -e

certname=MyCA
nickname=MyCA

instance_name=localhost
instance_dir=/etc/pki/tls

if [ -e "config.bashrc" ]; then
  . config.bashrc
else
  echo "no config.bashrc."
  echo "create config.bashrc and define 'password' variable."
  exit 1
fi

help()
{
	echo "usage : $0 <target>"
	echo "   target : clean init"
}

clean()
{
	echo clean database
	rm -f ${instance_dir}/cert9.db
	rm -f ${instance_dir}/key4.db
	rm -f ${instance_dir}/pkcs11.txt

}

list()
{
	certutil -L -d ${instance_dir}
}

init()
{
	echo create database
	dd if=/dev/urandom of=noise.bin bs=1 count=2048
	certutil -N -d ${instance_dir} --empty-password

	rm -f noise.bin
	echo make a certificate
	echo $password > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048
	echo -e "y\n\ny\n" | \
	certutil -S \
		-x \
		-d ${instance_dir} \
		-z noise.bin \
		-n "$certname" \
		-s "cn=CAcert" \
		-t "CT,C,C" \
		-m $RANDOM \
		-k rsa \
		-g 2048 \
		-Z SHA256 \
		-f password.txt \
		-2

	echo export cacert.crt
	certutil -L -d ${instance_dir} \
		-n "$certname" -a > cacert.crt
	rm -f password.txt
	rm -f noise.bin

	cp -f cacert.crt /etc/pki/tls/certs/
}

crt()
{
	echo CA: create crt
	echo $password > password.txt
		
	#-x \

	certutil -C \
		-c "$certname" \
		-i server.csr \
		-a \
		-o server.crt \
		-f password.txt \
		--extSAN dns:localhost,ip:192.168.56.78,ip:127.0.0.1 \
		-v 120 \
		-d ${instance_dir}
	echo CA: generated server.crt
}

for target in $@; do
	type=`type -t $target || true`
	if [ "x$type" = "xfunction" ]; then
		$target
	fi
done


