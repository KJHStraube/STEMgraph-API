# JSON-LD structure: Graph

**Type:** `JSON-LD`
**Context:** `doc/graphContext.json`

## Properties

| Field | Type | Multiplicity | Description |
|-------|------|--------------|-------------|
| `@id` | String | 1 | The URL where the graph was generated. |
| `generatedBy` | Organization | 1 | Who created this specific graph from raw data. |
| `generatedAt` | DateTime | 1 | The timestamp when the graph was created. |

## structure of *generatedBy*

| Field | Type | Multiplicity | Description |
|-------|------|--------------|-------------|
| `@type` | String | 1 | Always "schema:Organization". |
| `schema:name` | String | 1 | The creator's name. |
| `schema:url` | String | 1 | The creator's homepage. |

### Example

```jsonld
{
  "@id": "https://raw.githubusercontent.com/KJHStraube/STEMgraph-API/refs/heads/main/doc/graphExample.json",
  "generatedBy": {
    "@type": "schema:Organization",
    "schema:name": "STEMgraph API",
    "schema:url": "https://github.com/KJHStraube/STEMgraph-API/"
  },
  "generatedAt": "2025-11-07T15:35:00"
}

