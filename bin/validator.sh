#!/bin/bash

# Get all STEMgraph repos
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repo list saved"

total=$(wc -l < repolist.txt.tmp)
valid=0
invalid=0

# Clear error log
> readme-errorlog.txt

echo "Validating metadata from $total repositories..."
echo ""

while read -r p; do
  # Extract JSON metadata from README
  meta=$(gh api /repos/STEMgraph/"$p"/contents/README.md -H 'Accept: application/vnd.github.v3.raw' 2>/dev/null | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p')

  # Validate metadata
  validation=$(echo "$meta" | jq -r --arg repo "$p" '
    def is_uuid: test("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    def has_prefix: test("^STEMgraph:") or test("^https?://");
    
    def validate_depends:
      if type == "string" then
        if has_prefix then "contains_prefix"
        elif is_uuid then true
        else "invalid_uuid_format"
        end
      elif type == "array" and length == 0 then true
      elif type == "array" and (.[0] == "AND" or .[0] == "OR") then
        if length < 2 then "and_or_without_operands"
        else
          [.[1:] | .[] | validate_depends] | 
          if any(. != true) then (map(select(. != true)) | .[0])
          else true
          end
        end
      elif type == "array" then
        [.[] | validate_depends] |
        if any(. != true) then (map(select(. != true)) | .[0])
        else true
        end
      else "unexpected_type"
      end;
    
    if . == null or . == "" then "\($repo): no valid JSON metadata found"
    elif .id | not then "\($repo): missing id field"
    elif .depends_on and ((.depends_on | type) != "array") then "\($repo): depends_on is not an array"
    elif .depends_on then
      (.depends_on | validate_depends) as $result |
      if $result == true then "ok"
      else "\($repo): depends_on validation failed - \($result)"
      end
    else "ok"
    end
  ')

  if [ "$validation" = "ok" ]; then
    ((valid++))
  else
    echo "$validation" >> readme-errorlog.txt
    ((invalid++))
  fi

done < repolist.txt.tmp

echo ""
echo "=========================================="
echo "Validation complete"
echo "Total repositories: $total"
echo "Valid: $valid"
echo "Invalid: $invalid"
if [ $invalid -gt 0 ]; then
  echo "Errors logged in: readme-errorlog.txt"
fi
echo "=========================================="

rm *.tmp
