---
name: rest-to-mcp-generator
description: Generate a complete MCP project structure from a REST OpenAPI specification — entirely skill-driven. Use this skill when the user wants to convert an OpenAPI spec into MCP kind files, generate MCPTools from a REST API, create an MCP server from an OpenAPI spec, or produce the full set of MCP gateway assets (MCPTools, MCPServer, Invoke, Telemetry, FreeFlowPolicySequence, Quota, spec copy) directly in their project. Triggers on phrases like "generate MCP from my spec", "convert REST to MCP", "create MCP kind files", "make MCP tools from OpenAPI", "convert my project to MCP", "create an MCP server from this API", or any variation asking to convert or generate MCP assets from an OpenAPI/Swagger specification. Always triggers when user provides an OpenAPI spec path or a project folder and asks for MCP output.
---

# REST to MCP Generator

This skill converts a REST OpenAPI specification into a complete set of MCP kind files. It generates **7 files** in a `mcp/` subdirectory inside a new project.

## Step 0 — Create the Project

Use the `use_skill` tool to activate the **`project-manager`** skill:

```
use_skill("project-manager")
```
Always create a new project dont get list of existing projects or dont search in workspace too. Create a new project and have all assets inside mcp folder.
Ask the user for a project name if one has not been provided. Pass the project name to the skill and let it create the project. Do not create any directory or write any file yourself — the skill handles everything.

Once the skill completes it returns the created project's directory path. Assign this as `projectDir`:

```
projectDir  = <absolute path returned by project-manager>
outputDir   = <projectDir>/mcp
namespace   = last path segment of projectDir  (e.g. "petstore-project")
```

Create the `mcp/` output directory:

```bash
mkdir -p <outputDir>
```

**Do not proceed to Step 1 until the project is successfully created.**

---

## Step 1 — Locate the OpenAPI Spec

The user only needs to provide **one of**:
- A direct path to an OpenAPI spec file (`.yaml`, `.yml`, `.json`)
- The project directory — in which case scan for the spec automatically

**If a project directory is given**, search for the OpenAPI spec inside it:

```bash
find <project-dir> -maxdepth 3 \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
  | xargs grep -l "openapi:" 2>/dev/null | head -5
```

If multiple specs are found, list them and ask the user to pick one. If exactly one is found, use it silently.

From the resolved spec path, derive:

```
specAbsPath   = absolute path to spec file
```

> `projectDir`, `outputDir`, and `namespace` are already set from Step 0 — do not re-derive them from the spec path.

Read the spec with `read_file`. Parse it mentally — you need `info.title`, `info.version`, `info.description`, `servers[0].url`, and `paths`.

Derive names:

| Variable | Formula | Example |
|---|---|---|
| `apiTitle` | `spec.info.title` | `Pet Store` |
| `apiName` | lowercase, spaces/special→hyphen, collapse hyphens | `pet-store` |
| `version` | `spec.info.version \|\| 1.0` (never quoted) | `1.0` |
| `randomSuffix` | 5-char alphanumeric — generate one random string now | `ab3f9` |
| `toolName` | `<apiName>-mcp-tool-<rand>` | `pet-store-mcp-tool-ab3f9` |
| `serverName` | `<apiName>-mcp-server-<rand>` | `pet-store-mcp-server-ab3f9` |
| `invokeName` | `invoke-<rand>` | `invoke-ab3f9` |
| `telemetryName` | `telemetry-<rand>` | `telemetry-ab3f9` |
| `quotaName` | `<namespace>-quota-<rand>` | `petstore-project-quota-ab3f9` |
| `policySeqName` | `<namespace>-freeflowpolicysequence-<rand>` | `petstore-project-freeflowpolicysequence-ab3f9` |
| `specFileName` | `<apiName>-spec.yml` | `pet-store-spec.yml` |

Pre-calculate all `$ref` strings (format: `<namespace>:<name>:<version>`):

```
toolRef       = <namespace>:<toolName>:<version>
invokeRef     = <namespace>:<invokeName>:<version>
telemetryRef  = <namespace>:<telemetryName>:<version>
quotaRef      = <namespace>:<quotaName>:<version>
policySeqRef  = <namespace>:<policySeqName>:<version>
serverRef     = <namespace>:<serverName>:<version>
```

---

## Step 2 — Operation Selection

Use the `use_skill` tool to activate the **`operation-selector`** skill, passing `specAbsPath` as the spec file path. This skill owns the full selection flow — do not implement any part of it yourself:

```
use_skill("operation-selector")
```

