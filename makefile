VERSION=0.7
PKG=rbackup-$(VERSION)
SRCTAR=$(PKG).tar.gz

$(SRCTAR):
	git archive --format=tar.gz --prefix=$(PKG)/ -o $(SRCTAR) $(VERSION)

gittar: $(SRCTAR)
