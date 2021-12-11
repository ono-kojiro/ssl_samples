all :

init : init-ca init-server

init-ca :
	cd ca && sh myca.sh init
	cd ca && sh myca.sh ca

init-server :
	cd server && sh myserver.sh init

csr :
	cd server && sh myserver.sh csr

crt :
	cd ca && $(MAKE) crt

key :
	cd server && $(MAKE) import save

test : mclean init csr crt key

clean :
	cd ca     && sh myca.sh     clean
	cd server && sh myserver.sh clean

mclean : destroy

destroy :
	cd ca     && sh myca.sh     destroy
	cd server && sh myserver.sh destroy

