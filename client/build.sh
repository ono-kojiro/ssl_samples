#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

client=${client:-"client"}
cn="$client"

output_dir="$top_dir"

database="$output_dir/db"
password=${password:-"secret"}
p12pass="p12pass"

csrfile=${output_dir}/${client}.csr
crtfile=${output_dir}/${client}.crt
  
p12file=${output_dir}/${client}.p12
pemfile=${output_dir}/${client}.key.pem
keyfile=${output_dir}/${client}.key
derfile=${output_dir}/${client}.der

help()
{
cat - << EOS
usage : $0 <target>
  target :
    clean
    init
    csr     create csr
    crt     create crt
    load    import server.crt
    list    show list of certificate
    save    export server.key
EOS

}

all()
{
  #destroy
  init

  csr
  crt
  load
  save
}


clean() {
  rm -f ${output_dir}/*.csr
  rm -f ${output_dir}/*.crt
  rm -f ${output_dir}/*.key
}

destroy()
{
  #rm -rf ${output_dir}
  :
}

list() {
  certutil -L -d ${database}
}

csr()
{
	echo "INFO: create csr, $csrfile"
	mkdir -p ${output_dir}
	echo -n ${password} > password.txt
	dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1

    cmd="certutil -R"
    cmd="$cmd -d ${database}"
	cmd="$cmd -s cn=$cn"
	cmd="$cmd -f password.txt"
	cmd="$cmd -z noise.bin"
	cmd="$cmd -o $csrfile"
    #cmd="$cmd --keyUsage digitalSignature,keyEncipherment"
    #cmd="$cmd --keyUsage digitalSignature,nonRepudiation,dataEncipherment"
    #cmd="$cmd --nsCertType  sslClient"
    #cmd="$cmd --extKeyUsage clientAuth"
    cmd="$cmd -n ${client}"
    cmd="$cmd -a"

    echo $cmd
    $cmd

	rm -f password.txt noise.bin

    #cat $csrfile | openssl req -text
    #openssl req -text -noout -in mylocalclient.csr
}

init()
{
  #rm -rf ${database}
  if [ ! -d "$database" ]; then
    mkdir -p ${database}

    echo "INFO: create database in ${database}"
    cmd="certutil -N -d ${database} --empty-password"
    echo $cmd
    $cmd
  else
    echo "INFO: ${database} is already existing."
  fi
}

crt()
{
  cd ../ca
  pwd
  sh ./build.sh ccert -i ${csrfile} -o ${crtfile}
  #cp -f ${crtfile} $top_dir/
  cd $top_dir
}

show()
{
  openssl x509 -text -noout -in ${crtfile}
}


load()
{
	echo "import $crtfile"
	certutil -A -d ${database} \
		-n "${client}" \
		-t ",," \
		-i $crtfile
}

dump()
{
  certutil
}

save()
{
	p12
	seckey
	#jks

    der
    cer
}

p12()
{
  echo export $p12file
  cmd="pk12util -o $p12file"

  cmd="$cmd -n ${client}"
  cmd="$cmd -d ${database}"
  cmd="$cmd -W ${p12pass}"

  echo $cmd
  $cmd

  echo "INFO: import p12 file in Microsoft Edge"
}

der()
{
  cmd="openssl x509 -outform der -in ${crtfile} -out ${derfile}"
  echo $cmd
  $cmd
}

seckey()
{
	echo export $pemfile
	openssl pkcs12 \
		-in  $p12file \
		-nocerts \
		-out $pemfile \
        -password "pass:${p12pass}" \
		-nodes


    openssl rsa -in  $pemfile -out $keyfile
}

cer()
{
  cat ${crtfile} ${keyfile} > ${client}.cer
}

vars()
{
  echo "csrfile : $csrfile"
}

destroy()
{
  rm -rf ${database}
  rm -f ${client}.*
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
  LANG=C type $target 2>&1 | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    echo target \"$target\" is not a function.
  fi
done

