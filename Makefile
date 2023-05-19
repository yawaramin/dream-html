DOCPATH=$(PWD)/_build/default/_doc/_html

.PHONY : publish_doc
publish_doc : odoc
	@git checkout gh-pages && cp -R $(DOCPATH)/* . && rm -rf dream_html && git commit -a --amend -mdocs && git push --force && git checkout -

.PHONY : doc
doc : odoc
	@echo "Documentation generated at file://$(DOCPATH)/index.html"

.PHONY : odoc
odoc :
	@dune build @doc
