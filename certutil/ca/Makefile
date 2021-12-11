all : init ca
	
init :
	sh myca.sh init

ca :
	sh myca.sh ca

crt :
	sh myca.sh crt \
		-i ../server/myserver.csr \
		-o ../server/myserver.crt

clean :
	sh myca.sh destroy

