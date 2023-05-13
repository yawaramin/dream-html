.PHONY : publish_doc

publish_doc :
	dune build @doc && git checkout gh-pages && cp -R _build/default/_doc/_html/* . && rm -rf dream_html && git commit -a --amend -mdocs && git push --force && git checkout -
