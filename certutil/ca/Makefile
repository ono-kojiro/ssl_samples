all : init
	
init :
	sh myca.sh init

crt :
	sh myca.sh crt 192.168.0.98 127.0.0.1 

clean :
	sh myca.sh clean

mclean : destroy

destroy :
	sh myca.sh destroy

.PHONY : \
	all clean test db ca crt

