#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ca_name="MyRootCA"

ca_base=`echo $ca_name | tr '[:upper:]' '[:lower:]'`

ca_key="${ca_base}.key"
ca_crt="${ca_base}.crt"
ca_cfg="${ca_base}.cfg"

cat - << EOF > ${ca_cfg}
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

usage() {
  cat - << EOS
usage : $0 <target>

  target:
    key
    crt
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
    --no-text \
    --outfile ${ca_key}
}

crt()
{
  echo "INFO: generate cert..."
  certtool \
    --generate-self-signed \
    --p12-name "My Root Certificate Authority" \
    --load-privkey ${ca_key} \
    --template ${ca_cfg} \
    --outfile ${ca_crt}

  rm -f ${ca_cfg}
}

info()
{
  certtool \
    --certificate-info --infile ${ca_crt}
}

clean()
{
  rm -f ${ca_crt} ${ca_key} ${ca_cfg}
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