The skill will:
1. Run the selector script in `--list` mode and present numbered operations to the user in chat
2. Wait for the user to reply with their chosen indexes (e.g. `1,3,4` or `all`)
3. Run the selector script in `--select-indexes` mode to resolve the final map

**Do not proceed to Step 3 until the skill returns.** Do not run the selector script directly, do not present the list yourself, and do not pre-select any operations.

Once the skill completes it returns a `selected` object — a JSON map of paths to arrays of lowercase HTTP methods:

```json
{
  "/pets": ["get", "post"],
  "/pets/{petId}": ["get"]
}
```

Assign this as `selectedOperations` and proceed to Step 3.

---

## Step 3 — Generate the MCPTools YAML

Build the `MCPTools` kind file by parsing the OpenAPI spec. The rules below are **canonical** — they match the behaviour of the production `OpenApiV3Adapter.toMcpTool()` implementation exactly. Follow every sub-rule; gaps cause runtime gateway failures.

---

### 3a — Tool name

Use `operationId` from `spec.paths[path][method].operationId` when present.

When absent, derive from method + last path segment:
- Split path by `/`, take the last non-empty segment
- Strip `{` and `}` from path parameters
- Combine as `<method>_<segment>` (underscore, lowercase)

> `GET /pets/{petId}` with no operationId → `get_petid`
> `POST /store/order` with no operationId → `post_order`

---

### 3b — Tool `title` field

Set `title` to `spec.paths[path][method].summary` **only when a summary exists**. Omit `title` entirely when summary is absent.

---

### 3c — Tool `description` field

Priority order (use the first that exists):
1. `spec.paths[path][method].description`
2. `spec.paths[path][method].summary`
3. Fallback: `"Make a <METHOD> request to <path>"`

> **Never substitute summary for description when description exists.** The production adapter (`initializeTool`) uses `op.description || op.summary || fallback`. This is the rule that fixes loginUser, findPetsByStatus, getPetById, and deletePet.

---

### 3d — Parameter resolution

**Path-level parameters** (`spec.paths[path].parameters`) are inherited by all operations on that path. Collect them first, then let operation-level parameters override by `name::in` key.

Resolve `$ref` parameters: if a parameter is `{ $ref: "#/components/parameters/SomeName" }`, look it up in `spec.components.parameters` and use the resolved object.

**Sources (in merge order — operation overrides path-level):**
1. Path-level: `spec.paths[path].parameters`
2. Operation-level: `spec.paths[path][method].parameters`

Ignore `parameters` as a path-item key (it is not an HTTP method). Only process operations for HTTP methods: `get`, `put`, `post`, `delete`, `options`, `head`, `patch`, `trace`.

---

### 3e — inputSchema properties: per-parameter structure

For **every** parameter (path, query, header) and every request body property, the property object MUST include **`x-parameter-location`** — this is the gateway's routing signal. Without it the gateway cannot distinguish query params from path params at runtime.

For each parameter:

```yaml
<paramName>:
  type: <type>                          # from schema; default "string" if empty schema
  description: <description>            # from param.description, else "<paramName> parameter"
  x-parameter-location: <param.in>      # "path" | "query" | "header" — ALWAYS PRESENT
  # copy ALL other schema fields that exist: enum, format, minimum, maximum, default, example, items, properties, required
```

**Type determination rules (match `determineParameterType`):**
- If `paramSchema` has an explicit `type` field → use it
- If `paramSchema` is empty `{}` → default to `"string"`
- If `paramSchema` has `properties` but no `type` → omit `type` (object is implied)
- If `paramSchema` has `items` and `type: "array"` → use `"array"`, and include `items`
- Boolean schema (literal `true`) → `"boolean"`

**`items` field** — when type is `array`, ALWAYS include `items`. Copy the full `items` sub-schema (inline any `$ref` from `components.schemas`):

```yaml
photoUrls:
  type: array
  items:
    type: string
  description: "URLs of pet photos"
  x-parameter-location: query
```

**`example` values** — copy `example` from the spec whenever it exists on a parameter or schema property. Include it in the property definition.

**Header parameters** — include ALL header parameters regardless of `required` status (the previous instruction to only include `required: true` headers was incorrect).

**`api_key` security header** — when the spec declares a security scheme of type `apiKey` with `in: header`, synthesise a header parameter for it even if it does not appear in the operation's `parameters` array:

```yaml
api_key:
  type: string
  description: "API key for authentication"
  x-parameter-location: header
```

