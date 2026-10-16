---
name: test-generator
description: Generate and execute API tests for IBM API Connect / APIC projects. Use this skill when users want to create tests for published APIs, generate test cases from OpenAPI specifications, create assertions for API responses, set up test environments with authentication, or execute tests using the apic CLI. Triggers on any mention of IBM API Connect or API Connect (APIC) in the context of testing. Also triggers when users mention "generate tests", "create API tests", "test my API", "test generation", "create assertions", "test environment", "run tests", or provide OpenAPI/Swagger specifications for testing.
---

# API Connect Test Generator

Generate test suites for IBM API Connect projects from OpenAPI specifications and execute them using the `apic` CLI.

## Prerequisites

**Node.js version 24 is required.** Verify the CLI before any operation by running:

```bash
apic schema list
```

Interpret the result as follows:

| Result | Meaning | Action |
|--------|---------|--------|
| Returns a list of assets and versions | `apim-cli` installed correctly | ✅ Proceed |
| `error: unknown command 'schema'` | Old `apic` toolkit installed — `schema` command not available | Run `apic version --debug`; if output identifies as _APIConnect toolkit client_, ask the user to upgrade to the latest toolkit — **HARD STOP** until they confirm the upgrade, then re-run `apic schema list` |
| `error: unknown command 'version'` | `apim-cli` present but outdated | Run `npm i -g @apistudio/apim-cli@latest`, then re-run `apic schema list` |
| `command not found: apic` | CLI not installed | Run `npm i -g @apistudio/apim-cli@latest`, then re-run `apic schema list` |

If `apic schema list` does not return a valid asset list after following the steps above — **HARD STOP**. Do not proceed or offer alternative methods. Ask the user to resolve the CLI issue first.

## Core Principles

- **Basic tests only**: happy path (200, 201) and common errors (400, 404). No edge cases, no multi-step workflows.
- **No ID-based GET/DELETE tests**: `GET /pet/10` is non-deterministic. Only collection GETs (`GET /pets`) and POST/PUT operations. If the spec has no collection GET endpoint (only `GET /resource/{id}`), do not add any GET test. Note in the test report that read-path coverage is absent because no collection endpoint exists — this is expected and acceptable.
- **Schema-driven**: extract everything from the OpenAPI spec — endpoints, payloads, response schemas.
- **Assertion reuse**: create shared assertion files per status/scenario (5–7 files covers most APIs).
- **Never modify any file after a test failure without user approval** — analyse the failure, identify the root cause, propose the exact fix as a before/after diff, and wait for explicit approval before touching anything. This applies even if the user has given general permission at the start of the session — each proposed change requires its own approval.
- **Never create `test-results.json`** — always write a markdown summary; generate HTML/PDF only if the user explicitly requests a detailed report.
- **Never use spec server URLs**: only use endpoints from `apic publish` responses or explicit user input.

## Workflow

### Step 1 — Locate the OpenAPI Specification

```bash
find <project-path> -name "*.yaml" -o -name "*.yml" -o -name "*.json" | grep -i "spec\|swagger\|openapi"
```

Extract: endpoints, HTTP methods, request/response schemas, authentication schemes, response codes.

### Step 2 — Retrieve CLI Schemas

Always retrieve official schemas before generating any file:

```bash
apic schema get test --gateway common
apic schema get assertion --gateway common
apic schema get environment --gateway common
```

Never generate files from memory — the CLI schema is the source of truth.

### Step 3 — Generate Environment File

See [`references/environment-instructions.md`](references/environment-instructions.md) for the full schema and variable rules.

Key points: extract auth variables from `securitySchemes`, mark secrets with `isSecret: true`, leave values empty.

**Client-credentials policy detection:** Before generating the environment file, check whether the project's policy sequence contains any security policies (`ExtractIdentity`, `Authenticate`, `Authorize`, or `IAM`).
- **DataPower Nano Gateway** uses `ExtractIdentity`, `Authenticate`, and `Authorize`.
- **webMethods API Gateway** uses `IAM` for identity and client credential validation.

