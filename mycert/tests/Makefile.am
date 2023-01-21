LOG_DRIVER := env AM_TAP_AWK='$(AWK)' $(SHELL) \
               $(top_srcdir)/config/tap-driver.sh

TESTS = \
  00-dummy.sh \
  01-myca_init.sh \
  02-myserver_init.sh \
  03-myserver_csr.sh \
  04-myca_crt.sh \
  05-myserver_load.sh \
  06-myserver_save.sh

EXTRA_DIST = $(TESTS) config.bashrc

report :
	trs2junit -o junit_report.xml *.trs

clean-local :
	rm -rf MyCA MyServer
