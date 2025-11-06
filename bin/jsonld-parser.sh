#!/bin/bash

# Get all STEMgraph repos
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repo list saved as ./repolist.txt.tmp"

parsed=0
total=$(wc -l < repolist.txt.tmp)

# Create JSON-LD header 
cat > jsonld.tmp <<'EOF'
{
	"@context": {
		"schema": "http://schema.org/",
		"Exercise": "schema:LearningResource",
		"isBasedOn": "schema:isBasedOn",
		"stg": "https://github.com/STEMgraph/vocab#",
		"@base": "https://github.com/STEMgraph/"
	},
	"@graph": [
EOF

echo "Processing README files..."
> deps.txt.tmp

while read -r p; do
  # Extract JSON metadata from README
  meta=$(gh api /repos/STEMgraph/"$p"/contents/README.md -H 'Accept: application/vnd.github.v3.raw' | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p')

  echo "$meta" | jq -c --arg repo "$p" '
      def process_depends:
        if type != "array" or length == 0 then
          {isBasedOn: [], altDep: null}
        elif .[0] == "OR" then
          {isBasedOn: [], altDep: {("@type"): "stg:AlternativeDependency", ("stg:isBasedOnOptions"): .[1:]}}
        else
          # Check for nested OR
          [.[] | select(type == "array" and .[0] == "OR")] as $or_arrays |
          if ($or_arrays | length) > 0 then
            {isBasedOn: [.[] | select(type == "string")], altDep: {("@type"): "stg:AlternativeDependency", ("stg:isBasedOnOptions"): $or_arrays[0][1:]}}
          else
            {isBasedOn: ., altDep: null}
          end
        end;
      
      ((.id // $repo)) as $eid |
      (.depends_on | process_depends) as $deps |
      
      {("@id"): $eid, ("@type"): "Exercise"}
      | if ($deps.isBasedOn | length) > 0 then . + {isBasedOn: $deps.isBasedOn} else . end
      | if $deps.altDep then . + {("stg:hasAlternativeDependency"): $deps.altDep} else . end
  ' >> deps.txt.tmp
  ((parsed++))
done < repolist.txt.tmp

# Finalize JSON-LD
echo "Finalizing JSON-LD..."
sed 's/$/,/' deps.txt.tmp | sed '$s/,$//' >> jsonld.tmp
echo '  ]
}' >> jsonld.tmp

mv jsonld.tmp jsonld.json

echo ""
echo "=========================================="
echo "JSON-LD generated: ./jsonld.json"
echo "Successfully parsed: $parsed / $total repos"
echo "=========================================="

rm *.tmp
