DOCPATH=$(PWD)/_build/default/_doc/_html

.PHONY : publish_doc
publish_doc : odoc
	@chmod 644 $(DOCPATH)/index.html &&\
	cp index.html $(DOCPATH)/ &&\
	git checkout gh-pages &&\
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
	@echo "Documentation generated at file://$(DOCPATH)/index.html"

.PHONY : odoc
odoc :
	@dune build @doc
