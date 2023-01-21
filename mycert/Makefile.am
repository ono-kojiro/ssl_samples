ACLOCAL_AMFLAGS = -I config

bin_SCRIPTS = myca myserver

EXTRA_DIST = myca myserver debian

SUBDIRS = tests

deb :
	sh mkdebpkg.sh ctrl --package $(PACKAGE_NAME) --version $(PACKAGE_VERSION)
	$(MAKE) dist
	cp -f $(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz \
		$(PACKAGE_NAME)_$(PACKAGE_VERSION).tar.gz
	sh mkdebpkg.sh dsc  --package $(PACKAGE_NAME) --version $(PACKAGE_VERSION)

	rm -rf ./debbuild
	echo "extract source ..."
	dpkg-source -x $(PACKAGE_NAME)_$(PACKAGE_VERSION).dsc ./debbuild
	echo "build package ..."
	cd debbuild && \
		dpkg-buildpackage -rfakeroot -b -us -uc

report :
	cd tests && $(MAKE) report

