VERS = 0.2
V = rbackup-$(VERS)
CVSTAG = rbackup-`echo $(VERS) | tr . _`

cvstar:
	cvs export -r $(CVSTAG) -d $V rbackup
	tar cvf $V.tar $V
	gzip -v $V.tar
	rm -rf $V
