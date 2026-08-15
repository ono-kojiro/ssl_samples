#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

toplevel=`git rev-parse --show-toplevel`

ret=0

if [ ! -e ".env" ]; then
  echo "ERROR: no .env file"
  ret=`expr $ret + 1`
else
  . ./.env
fi

if [ -z "$server_name" ]; then
  echo "ERROR: server_name not defined"
  ret=`expr $ret + 1`
fi

if [ -z "$addrs" ]; then
  echo "ERROR: addrs not defined"
  ret=`expr $ret + 1`
fi

if [ -z "$ca_crt" ]; then
  echo "ERROR: ca_crt not defined"
  ret=`expr $ret + 1`
fi

if [ -z "$ca_key" ]; then
  echo "ERROR: ca_key not defined"
  ret=`expr $ret + 1`
fi

if [ "$ret" -ne 0 ]; then
  exit $ret
fi

server_base=`echo $server_name| tr '[:upper:]' '[:lower:]'`

if [ -z "$fqdn" ]; then
  fqdn="${server_base}.example.com"
fi

if [ -z "$key_type" ]; then
  key_type="ed25519"
fi

if [ -z "$expiration_days" ]; then
  expiration_days="3550"
fi

server_key="${server_base}.key"
server_csr="${server_base}.csr"
server_crt="${server_base}.crt"
server_p12="${server_base}.p12"
server_jks="${server_base}.jks"


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

  p12
  jks
}

key()
{
  certtool \
    --generate-privkey \
    --no-text \
    --sec-param High \
    --key-type ${key_type} \
    --outfile ${server_key}
  chmod 640 ${server_key}
}

req()
{
  template=`mktemp` || exit

  cat - << EOF > ${template}
country = "JP"
organization = "Example Organization"
unit = "MyServerUnit"
signing_key
encryption_key
tls_www_server
EOF

  for addr in $addrs; do
cat - << EOF >> ${template}
    cn = "${addr}"
EOF
    break
  done

  certtool \
    --generate-request \
    --no-text \
    --load-privkey ${server_key} \
    --template ${template} \
    --outfile ${server_csr}

  rm -f ${template}
}

crq_info()
{
  certtool --crq-info --infile ${server_csr}
}

crt()
{
  template=`mktemp` || exit

  {
    for dns in ${fqdn} localhost; do
	  echo "dns_name = \"${dns}\""
    done

    for addr in $addrs 127.0.0.1; do
	  echo "ip_address = \"${addr}\""
    done
    
	echo "expiration_days = $expiration_days"
  
  } > ${template}

  certtool \
    --generate-certificate \
    --no-text \
    --load-request ${server_csr} \
    --load-ca-certificate ${ca_crt} \
    --load-ca-privkey ${ca_key} \
    --template ${template} \
    --outfile ${server_crt}

  rm -f ${template}
  rm -f ${server_csr}
}

info()
{
  certtool \
    --certificate-info \
    --infile ${server_crt}
}

show()
{
  info
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

jks()
{
  which keyttol
  if [ "$?" -eq 0 ]; then
    keytool -importkeystore \
      -srckeystore $server_p12 \
      -srcstoretype PKCS12 \
      -srcstorepass changeit \
      -destkeystore $server_jks \
      -deststoretype JKS \
      -deststorepass changeit
  else
    echo "INFO: no keytool command"
  fi
}

clean()
{
  rm -f *.csr *.crt *.key *.p12 *.jks
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

