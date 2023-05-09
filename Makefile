.PHONY : publish_doc

publish_doc :
	g co gh-pages && cp -R _build/default/_doc/_html/* . && rm -rf dream_html && g ci -a --amend -mdocs && g pf && g co -
