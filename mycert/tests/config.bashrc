workdir=`pwd`

ca_name="MyCA"
ca_database=${workdir}/${ca_name}

server_name="MyServer"
server_database=${workdir}/${server_name}
server_addr=192.168.0.98

csrfile=`echo ${server_name}.csr | tr '[:upper:]' '[:lower:]'`
crtfile=`echo ${server_name}.crt | tr '[:upper:]' '[:lower:]'`

csrpath=${server_database}/${csrfile}
crtpath=${server_database}/${crtfile}

