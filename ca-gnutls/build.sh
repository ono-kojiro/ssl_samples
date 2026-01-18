#!/bin/sh

top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd $top_dir

ca_name="MyRootCA"

ca_base=`echo $ca_name | tr '[:upper:]' '[:lower:]'`

ca_key="${ca_base}.key"
ca_crt="${ca_base}.crt"
ca_cfg="${ca_base}.cfg"

infile=""
outfile=""
cfgfile=""

usage() {
  cat - << EOS
usage : $0 <target>

  target:
    key
    crt
EOS

}

key()
{
  if [ -z "$outfile" ]; then
    outfile="${ca_key}"
  fi

  certtool \
    --generate-privkey \
    --sec-param High \
    --key-type=ecdsa \
    --outfile ${outfile}
}

crt()
{
  if [ -z "$infile" ]; then
    infile="${ca_key}"
  fi

  if [ -z "$outfile" ]; then
    outfile="${ca_crt}"
  fi
  
  if [ -z "$cfgfile" ]; then
    cfgfile="${ca_cfg}"
  fi

  certtool \
    --generate-self-signed \
    --load-privkey ${infile} \
    --template ${cfgfile} \
    --outfile ${outfile}
}

info()
{
  certtool \
    --certificate-info --infile ${ca_crt}
}

clean()
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
    -c | --config)
      shift
      cfgfile=$1
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

