all : init ca
	
init :
	sh myca.sh init

ca :
	sh myca.sh ca

crt :
	sh myca.sh crt 

clean :
	sh myca.sh clean

mclean : destroy

destroy :
	sh myca.sh destroy

.PHONY : \
	all clean test init ca crt