Only add this when:
1. `spec.securitySchemes` (or `spec.components.securitySchemes`) contains a scheme with `type: "apiKey"` and `in: "header"`
2. AND that scheme is referenced in the operation's `security` array OR the global `security` array
3. AND no parameter with that name already exists in the parameter map

---

### 3f — Request body merging

If `spec.paths[path][method].requestBody` exists:

1. Prefer `content['application/json'].schema`; fall back to the first available content type's schema.
2. Inline all `$ref` schemas from `components.schemas` (handle cycles by returning `{}`).
3. Handle schema composition:
   - **`allOf`** — merge all sub-schemas: union their `properties`, union their `required` arrays
   - **`oneOf` / `anyOf`** — if the tool already has properties, wrap in `allOf: [ {existing-props-object}, {oneOf/anyOf-schema} ]`; otherwise assign the oneOf/anyOf directly to `inputSchema`
   - **object with properties** — merge each property into `inputSchema.properties`; if a property name clashes, prefix body property with `body_`
   - **primitive / non-object** — add a single `body` property with the inlined schema; mark `body` as required

4. Request body properties do **NOT** get `x-parameter-location` (they come from the request body, not a URL parameter).

5. Add body `required` fields from `requestBody.schema.required` to the `required` array.

---

### 3g — `category` sub-object on properties

When a schema property has `x-category` or a `category` property-object (with sub-fields `id` and/or `name`), preserve that structure exactly as it appears in the spec. Do not flatten nested objects — inline them via the `$ref` resolution pass.

Example — if the spec has:
```yaml
category:
  $ref: '#/components/schemas/Category'
```
and `Category` resolves to `{ type: object, properties: { id: { type: integer }, name: { type: string } } }`, emit:
```yaml
category:
  type: object
  properties:
    id:
      type: integer
    name:
      type: string
```

---

### 3h — `required` array

Collect `required` parameter names from:
- Parameters with `required: true`
- `requestBody.content[...].schema.required` array (body property names)

Omit the `required` key entirely if the resulting array is empty.

---

### 3i — x-api-binding

Every tool entry MUST have `x-api-binding`. The `api.$path` is added at this stage:

```yaml
x-api-binding:
  operationPath: /pets/{petId}
  operationMethod: GET          # uppercase
  api:
    $path: ./<specFileName>
```

---

### 3j — Full MCPTools structure

```yaml
kind: MCPTools
apiVersion: api.ibm.com/v1
metadata:
  name: <toolName>
  namespace: <namespace>
  version: <version>
  tags: []
  description: "<spec.info.description or ''>"
spec:
  tools:
    - name: <operationId or method_segment>
      title: "<summary>"            # only if summary exists; omit if absent
      description: "<description || summary || fallback>"
      inputSchema:
        type: object
        properties:
          petId:
            type: integer
            format: int64
            description: "Pet id to delete"
            example: 10
            x-parameter-location: path
          api_key:
            type: string
            description: "API key for authentication"
            x-parameter-location: header
          status:
            type: string
            description: "Status values for filter"
            enum:
              - available
              - pending
              - sold
            example: available
            x-parameter-location: query
          photoUrls:
            type: array
            items:
              type: string
            description: "Photo URLs"
            x-parameter-location: query
          category:
            type: object
            properties:
              id:
                type: integer
                format: int64
                example: 1
              name:
                type: string
                example: Dogs
            description: "Category of the pet"
          quantity:
            type: integer
            format: int32
            description: "Number of items in stock"
            example: 7
        required:
          - petId
      x-api-binding:
        operationPath: /pet/{petId}
        operationMethod: DELETE
        api:
          $path: ./pet-store-spec.yml
    # ... one entry per selected operation
```

Write to: `<outputDir>/<toolName>.yaml`

---

## Step 4 — Write the Spec Copy

Write the parsed spec content (as-is, preserving original format) to:

```
<outputDir>/<specFileName>
```

Use `write_file` with the raw content of the spec. Do not modify the spec content.

---

## Step 5 — Generate MCPServer

Write this file directly with `write_file` — no CLI schema needed; the shape is fixed and fully known.

### MCPServer — `<outputDir>/<serverName>.yaml`

The MCPServer shape is fully known. Generate exactly:

```yaml
kind: MCPServer
apiVersion: api.ibm.com/v1
metadata:
  name: <serverName>
  namespace: <namespace>
  version: <version>
  tags: []
spec:
  title: <apiTitle> MCP Server
  protocolVersion: V2025_11_25
  policy-sequence:
    - $ref: <policySeqRef>
  capabilities:
    tools:
      - $ref: <toolRef>
  quota:
    $ref: <quotaRef>
```

