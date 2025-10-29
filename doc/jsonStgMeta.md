# JSON Structure: STEMgraph Repository Metadata

**Type:** `https://schema.org/LearningResource`

The metadata is placed on top of the exercise document between &lt;!-- and --&gt;.

## Properties

| Field | Type | Multiplicity | Description |
|-------|------|--------------|-------------|
| `id` | String | 1 | The exercise's UUID. |
| `depends_on` | String | 0-n | Exercises this one is based on. |
| `author` | String | 1-n | The exercise's author(s). |
| `first_used` | Date | 1 | The day the exercise was first used. |
| `keywords` | String | 0-n | Tags describing the exercise's content. |

### Example

```json
{
  "id": "f87c7e89-ece7-4c55-af54-16a3b3b7435f",
  "depends_on": [
    "AND",
    "302c98a7-cbea-435c-ada2-bbf7538429a2",
    "81f2e303-d35c-4857-9cb7-190e3c5372b0",
    [
      "OR",
      "718193ef-11a1-408d-af23-4b10c24d490d", 
      "99787eda-617a-4a68-b9a4-d60ec5c5c303"  
    ]
  ],
  "author": "Stephan Bökelmann",
  "first_used": "2025-06-05",
  "keywords": ["C Compiler", "Inline Assembly", "Syscall", "Objdump", "Locals and Globals", "Primitive Types"]
}
