.PHONY : publish_doc

publish_doc :
	git checkout gh-pages && cp -R _build/default/_doc/_html/* . && rm -rf dream_html && git commit -a --amend -mdocs && g pf && git checkout -