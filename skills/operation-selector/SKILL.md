---
name: operation-selector
description: >
  Supporting skill for rest-to-mcp-generator. Activated by that skill during
  Step 2 to let the user choose which OpenAPI/Swagger operations to convert into
  MCP tools. Presents every path+method as a numbered list, waits for the user's
  reply, and returns a `selected` JSON object (path → HTTP method array) for the
  parent skill to use as `selectedOperations`. Do not activate this skill
  directly — it is invoked by rest-to-mcp-generator via use_skill("operation-selector").
---

# Operation Selector

This is a **supporting skill** for `rest-to-mcp-generator`. It is activated during **Step 2** of that skill to collect the user's operation selection from an OpenAPI spec before MCP kind files are generated.

## When this skill is called

`rest-to-mcp-generator` calls this skill with a resolved `specAbsPath` already in context. The path is always available — do not ask for it again.

## Inputs

- `specAbsPath` — absolute path to the OpenAPI file (JSON, YAML, or YML), passed in from `rest-to-mcp-generator`

## Selection behavior

- Do not rely on terminal-only interactive prompts
- First produce a structured numbered list of operations by running the script in `--list` mode
- Present those options to the user in chat and **WAIT** for their response
- The user replies with a comma-separated list of option numbers such as `1,3,4` or the word `all`
- **CRITICAL**: Do NOT run `--select-indexes` until the user has explicitly provided their indexes
- Only after the user replies should the script be run again to resolve the selection

## Selection label rules

- If an operation has an `operationId` that is unique across the entire document, show the `operationId`
- Otherwise show `<HTTP-METHOD> <path>`
- Ignore non-operation keys under a path item: `summary`, `description`, `parameters`, `servers`

## Implementation

Run the Node.js script `select-operations.js` that ships alongside this skill.

### Step 1 — Produce numbered options

```bash
node select-operations.js <specAbsPath> --list
```

This prints JSON with:

- `openApiFile`
- `instructions`
- `options` — array of `{ index, label, method, path, operationId }`

The agent MUST:

1. Show the numbered options in a clear, readable format using the `label` values **exactly as returned** — do not reformat them
2. Ask the user which operations they want to convert into MCP tools
3. **WAIT** for the user to respond before doing anything else
4. Never proceed to Step 2 without explicit user input
5. If `options` is empty, tell the user there are no selectable operations and stop

Example output shape:

```json
{
    "openApiFile": "./example.yml",
    "instructions": "Select one or more operation numbers using a comma-separated list such as \"1,3,4\". Then run the script again with --select-indexes.",
    "options": [
        {
            "index": 1,
            "label": "getWeather",
            "method": "GET",
            "path": "/weather",
            "operationId": "getWeather"
        },
        {
            "index": 2,
            "label": "POST /pets",
            "method": "POST",
            "path": "/pets",
            "operationId": null
        }
    ]
}
```

### Step 2 — Resolve the user's selection

**CRITICAL**: Only run this after the user has provided their indexes.

```bash
node "<SCRIPT_PATH>" <specAbsPath> --select-indexes "<user-indexes>"
```

If the user said `all`, pass the full comma-separated list of all indexes (e.g. `"1,2,3"`).

This prints JSON with `selectedIndexes` and `selected`. Return the `selected` object to the calling skill — it maps paths to arrays of lowercase HTTP methods:

```json
{
    "selected": {
        "/weather": ["get"],
        "/pets": ["post"]
    }
}
```

If multiple methods are chosen for the same path they are grouped:

```json
{
    "selectedIndexes": [1, 2, 3],
    "selected": {
        "/pets": ["get", "post"],
        "/stores": ["delete"]
    }
}
```

## Return value

Return the `selected` object to `rest-to-mcp-generator` as `selectedOperations`. The parent skill assigns it and proceeds to Step 3.

## Notes

- If the file is invalid or has no `paths` object, treat it as having no selectable operations
- If duplicate indexes are entered, include each operation once
- Preserve ordering based on path order and HTTP method order in the source document
