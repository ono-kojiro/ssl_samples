#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ca_name="MyLocalCA"

ca_base=`echo $ca_name | tr '[:upper:]' '[:lower:]'`

ca_key="${ca_base}.key"
ca_crt="${ca_base}.crt"
ca_cfg="${ca_base}.cfg"

usage() {
  cat - << EOS
usage : $0 <target>

  target:
    key
    crt

    show
EOS

}

all()
{
  key
  crt
}

key()
{
  echo "INFO: generate private key..."
  certtool \
    --generate-privkey \
    --no-text \
    --sec-param High \
    --key-type=ed25519 \
    --outfile ${ca_key}
}

crt()
{
  cat - << EOF > ${ca_cfg}
organization = "MyLocalCA"
unit = "MyUnit"

state = "MyState"
country = "JP"
cn = "MyLocalCA"
expiration_days = 7300
ca
cert_signing_key
crl_signing_key
EOF

  echo "INFO: generate cert..."
  certtool \
    --generate-self-signed \
    --p12-name "My Local Certificate Authority" \
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

show()
{
  info
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

