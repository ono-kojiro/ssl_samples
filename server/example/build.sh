#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

toplevel=`git rev-parse --show-toplevel`


server_name="example"
server_base=`echo $server_name| tr '[:upper:]' '[:lower:]'`

fqdn="${server_base}.example.com"
ipaddr="192.168.1.13"

server_key="${server_base}.key"
server_crq="${server_base}.crq"
server_crt="${server_base}.crt"
server_p12="${server_base}.p12"

ca_crt="${toplevel}/ca-rsa/myrootca.crt"
ca_key="${toplevel}/ca-rsa/myrootca.key"

help() {
  cat - << EOS
usage : $0 <target>

  target
    key
    req
    crt

    all
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
    --no-text \
    --generate-privkey \
    --outfile ${server_key}
}

req()
{
  cat - << EOF > request.cfg
country = "JP"
organization = "Example Organization"
unit = "MyServerUnit"
cn = "${ipaddr}"
signing_key
encryption_key
tls_www_server
EOF

  certtool \
    --generate-request \
    --load-privkey ${server_key} \
    --template request.cfg \
    --outfile ${server_crq}

  rm -f request.cfg
}

crq_info()
{
  certtool --crq-info --infile ${server_crq}
}

crt()
{
  cat - << EOF > generate.cfg
dns_name = "${fqdn}"
dns_name = "localhost"
ip_address = "${ipaddr}"
ip_address = "127.0.0.1"
expiration_days = 3650
EOF

  certtool \
    --generate-certificate \
    --load-request ${server_crq} \
    --load-ca-certificate ${ca_crt} \
    --load-ca-privkey ${ca_key} \
    --template generate.cfg \
    --outfile ${server_crt}

  rm -f generate.cfg
  rm -f ${server_crq}
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

p12()
{
  openssl pkcs12 -export \
    -in $server_crt \
    -inkey $server_key \
    -out $server_p12 \
    -name $server_name \
    -passout pass:changeit
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

