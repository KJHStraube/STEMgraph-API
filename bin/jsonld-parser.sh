#!/bin/bash

# Get all STEMgraph repos
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repo list saved as ./repolist.txt.tmp"

parsed=0
total=$(wc -l < repolist.txt.tmp)

# Get current timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")

# Create JSON-LD header with root-level metadata
cat > jsonld.tmp <<EOF
{
  "@context": {
    "@base": "https://github.com/STEMgraph/",
    "@language": "en",
    "@version": 1.1,
    "schema": "https://schema.org/",
    "xsd": "https://www.w3.org/2001/XMLSchema#",
    "owl": "https://www.w3.org/2002/07/owl#",
    "Exercise": "schema:LearningResource",
    "Person": "schema:Person",
    "dependsOnAlternatives": {
      "@id": "owl:Class",
      "@type": "@id"
    },
    "learningResourceType": {
      "@id": "schema:learningResourceType",
      "@type": "xsd:string"
    },
    "author": {
      "@id": "schema:author",
      "@type": "@id"
    },
    "name": {
      "@id": "schema:name",
      "@type": "xsd:string"
    },
    "publishedAt": {
      "@id": "schema:datePublished",
      "@type": "xsd:date"
    },
    "keywords": {
      "@id": "schema:keywords",
      "@type": "xsd:string"
    },
    "teaches": {
      "@id": "schema:teaches",
      "@type": "xsd:string"
    },
    "dependsOn": {
      "@id": "schema:competencyRequired",
      "@type": "@id"
    },
    "oneOf": {
      "@id": "owl:oneOf",
      "@container": "@list",
      "@type": "@id"
    },
    "generatedBy": {
      "@id": "schema:sdPublisher",
      "@type": "@id"
    },
    "generatedAt": {
      "@id": "schema:sdDatePublished",
      "@type": "xsd:dateTime"
    }
  },
  "@id": "https://raw.githubusercontent.com/STEMgraph/STEMgraph-API/main/jsonld.json",
  "generatedBy": {
    "@type": "schema:Organization",
    "schema:name": "STEMgraph API",
    "schema:url": "https://github.com/STEMgraph/"
  },
  "generatedAt": "$timestamp",
  "@graph": [
EOF

echo "Processing README files..."
> deps.txt.tmp

while read -r p; do
  # Extract full README content
  readme=$(gh api /repos/STEMgraph/"$p"/contents/README.md -H 'Accept: application/vnd.github.v3.raw' 2>/dev/null)
  
  # Skip if README not found
  if [ -z "$readme" ]; then
    continue
  fi
  
  # Extract JSON metadata from README
  meta=$(echo "$readme" | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p')
  
  # Extract first heading (teaches)
  teaches=$(echo "$readme" | grep -m 1 '^# ' | sed 's/^# //')

  echo "$meta" | jq -c --arg repo "$p" --arg teaches "$teaches" '
      def process_depends:
        if type != "array" or length == 0 then
          {dependsOn: [], altDep: null}
        elif .[0] == "OR" then
          {dependsOn: [], altDep: {("@type"): "dependsOnAlternatives", oneOf: .[1:]}}
        else
          # Check for nested OR
          [.[] | select(type == "array" and .[0] == "OR")] as $or_arrays |
          if ($or_arrays | length) > 0 then
            {dependsOn: ([.[] | select(type == "string")] + [{("@type"): "dependsOnAlternatives", oneOf: $or_arrays[0][1:]}]), altDep: null}
          else
            {dependsOn: ., altDep: null}
          end
        end;
      
      # Extract values from input
      ((.id // $repo)) as $eid |
      (.depends_on | process_depends) as $deps |
      .author as $author |
      .first_used as $published |
      .keywords as $keys |
      
      # Build output object
      {("@id"): $eid, ("@type"): "Exercise", learningResourceType: "Exercise"}
      | if ($deps.dependsOn | length) > 0 then . + {dependsOn: $deps.dependsOn} else . end
      | if $author then . + {author: [{("@type"): "Person", name: $author}]} else . end
      | if $published then . + {publishedAt: $published} else . end
      | if $keys then . + {keywords: $keys} else . end
      | if ($teaches != "") then . + {teaches: $teaches} else . end
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