If any of these policies are present, the API enforces client-credential-based authentication. In that case:
- **Ask the user for their `client_id` and `client_secret`** before proceeding: _"This API uses an Extract Identity / Authenticate / Authorize policy sequence. To run the tests you will need a valid `client_id` and `client_secret`. Please provide them (or the environment variable names that hold them)."_
- Add both `client_id` and `client_secret` (both `isSecret: true`) to the environment file in addition to any variables derived from `securitySchemes`.
- **Important — credential visibility rules in API Manager:**
  - The `client_secret` is shown **only once**, at the moment the application is created. It cannot be retrieved from the UI afterwards.
  - The `client_id` can be viewed again at any time from the application's subscription in API Manager.
- **Do not suggest any other source** (such as a Developer Portal or external system) — only refer the user to API Manager.

### Step 4 — Generate Assertion Files

See [`references/assertion-instructions.md`](references/assertion-instructions.md) for the Key ENUM, Action ENUM, and the three enforced rules.

### Step 5 — Generate Test File

See [`references/test-instructions.md`](references/test-instructions.md) for the full schema, `$ref` vs `$endpoint` usage, and request rules.

Key points:
- `assertions` is always an array (`- $ref: ...`), even for a single reference
- No `expressions` field exists in test files
- **Always use `spec.api.$endpoint` for the gateway URL — never `spec.api.$ref` in test files**
- **Client-credentials headers:** When the project uses `ExtractIdentity`, `Authenticate`, `Authorize`, or `IAM` policies, check the policy configuration for custom client ID / secret header names. If custom names are defined (e.g. `X-Client-ID`), use those; otherwise, default to `X-IBM-Client-Id` and `X-IBM-Client-Secret` on **every request** in the test file, referencing `${client_id}` and `${client_secret}`.
- **OWASP policy compatibility rules:**
  - **BOPLA / Redact / DataMasking:** If `Redact` or `DataMasking` policies are present in the policy sequence, exclude redacted response fields from `haveProperty` assertions and from the `required` array in `validateSchema` JSON strings so that stripped fields do not trigger false test failures.
  - **API8 Security Headers:** When `Set` policies add security response headers (e.g., `X-Frame-Options`, `Strict-Transport-Security`, `Content-Security-Policy`), generate matching `responseHeaders` assertions to verify header injection.
  - **SSRF / URL fields:** Use valid, well-formed URLs (e.g., `https://api.example.com/callback`) in sample payloads instead of placeholder strings like `"string"` to satisfy SSRF allowlist policies.

### Step 6 — Validate and Save

Validate against CLI schemas, then write files:

```
<project-path>/tests/<api-name>-test.yaml
<project-path>/tests/assertions/<code>-<scenario>.yml
<project-path>/tests/environments/<test-name>-environment.yml
```

Checklist: `$ref` format is `namespace:name:version`, variables use `${var}`, `assertions` is an array.

Before saving any assertion file, run:
```bash
grep -n 'responseStatus' <file>
```
If any line shows `responseStatus:` followed by a quoted value (e.g., `"200"` or `'200'`), fix it to a bare integer before saving. Do not skip this check.

### Step 7 — Confirm Endpoint with User

**`--endpoints` is the base URL passed to `apic test` that determines where the tests are executed against.** Always confirm this value before running.

Decision logic:
1. **If a publish/deploy occurred earlier in this conversation**, extract the endpoint from that response and present it to the user: _"I'll use `<extracted-url>` as the test endpoint — is that correct?"_ Wait for confirmation before proceeding.
2. **If no endpoint is known from context**, ask the user: _"What is the base URL of the deployed API to run the tests against?"_

Valid endpoint sources:
- Endpoint returned in the `apic deploy` / `apic publish` response from earlier in the conversation
- URL explicitly provided by the user

