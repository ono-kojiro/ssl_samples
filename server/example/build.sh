#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

server_name="luna2"
server_base=`echo $server_name| tr '[:upper:]' '[:lower:]'`

server_key="${server_base}.key"
server_crq="${server_base}.crq"
server_crt="${server_base}.crt"

ca_crt="../../ca-gnutls/myrootca.crt"
ca_key="../../ca-gnutls/myrootca.key"

help() {
  cat - << EOS
usage : $0 <target>

  target
    key
    req
    crt
EOS

}

all()
{
  key
  req
  crt
}

key()
{
  certtool \
    --generate-privkey \
    --outfile ${server_key}
}

req()
{
  certtool \
    --generate-request \
    --load-privkey ${server_key} \
    --template request.cfg \
    --outfile ${server_crq}
}

crq_info()
{
  certtool --crq-info --infile ${server_crq}
}

crt()
{
  certtool \
    --generate-certificate \
    --load-request ${server_crq} \
    --load-ca-certificate ${ca_crt} \
    --load-ca-privkey ${ca_key} \
    --template generate.cfg \
    --outfile ${server_crt}
}

crt_info()
{
  certtool \
    --certificate-info --infile ${server_crt}
}

show()
{
  openssl x509 -noout -text -in ${server_crt} | tee output.txt
}

clean()
{
  rm -f *.crq *.crt *.key
}

args=""

while [ "$#" -ne 0 ]; do
  case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -i | --input)
      shift
      infile=$1
      ;;
    -o | --output)
      shift
      outfile=$1
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $arg
  else
    "ERROR: $arg is NOT a shell function."
    exit 1
  fi
done

