VERSION=0.3
PKG=rbackup-$(VERSION)
SRCTAR=$(PKG).tar.gz

$(SRCTAR):
	git archive --format=tar.gz --prefix=$(PKG)/ -o $(SRCTAR) $(PKG)

gittar: $(SRCTAR)