### Step 8 — Execute Tests

```bash
apic test <ProjectName> \
  --names <namespace>:<test-name>:<version> \
  --localDir . \
  --endpoints http://gateway:port/api/path \
  --env bearer_token=${BEARER_TOKEN}
```

- `--localDir` is the root of the API Connect project — defaults to `.` (current directory)
- `--names` references the **test file's** `namespace:name:version` — not the API file
- Always use the base URL — do not append resource paths (e.g., `/pet`)
- Example: `http://gateway:9090/api/petstore/1.0` ✓ — `http://gateway:9090/api/petstore/1.0/pet` ✗
- Retry up to 3 times (5s delay) on connection timeout — pods may need to warm up. After 3 failed retries, stop and report the connection error to the user — do not attempt further fixes or re-runs.

**When the project uses Extract Identity / Authenticate / Authorize / IAM policies (and/or token auth)**, pass all required environment variables in a single comma-separated `--env` flag:

```bash
# Example with client credentials and bearer token together:
apic test <ProjectName> \
  --names <namespace>:<test-name>:<version> \
  --localDir . \
  --endpoints http://gateway:port/api/path \
  --env client_id=${CLIENT_ID},client_secret=${CLIENT_SECRET},bearer_token=${BEARER_TOKEN}
```

If the user has not yet provided these values, **stop and ask before running**: _"This project requires a `client_id` and `client_secret` to authenticate. Please provide them so they can be passed to `--env`."_

### Step 9 — Interpret Results and Report

Parse the `apic test` output for total passed/failed counts and per-assertion details.

**Reporting rules (follow exactly):**
1. Always write a markdown summary to `<project-path>/tests/reports/test-report-<timestamp>.md`, where `<timestamp>` uses the format `YYYYMMDD-HHmmss` (e.g., `20240115-103000`).
2. Never create `test-results.json` — not as a side output, not as an intermediate file, not at all.
3. If the user explicitly asks for a detailed report, generate HTML or PDF using `scripts/generate-pdf-report.js`. Do not produce HTML/PDF proactively.

**When tests fail — mandatory approval gate:**
1. Stop immediately — do not edit any file.
2. Classify the failure using [`references/debugging.md`](references/debugging.md) before proposing any change.
3. Propose the exact change you would make (show the before/after YAML diff).
4. Wait for the user to explicitly approve that specific change before modifying anything.

### Step 10 — Iterate

Only apply fixes after the user approves each proposed change. Re-run after applying and report the new results using the same markdown summary format.

## Reference Files

| File | When to read |
|------|-------------|
| [`references/environment-instructions.md`](references/environment-instructions.md) | Creating environment files |
| [`references/assertion-instructions.md`](references/assertion-instructions.md) | Creating assertion files |
| [`references/test-instructions.md`](references/test-instructions.md) | Creating test files |
| [`references/debugging.md`](references/debugging.md) | Classifying test failures before proposing any fix |
| [`examples/environments/environment-bearer.yml`](examples/environments/environment-bearer.yml) | Environment template — bearer token / API key auth |
| [`examples/environments/environment-client-credentials.yml`](examples/environments/environment-client-credentials.yml) | Environment template — client credentials (extract-identity / authenticate / authorize) |
| [`examples/assertions/`](examples/assertions/) | Assertion YAML templates (200-success, 201-created, 400, 401, 404, resource-specific) |
| [`examples/test-patterns/`](examples/test-patterns/) | Test YAML templates (crud, query-params, external-endpoint) |
| [`examples/complete-workflows/`](examples/complete-workflows/) | Full worked examples — PetStore (bearer token) and client-credentials flow (extract-identity / authenticate / authorize) |

## Integration with Other Skills

Typical workflow: `asset-manager` → `build-project` → `publish-project` → **capture & confirm endpoint** → generate tests → execute → review.
