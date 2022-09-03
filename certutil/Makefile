all :

init : init-ca init-server

init-ca :
	$(MAKE) -C ca init

init-server :
	$(MAKE) -C server init

csr :
	$(MAKE) -C server csr

crt :
	$(MAKE) -C ca crt

key :
	$(MAKE) -C server import save

test : init csr crt key

clean :
	cd ca     && sh myca.sh     clean
	cd server && sh myserver.sh clean

mclean : destroy

destroy :
	cd ca     && sh myca.sh     destroy
	cd server && sh myserver.sh destroy

