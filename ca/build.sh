#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ret=0

if [ ! -e ".env" ]; then
  echo "ERROR: no .env file"
  ret=`expr $ret + 1`
else
  . ./.env
fi

if [ -z "$ca_name" ]; then
  echo "ERROR: ca_name not defined"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  exit $ret
fi

ca_name="MyRootCA"

ca_base=`echo $ca_name | tr '[:upper:]' '[:lower:]'`

ca_key="${ca_base}.key"
ca_crt="${ca_base}.crt"

usage() {
  cat - << EOS
usage : $0 <target>

  target:
    all (key / crt)
    key
    crt

    info
    clean / mclean
EOS

}

all()
{
  key
  crt
}

key()
{
  certtool \
    --generate-privkey \
    --sec-param High \
    --key-type ${key_type} \
    --outfile ${ca_key}
}

debug()
{
  echo $tmpfile
}

crt()
{
  template=`mktemp` || exit

  cat - << EOF > ${template}
organization = "MyRootCA"
unit = "MyUnit"

state = "Example"
country = "JP"
cn = "MyRootCA"
expiration_days = 7300
ca
cert_signing_key
crl_signing_key
EOF

  echo "INFO: generate cert..."
  certtool \
    --generate-self-signed \
    --p12-name "My Root Certificate Authority" \
    --load-privkey ${ca_key} \
    --template ${template} \
    --outfile ${ca_crt}

  rm -f ${template}
}

info()
{
  certtool \
    --certificate-info --infile ${ca_crt}
}

clean()
{
  :
}

mclean()
{
  rm -f ${ca_crt} ${ca_key}
}

args=""

while [ "$#" -ne 0 ]; do
  case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      args="$args $1"
      ;;
  esac

  shift
done

if [ -z "$args" ]; then
  usage
fi

for arg in $args; do
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $arg
  else
    echo "ERROR: $arg is NOT a shell function." 1>&2
    exit 1
  fi
done

