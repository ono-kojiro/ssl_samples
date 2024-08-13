#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ca_name=MyLocalCA

output_dir="$top_dir"
cabase=`echo $ca_name | tr '[:upper:]' '[:lower:]'`
cacert="${output_dir}/${cabase}.crt"

database="$output_dir/db"
password=${password:-"secret"}
months_valid=120

extkeyusage="serverAuth"
certtype="sslServer"
common_name=""

help() {
  cat - << EOS
usage : $0 <target>
target
 init       init database
 cacert     create CA cert
 show       show contents of cacert

 crt        create server.crt
 clean      remove database
EOS

}

clean() {
	echo clean database
	rm -rf ${database}
	rm -f ${cacert}
}

list() {
	certutil -L -d ${database}
}

prepare()
{
  sudo apt -y install libnss3-tools
}

init()
{
  if [ "$show_help" -ne 0 ]; then
    echo "usage: $0 init"
    exit 1
  fi

  mkdir -p ${database}
  rm -f ${database}/*

  echo "INFO: create database in ${database}"
  cmd="certutil -N -d ${database} --empty-password"
  echo $cmd
  $cmd
}

cacert()
{
  if [ -z "$ca_name" ]; then
    echo "ERROR : no ca_name option"
    exit 1
  fi

  echo "INFO: make a certificate"
  echo $password > password.txt
  dd if=/dev/urandom of=noise.bin bs=1 count=2048 > /dev/null 2>&1
  echo "initialize CA, $database"

  mkdir -p ${database}

  cmd="certutil"

  # Self sign
  cmd="$cmd -x"

  # Make a certificate and add to database 
  cmd="$cmd -S"

  # database-directory
  cmd="$cmd -d ${database}"

  # Specify the noise file to be used
  cmd="$cmd -z noise.bin"

  # Specify the nickname of the cert
  cmd="$cmd -n $ca_name"

  # Specify the subject name (using RFC1485)
  cmd="$cmd -s cn=${ca_name}"

  # Set the certificate trust attributes
  #   trustargs is of the form x,y,z where:
  #     x is for SSL,
  #     y is for S/MIME
  #     z is for code signing.
  # See also messages of 'certutil --help'
  cmd="$cmd -t CT,C,C"

  # Cert serial number
  cmd="$cmd -m $RANDOM"

  # Type of key pair to generate
  cmd="$cmd -k rsa"

  # Key size in bits
  cmd="$cmd -g 2048"

  # Specify the hash algorithm to use
  cmd="$cmd -Z SHA256"

  # Specify the password file
  cmd="$cmd -f password.txt"

  # Months valid (default is 3)
  cmd="$cmd -v $months_valid"

  # Create basic constraint extension
  cmd="$cmd -2"
  echo $cmd

  # Is this a CA certificate [y/N]? y
  # Enter the path length constraint, enter to skip [<0 for unlimited path]: 0
  # > Is this a critical extension [y/N]? y
  printf 'y\n0\ny\n' | $cmd

  export_cacert
}

show()
{
  openssl x509 -in ${cacert} -text
}

export_cacert()
{ 
  echo export ${cacert}
  mkdir -p ${output_dir}
  certutil -L -d ${database} \
    -n "$ca_name" -a > ${cacert}
  
  rm -f password.txt noise.bin
}

crt()
{
  if [ "$show_help" != "0" ]; then
    echo "usage : $0 --output output.crt --input input.csr"
    exit 1
  fi

  ret=0
  if [ -z "$output" ]; then
    echo "ERROR : no output option"
    ret=`expr $ret + 1`
  fi
  
  if [ -z "$input" ]; then
    echo "ERROR : no input option"
    ret=`expr $ret + 1`
  fi
  
  if [ $ret != 0 ]; then
    exit $ret
  fi
    
  echo CA: create ${output}
  echo $password > password.txt

  # -C : create a new binary certificate file		
  #-x \
  cmd="certutil -C"
  cmd="$cmd -c $ca_name"
  cmd="$cmd -i ${input}"
  cmd="$cmd -a"
  cmd="$cmd -o ${output}"
  cmd="$cmd -f password.txt"
  cmd="$cmd -v 120"
  cmd="$cmd -d ${database}"
  cmd="$cmd --nsCertType $certtype"
  cmd="$cmd --extKeyUsage $extkeyusage"
  
  echo $cmd
  $cmd
  echo "generated ${output}"
  rm -f password.txt
}

ccert() {
  if [ "$show_help" != "0" ]; then
    echo "usage : $0 --output output.crt --input input.csr addr1 addr2 ..."
    exit 1
  fi

  ret=0
  if [ -z "$output" ]; then
    echo "ERROR : no output option"
    ret=`expr $ret + 1`
  fi
  
  if [ -z "$input" ]; then
    echo "ERROR : no input option"
    ret=`expr $ret + 1`
  fi

  #if [ $# -eq 0 ]; then
  #  echo "no server addresses"
  #  ret=`expr $ret + 1`
  #fi

  if [ $ret != 0 ]; then
    exit $ret
  fi
    
  server_addrs="$@"

  echo CA: create ${output}
  echo $password > password.txt

  extsan="dns:localhost"
  for addr in $server_addrs; do
    extsan="$extsan,ip:$addr"
  done

  # -C : create a new binary certificate file		
  #-x \
  cmd="certutil -C"
  cmd="$cmd -c $ca_name"
  cmd="$cmd -i ${input}"
  cmd="$cmd -a"
  cmd="$cmd -o ${output}"
  cmd="$cmd -f password.txt"
  #cmd="$cmd --extSAN $extsan"
  cmd="$cmd -v 120"
  cmd="$cmd -d ${database}"
  #cmd="$cmd --keyUsage nonRepudiation,dataEncipherment"
  #cmd="$cmd --nsCertType  sslClient"
  #cmd="$cmd --extKeyUsage clientAuth"
  
  echo $cmd
  $cmd
  echo "generated ${output}"
  rm -f password.txt
}


vars()
{
  echo "ca_name      : ${ca_name}"
  echo "database     : ${database}"
  echo "cacert       : ${cacert}"
  echo "input        : ${input}"
  echo "output       : ${output}"
  echo "server_addr  : ${server_addr}"
}

clean()
{
  rm -f ${output_dir}/*.crt
}

destroy()
{
  rm -rf ${database_dir}
}

install_cacert()
{
  ansible-playbook -K -i hosts.yml site.yml
}

if [ $# -eq 0 ]; then
  help
  exit 1
fi

subcmd=$1
shift
	
num=`LANG=C type $subcmd | grep 'function' | wc -l`
if [ "$num" -eq 0 ]; then
  echo \"$subcmd\" is not a function.
  exit 2
fi

args=""
show_help=0

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
      show_help=1
      ;;
    -c | --ca_name)
      shift
      ca_name=$1
      ;;
    -i | --input)
      shift
      input=$1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -e | --extkeyusage)
      shift
      extkeyusage=$1
      ;;
    -t | --certtype)
      shift
      certtype=$1
      ;;
    -n | --common-name)
      shift
      common_name=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

$subcmd "$@"

