DOCPATH=$(PWD)/_build/default/_doc/_html
ODOC_SUPPORT=$(DOCPATH)/odoc.support

.PHONY : publish_doc
publish_doc : odoc
	@git checkout gh-pages &&\
	cp -R $(DOCPATH)/* . &&\
	git add . &&\
	git commit --amend -mdocs &&\
	git push --force &&\
	git checkout -

.PHONY : publish_opam
publish_opam :
	@dune-release distrib && dune-release publish distrib && dune-release opam pkg -y && dune-release opam submit -y

.PHONY : doc
doc : odoc
	@echo "Documentation generated at file://$(DOCPATH)/dream-html/Dream_html/index.html"

.PHONY : odoc
odoc :
	@dune build @doc &&\
	chmod 644 $(DOCPATH)/index.html &&\
  /bin/rm -rf $(ODOC_SUPPORT) &&\
	cp index.html $(DOCPATH)/ &&\
	cp -R odoc.support $(ODOC_SUPPORT)

