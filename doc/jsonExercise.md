# JSON-LD Structure: Exercise

**Type:** `schema:LearningResource`  
**Context:** `https://schema.org` plus custom terms from `https://github.com/STEMgraph/vocab#`

## Properties

| Field | Type | Multiplicity | Description |
|-------|------|--------------|-------------|
| `@id` | String | 1 | The exercise's UUID. |
| `@type` | String | 1 | Always "schema:LearningResource". |
| `schema:isBasedOn` | String | 0-n | Exercises this one is based on. |
| `stg:hasAlternativeDependency` | Object | 0-n | Represents a set of alternative prerequisites. |

## `stg:AlternativeDependency` structure

| Field | Type | Multiplicity | Description |
|-------|------|--------------|-------------|
| `@type` | String | 1 | Always "stg:AlternativeDependency". |
| `stg:isBasedOnOptions` | String | 1-n | List of alternative prerequisite exercises. |

### Example

```jsonld
{
    "@context": {
        "schema": "https://schema.org",
        "stg": "https://github.com/STEMgraph/vocab#"
    },
    "@id": "f87c7e89-ece7-4c55-af54-16a3b3b7435f",
    "@type": "schema:LearningResource",
    "schema:isBasedOn": [
        "302c98a7-cbea-435c-ada2-bbf7538429a2",
        "81f2e303-d35c-4857-9cb7-190e3c5372b0"
    ],
    "stg:hasAlternativeDependency": {
        "@type": "stg:AlternativeDependency",
        "stg:isBasedOnOptions": [
            "718193ef-11a1-408d-af23-4b10c24d490d",
            "99787eda-617a-4a68-b9a4-d60ec5c5c303"
        ]
    }
}
