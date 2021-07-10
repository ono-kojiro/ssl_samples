#!/bin/sh

set -e

es_home=/usr/share/elasticsearch   
certutil=$es_home/bin/elasticsearch-certutil
es_path_conf=/etc/elasticsearch

help() {
	echo "usage : $0 <target>"
	echo " target"
	echo "   ca     create ca"
	echo "   crt    create crt"
	echo ""
	echo "   clean  remove database"
}

clean() {
  :
}

ca() {
	sudo $certutil ca \
		--out      /etc/elasticsearch/elastic-stack-ca.p12 \
		--pass ''
	sudo chmod 660 /etc/elasticsearch/elastic-stack-ca.p12
}

crt() {
	sudo $certutil cert \
		--ca  /etc/elasticsearch/elastic-stack-ca.p12 \
		--ca-pass '' \
		--out /etc/elasticsearch/elastic-cert.p12 \
		--pass ''
	sudo chmod 660 /etc/elasticsearch/elastic-cert.p12
}

clean() {
	sudo rm -f /etc/elasticsearch/elastic-stack-ca.p12
	sudo rm -f /etc/elasticsearch/elastic-cert.p12
}

ls() {
	sudo ls -l /etc/elasticsearch/
}

for target in $@; do
	type $target | grep 'function' > /dev/null 2>&1
	res=$?
	if [ "$res" = "0" ]; then
		$target
	else
		echo "target '$target' is not a function."
		exit 1
	fi
done