> Note: `metadata.version` is always the raw version string — never quoted. Write `version: 1.0` not `version: "1.0"`.
> MCPServer does **not** carry `labels.gatewayTypes`.

---

## Step 6 — Delegate Remaining Kind Files to Asset Manager

At this point MCPTools, spec copy, and MCPServer are written. Hand off to the `asset-manager` skill for the remaining **4 files**. **Pass the full context block below explicitly.**

---

### Handoff block to asset-manager

```
Generate the following 4 kind files using `apic schema get <Kind> --gateway lwgw` for each.
All files go into: <outputDir>

Pre-calculated names and $refs — use these exactly; they must match the already-written files:

  invokeName     = <invokeName>
  telemetryName  = <telemetryName>
  quotaName      = <quotaName>
  policySeqName  = <policySeqName>
  namespace      = <namespace>
  version        = <version>

  invokeRef      = <invokeRef>
  telemetryRef   = <telemetryRef>
  quotaRef       = <quotaRef>
  policySeqRef   = <policySeqRef>

Files to generate:

1. Invoke  →  <invokeName>.yaml
   - Kind: Invoke, gateway: lwgw
   - Prompt user for the backend endpoint URL (required — no default)
   - Default TLS profile: tls-client-profile-default:1.0.0
   - url expression: '<backendUrl>' & $pathAndQuery()
   - urlType: jsonata
   - timeout: 30, persistentConnections: false
   - decompressResponse: true, followRedirects: false, chunkedUpload: false

2. Telemetry  →  <telemetryName>.yaml
   - Kind: Telemetry, gateway: lwgw
   - spec: {} (empty object — the Telemetry spec has no fields)
   - labels.gatewayTypes: [nano]

3. Quota  →  <quotaName>.yaml
   - Kind: Quota
   - maxRequest: 1000
   - interval: 1m
   - extensions.dp-nano-gateway.spec.exceedAction: return429

4. FreeFlowPolicySequence  →  <policySeqName>.yaml
   - Kind: FreeFlowPolicySequence, gateway: lwgw
   - spec.main: [{ $ref: <invokeRef> }]
   - spec.monitoring: { $ref: <telemetryRef> }

For all files:
  metadata.namespace: <namespace>
  metadata.version: <version>
  metadata.tags: []
  labels.gatewayTypes: [nano]  (except Quota which does not carry this label)
```

---

## Step 7 — Summary

Once all 7 files are written, present a final summary:

```
✓ Generated 7 MCP files in <outputDir>/

  <specFileName>
  <toolName>.yaml                         MCPTools  (<N> tools)
  <serverName>.yaml                       MCPServer
  <invokeName>.yaml                       Invoke
  <telemetryName>.yaml                    Telemetry
  <quotaName>.yaml                        Quota
  <policySeqName>.yaml                    FreeFlowPolicySequence

$refs wired:
  MCPServer → MCPTools     <toolRef>
  MCPServer → PolicySeq    <policySeqRef>
  MCPServer → Quota        <quotaRef>
  PolicySeq → Invoke       <invokeRef>
  PolicySeq → Telemetry    <telemetryRef>
  MCPTools  → Spec         ./<specFileName>
```

---

## Step 8 Publish the mcp server

Publish the mcp server or publish the mcp project using skill called as publish-project

Use the `use_skill` tool to activate the **`publish-project`** skill:

```
use_skill("publish-project")
```

## Step 9 — Register MCP Server in Your Agent (optional)

Ask:

> "Would you like to register this MCP server in your AI coding assistant so you can call its tools directly?"

If the user says **No**, skip this step.

If the user says **Yes**, read [`agents.md`](./agents.md) in this skill's directory and follow the **Registration Procedure** defined there.

---

## Reference: Full output structure

```
<projectDir>/
└── mcp/
    ├── <apiName>-spec.yml
    ├── <apiName>-mcp-tool-<rand>.yaml
    ├── <apiName>-mcp-server-<rand>.yaml
    ├── invoke-<rand>.yaml
    ├── <telemetryName>.yaml
    ├── <namespace>-quota-<rand>.yaml
    └── <namespace>-freeflowpolicysequence-<rand>.yaml
```

## Reference: Kind file assets

These assets are provided for orientation.
For **MCPTools and MCPServer** the schema is fixed and built directly — no CLI needed.
For **Invoke, Telemetry, Quota, and FreeFlowPolicySequence** always retrieve the live schema via `apic schema get <Kind> --gateway lwgw` first.
These asset examples can be found at `examples/examples.md`