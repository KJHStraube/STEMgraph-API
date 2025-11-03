#!/bin/bash

#PREPERATION
# get all STEMgraph repos and save names as list
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

echo "jsonld.tmp file created with header"

# loop through list and get / decode each README.md
echo "getting and decoding README.md files from Repolist"


# PREPROCESSING

while read -r p; do

  # Extract JSON metadata from README
  meta=$(gh api /repos/STEMgraph/"$p"/contents/README.md -H 'Accept: application/vnd.github.v3.raw' | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p')

  # PROCESSING
  echo "$meta" | jq -c --arg repo "$p" '
      
      # Process depends_on array into isBasedOn and hasAlternativeDependency
      def process_depends:
        if type == "array" and length == 0 then
          {isBasedOn: [], altDep: null}
        elif type == "array" and .[0] == "AND" then
          {
            isBasedOn: [.[1:] | .[] | select(type == "string")],
            altDep: (
              [.[1:] | .[] | select(type == "array" and .[0] == "OR")] |
              if length > 0 then
                .[0] | {
                  ("@type"): "stg:AlternativeDependency",
                  ("stg:isBasedOnOptions"): .[1:]
                }
              else null
              end
            )
          }
        elif type == "array" and .[0] == "OR" then
          {
            isBasedOn: [],
            altDep: {
              ("@type"): "stg:AlternativeDependency",
              ("stg:isBasedOnOptions"): .[1:]
            }
          }
        elif type == "array" then
          {
            isBasedOn: .,
            altDep: null
          }
        else
          {isBasedOn: [], altDep: null}
        end;
      
      ((.id // $repo)) as $eid |
      
      if .depends_on then
        # Process dependencies
        (.depends_on | process_depends) as $deps |
        
        # Output main Exercise node
        (
          {
            ("@id"): $eid,
            ("@type"): "Exercise"
          } + 
          (if ($deps.isBasedOn | length) > 0 then {isBasedOn: $deps.isBasedOn} else {} end) +
          (if $deps.altDep then {("stg:hasAlternativeDependency"): $deps.altDep} else {} end)
        ),
        # Output Exercise nodes for all referenced UUIDs
        (($deps.isBasedOn + (if $deps.altDep then $deps.altDep."stg:isBasedOnOptions" else [] end)) | unique | .[] | {("@id"): ., ("@type"): "Exercise"})
      else
        # No dependencies
        {("@id"): $eid, ("@type"): "Exercise"}
      end
  ' >> deps.txt.tmp
  ((parsed++))

done < repolist.txt.tmp


#POSTPROCESSING
# Finalize JSON-LD
echo "Finishing the jsonld.tmp file"
# Remove duplicates, add commas, and append to jsonld
sort -u deps.txt.tmp | sed 's/$/,/' | sed '$s/,$//' >> jsonld.tmp

echo '  ]
}' >> jsonld.tmp

# Merge duplicate Exercise entries (combine isBasedOn arrays and hasAlternativeDependency)
jq '.["@graph"] |= (
  group_by(."@id") | 
  map(
    if length > 1 then
      reduce .[] as $item ({}; 
        . + $item | 
        if .isBasedOn and $item.isBasedOn then
          .isBasedOn = ([.isBasedOn, $item.isBasedOn] | add | unique)
        else . end
      )
    else .[0] 
    end
  )
)' jsonld.tmp > jsonld.json

echo ""
echo "=========================================="
echo "JSON-LD generated: ./jsonld.json"
echo "Successfully parsed: $parsed / $total repos"
echo "=========================================="

rm *.tmp
