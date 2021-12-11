#!/bin/sh

certname=MyCA
nickname=$certname
#database_dir=/etc/ssl/myca
database_dir=`pwd`/myca
password=secret
cacert=${database_dir}/myca.crt

server=optiplex
server_addr=192.168.0.93

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
  if [ -z "$certname" ]; then
    echo "ERROR : no certname option"
    exit 1
  fi

	echo make a certificate, ${database_dir}
	echo $password > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
	echo "initialize CA, $database_dir"

    mkdir -p ${database_dir}

	printf 'y\n0\ny\n' | \
	certutil -S \
		-x \
		-d ${database_dir} \
		-z noise.bin \
		-n "$certname" \
		-s "cn=${certname}" \
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
  if [ -z "$output" ]; then
    echo "ERROR : no output option"
    exit 1
  fi

	echo CA: create ${output}
	echo $password > password.txt
		
	#-x \
	certutil -C \
		-c "$certname" \
		-i ${input} \
		-a \
		-o ${output} \
		-f password.txt \
        --extSAN dns:localhost,ip:$server_addr,ip:127.0.0.1 \
		-v 120 \
		-d ${database_dir}
	echo CA: generated ${output}
		
    # --extSAN dns:localhost,ip:$server_addr,ip:127.0.0.1 
	rm -f password.txt
}

vars()
{
  echo "certname     : ${certname}"
  echo "database_dir : ${database_dir}"
  echo "cacert       : ${cacert}"
  echo "input        : ${input}"
  echo "output       : ${output}"
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
    *)
      args="$args $1"
      ;;
  esac

  shift
done

echo "args is $args"

for target in $args; do
	LANG=C type $target | grep 'function' > /dev/null 2>&1
	if [ "$?" = "0" ]; then
		$target
	else
		echo target \"$target\" is not a function.
	fi
done

