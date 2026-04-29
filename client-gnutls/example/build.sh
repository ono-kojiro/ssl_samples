#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

client_name="example"
client_base=`echo ${client_name} | tr '[:upper:]' '[:lower:]'`

client_key="${client_base}.key"
client_csr="${client_base}.csr"
client_crt="${client_base}.crt"
client_p12="${client_base}.p12"

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
  certtool --generate-privkey \
    --no-text \
    --sec-param high \
    --key-type ed25519 \
    --outfile ${client_key}
}

req()
{
  cat - << EOF > request.cfg
organization = "Example Org"
unit = "Client"
cn = "filebeat"
tls_www_client
encryption_key
signing_key
EOF

  certtool --generate-request \
    --no-text \
    --load-privkey ${client_key} \
    --template request.cfg \
    --outfile ${client_csr}

  rm -f request.cfg
}

csr()
{
  req
}

csr_info()
{
  certtool --crq-info --infile ${client_csr}
}

crt()
{
  cat - << EOF > generate.cfg
organization = "Example Org"
unit = "Client"
cn = "filebeat"
tls_www_client
encryption_key
signing_key
EOF

  certtool --generate-certificate \
    --no-text \
    --load-request ${client_csr} \
    --load-ca-certificate ${ca_crt} \
    --load-ca-privkey ${ca_key} \
    --template generate.cfg \
    --outfile ${client_crt}
}

crt_info()
{
  certtool \
    --certificate-info --infile ${client_crt}
}

p12()
{
  cat - << EOF > p12.cfg
p12_name = "${client_name}"
p12_password = "changeit"
EOF

  certtool --to-p12 \
    --load-certificate ${client_crt} \
    --load-privkey ${client_key} \
    --template p12.cfg \
    --outfile ${client_p12}
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
  arg=`echo $arg | tr '-' '_'`
  num=`LANG=C type $arg 2>&1 | grep 'function' | wc -l`
  if [ "$num" -ne 0 ]; then
    $arg
  else
    "ERROR: $arg is NOT a shell function."
    exit 1
  fi
done

