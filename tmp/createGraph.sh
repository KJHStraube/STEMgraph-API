#!/bin/bash

# gets metadata from STEMgraph repositories
# and creates a JSON-LD graph

# get names of all available repos
gh repo list STEMgraph --limit 200 --json name -q '.[].name' >allRepos.tmp
echo "fetched list of STEMgraph repo names..."

# now create the header of the final graph


# get README.md from each repo
while read -r p;
do
	echo "Metadata from Repository $p:"
#	curl -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/STEMgraph/$p/contents/README.md 2>README.err | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p'
	curl https://api.github.com/repos/STEMgraph/$p/contents/README.md 2>README.err | base64 -d | sed -n '/<!--/,/-->/p'
	echo
done <allRepos.tmp
