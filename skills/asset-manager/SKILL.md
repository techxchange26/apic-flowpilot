---
name: asset-manager
description: Create and manage IBM API Connect / APIC assets — APIs, Products, Plans, Policies, Routes — using the apic CLI. Retrieves JSON schemas dynamically for DataPower Nano Gateway or webMethods API Gateway. Trigger on creating/generating/scaffolding APIs, policies, routes, products, or plans; adding functionality (auth, rate limiting, caching, logging, transforms); onboarding a repo or codebase onto API Connect ("manage this repo on API Connect", "convert this repo to an API Connect project", "onboard this service", "turn this codebase into an API"); converting between gateway types (DataPower Nano Gateway ↔ webMethods API Gateway); OWASP requests ("scan for OWASP", "API security scan", "find vulnerabilities", "redact sensitive data", "protect admin endpoints", "deny delete for regular users"). Always trigger when users mention API Connect or APIC alongside any asset, project, or security action.
---

# API Connect Asset Manager

This skill manages the creation and generation of IBM API Connect assets using the `apic schema` CLI commands. The CLI provides JSON schemas for all asset types, which are used to generate valid YAML/JSON asset files.

## CRITICAL: Schema Usage

**Always retrieve the actual schema from the CLI before generating any asset — without exception:**

```bash
apic schema get <AssetKind> --gateway <gateway-type>
```

This rule is absolute and applies to **every** asset kind — `Invoke`, `Telemetry`, `Quota`, `FreeFlowPolicySequence`, `API`, `Product`, `Plan`, and all others. There are no exceptions, even when a handoff block, context message, or earlier instruction provides field hints or suggested values.

**The schema is the authority.** Field hints in handoff blocks are starting-point suggestions only. The CLI schema determines:
- Which fields are valid for the target gateway type
- Which fields are required vs. optional
- The correct types, formats, and nesting of every property

**Never skip the schema fetch because you think you already know the structure.** Asset schemas differ between gateway types and versions. Generating an asset without first retrieving its schema — or copying a structure from an example, a previous run, or your training data — will produce invalid output that fails at runtime.

The workflow is always:
1. `apic schema get <AssetKind> --gateway <gateway-type>`
2. Read the schema output
3. Map the collected field values onto the schema structure
4. Generate the asset YAML

Examples and field hints shown in this document are illustrative only — they must never be used as templates in place of the live schema.

## Prerequisites

Requires Node.js 24. **Skip entirely if `SESSION_CLI_VERIFIED=true`.**

If not yet verified, run `apic schema list` once:

| Result | Action |
|--------|--------|
| Returns asset list | ✅ Set `SESSION_CLI_VERIFIED=true`, proceed immediately |
| `error: unknown command 'schema'` | Run `apic version --debug`; if _APIConnect toolkit client_, ask user to upgrade — **HARD STOP** until confirmed, then re-run |
| `error: unknown command 'version'` | `npm i -g @apistudio/apim-cli@latest`, then re-run |
| `command not found: apic` | `npm i -g @apistudio/apim-cli@latest`, then re-run |

**HARD STOP** if `apic schema list` still fails after remediation.

## Core Principles

1. **Schema-driven** — Retrieve every schema from CLI before generating any asset
2. **Reference-based** — Assets link to each other via `$ref: <namespace>:<name>:<version>`
3. **Gateway-specific** — DataPower Nano Gateway and webMethods API Gateway have different available assets and policy sequences
4. **Smart defaults** — Three tiers govern every field across every asset:
   - **Always default silently** — fields with a universally safe, unambiguous value (e.g., `timeout`, `version`, `urlType`, TLS Client Profile). Apply without asking; list them in the confirmation summary. Never populate optional blocks like `cache` unless the user explicitly requests them.
   - **Always prompt explicitly** — fields where no safe default exists and the value is required and context-specific (e.g., endpoint URL, asset names, custom identifiers). Never guess, infer, or default these. Collect all such missing fields in a **single consolidated prompt**, not one at a time.
   - **Confirmation summary before executing** — after collecting all inputs, display a concise summary of every value that will be used (including which were defaulted) and wait for the user to confirm before running any `apic` commands or writing any files.
5. **Mandatory metadata** — Every asset MUST include `namespace` (defaults to project name) and `tags` (1–2 business-domain tags, e.g. `["payments", "retail"]`). Never use kind names or gateway names as tags.
6. **Version consistency** — API `metadata.version` MUST match OpenAPI `info.version`. Always quote versions (`"1.0"` not `1.0`).

## Understanding References

### `$ref` — Asset References
Links to another IBM API Connect asset: `<namespace>:<name>:<version>`

### `$path` — File References
Links to an external file. The path is **always relative to the file that contains the `$path` reference**, not relative to the project root.

**Supported formats:** `.json`, `.yaml`, `.yml`, `.wsdl`, `.zip`

**Snippets (illustrative — always generate from CLI schema):**

```yaml
# API asset saved at <project>/apis/<api-name>.yaml
# Spec saved at     <project>/spec/<api-name>-openapi.yaml
# Relative path from apis/ to spec/ is ../spec/
spec:
  api-spec:
    $path: ../spec/<api-name>-openapi.yaml      # relative to the API file's location
  uriSchemes:
    $ref: my-project:my-uri-schemes:1.0          # single direct ref
  policy-sequence:
    - $ref: my-project:my-sequence:1.0           # array

# FreeFlowPolicySequence (DataPower Nano Gateway) — Invoke goes in main
spec:
  monitoring:
    $ref: my-project:telemetry:1.0
  main:
    - $ref: my-project:extract-identity:1.0      # ExtractIdentity first (DataPower Nano Gateway only)
    - $ref: my-project:authenticate:1.0          # Authenticate second (DataPower Nano Gateway only)
    - $ref: my-project:authorize:1.0             # Authorize third (DataPower Nano Gateway only)
    - $ref: my-project:invoke:1.0                # Invoke MUST be here

# StagedPolicySequence (webMethods API Gateway) — Invoke goes in routing
spec:
  security:
    - $ref: my-project:iam:1.0                   # IAM is webMethods API Gateway only
  routing:
    - $ref: my-project:invoke:1.0                # Invoke MUST be here
```

## Complete API Creation Workflow

### Step 1: Select or Create Project — Parallel Fast-Path

> **MANDATORY — Do not skip. Do not wait for project confirmation before starting Step 4 schema fetches when the project name is already known.**

- **Project name already known (provided by user or upstream skill):** Fire `project-manager` skill invocation **and** the Step 4 schema fetches simultaneously — do not wait for `project-manager` to return before issuing the schema fetch tool calls. Both can resolve in parallel.
- **Project not specified:**
  1. **Add to an existing project** — run `apic list`, present results, let user select; start schema fetches immediately after issuing `apic list`
  2. **Create a new project** — invoke `project-manager` skill; issue Step 4 schema fetches in the same parallel batch as the `project-manager` invocation

**HARD RULE:** All project operations (create, list, rename, delete) are owned exclusively by the `project-manager` skill. Asset Manager never performs project operations directly.

### Step 2: Determine Gateway Type

Default is **DataPower Nano Gateway**. Only switch to webMethods API Gateway if the user explicitly mentions webMethods or wmgw.

### Step 3: OpenAPI Specification

- **Spec provided** — read it, extract name, version, paths, security schemes
- **No spec** — analyze workspace, read `references/openapi-generation.md`, generate spec, save to `<project>/spec/<api-name>-openapi.yaml`

### Step 4: Retrieve All Required Schemas — Parallel Batch (issue with Step 1)

**Issue all schema fetches as a single parallel batch — simultaneously with the Step 1 project-manager/list call, not after it:**

```bash
apic schema get API --gateway <gateway-type>
apic schema get FreeFlowPolicySequence --gateway lwgw   # DataPower Nano Gateway only
apic schema get StagedPolicySequence --gateway wmgw      # webMethods API Gateway only
apic schema get URISchemes --gateway <gateway-type>
apic schema get Invoke --gateway <gateway-type>
apic schema get Telemetry --gateway lwgw                 # DataPower Nano Gateway only — fetch here, use in Step 7
```

All `apic schema get` calls must be issued in one parallel batch. Never run them sequentially. Include `Telemetry` here so Step 7 needs no additional schema fetch.

### Step 5: Generate API Asset

Generate from the retrieved API schema. Save to `<project>/apis/<api-name>.yaml`.

**CRITICAL: `api-spec.$path` must be relative to the API file, not the project root.**
The API asset lives at `<project>/apis/<api-name>.yaml` and the spec lives at `<project>/spec/<api-name>-openapi.yaml`. The correct relative path from `apis/` up to `spec/` is always:

```yaml
spec:
  api-spec:
    $path: ../spec/<api-name>-openapi.yaml
```

Never use `./spec/...` or an absolute path — both will fail to resolve because the path is evaluated relative to the API asset file's own directory (`apis/`), not the project root.

**CRITICAL VERSION RULES:**
1. **Version must be a quoted string** — always `version: '1.0'`, never bare `version: 1.0` (YAML parses unquoted numbers as numeric, which will fail)
2. **API `metadata.version` MUST match the OpenAPI spec's `info.version`** exactly — if the spec says `info.version: '1.2'`, the API asset must have `metadata.version: '1.2'`

### Step 6: Generate Invoke Policy

Retrieve the Invoke schema first, then generate.

**Prompt required — endpoint URL has no safe default:**

⚠️ **Never default, guess, infer, or hallucinate the endpoint URL** — not from the OpenAPI spec, not from the workspace, not from any context. This rule is absolute and overrides any general "apply sensible defaults" instruction.

Ask the user directly:

```
What is the backend endpoint URL for this API?
(This is the URL where incoming requests will be forwarded.)
```

**Fields with sensible defaults** (apply silently — no prompting needed):

| Field | DataPower Nano Gateway default | webMethods API Gateway default |
|---|---|---|
| `timeout` | 60s | 60s |
| `version` | `HTTP/1.1` | `HTTP/1.1` |
| `urlType` | `jsonata` | `plain` |
| TLS Client Profile | `tls-client-profile-default:1.0.0` | `tls-client-profile-default:1.0.0` |

Never prompt for TLS Client Profile unless the user explicitly requests a custom profile.

**`verb` field — DataPower Nano Gateway only:** Never add the `verb` property to a DataPower Nano Gateway `Invoke` policy. This field is not valid for nano gateway and must be omitted entirely.

**Do not populate `cache`** — the `cache` block (`expire`, `scope`) is optional and must be omitted unless the user explicitly requests response caching.

**Confirmation summary before saving:**

Once the endpoint URL is provided, display a summary and wait for confirmation before writing any files:

```
# DataPower Nano Gateway example:
Invoke policy — values to be used:
  Endpoint URL:       <user-provided URL>                    [provided]
  Timeout:            60s                                    [default]
  HTTP version:       HTTP/1.1                               [default]
  URL type:           jsonata                                [default]
  TLS client profile: tls-client-profile-default:1.0.0      [default]
  Cache:              omitted                                [not needed by default]

# webMethods API Gateway example:
Invoke policy — values to be used:
  Endpoint URL:       <user-provided URL>                    [provided]
  Timeout:            60s                                    [default]
  HTTP version:       HTTP/1.1                               [default]
  URL type:           plain                                  [default]
  TLS client profile: tls-client-profile-default:1.0.0      [default]
  Cache:              omitted                                [not needed by default]

Proceed?
```

Once confirmed, construct the endpoint field value differently per gateway — this is an internal implementation detail, never surface it to the user:

- **DataPower Nano Gateway** — append the relative URL helper so the full path is forwarded:
  ```
  '''<user-url>'' & $relativeUrl(''request'')'
  ```
- **webMethods API Gateway** — use the URL exactly as provided by the user, no transformation:
  ```
  '<user-url>'
  ```

Save to `<project>/policies/<api-name>-invoke.yaml`.

### Step 7: Generate Telemetry Policy (DataPower Nano Gateway only)

> **Skip this step entirely for webMethods API Gateway** — `Telemetry` is not a valid kind for wmgw.

Use the `Telemetry` schema already fetched in Step 4 — **do not issue another `apic schema get Telemetry` call**.

The `Telemetry` asset populates the `monitoring` stage of the `FreeFlowPolicySequence` — it is the **only** policy allowed there.

**Fields with sensible defaults** (apply silently — no prompting needed):

| Field | Default |
|---|---|
| `spec.verbosity[0].level` | `detailed` |
| `spec.verbosity[0].onSuccessTrimTo` | `detailed` |
| `spec.verbosity[0].inboundLevel` | `detailed` |
| `spec.verbosity[0].outboundLevel` | `detailed` |
| `spec.verbosity[0].operations` | omitted (applies to all operations) |

Only collect `operations` entries if the user explicitly requests per-operation filtering; otherwise omit the field entirely.

**Confirmation summary before saving:**

```
Telemetry policy — values to be used:
  Verbosity level:        detailed   [default]
  On-success trim to:     detailed   [default]
  Inbound level:          detailed   [default]
  Outbound level:         detailed   [default]
  Operations filter:      all        [default]

Proceed?
```

Save to `<project>/policies/<api-name>-telemetry.yaml`.

### Step 8: Generate PolicySequence

Use the `FreeFlowPolicySequence` / `StagedPolicySequence` schema already fetched in Step 4 — **do not issue another schema fetch**.

- **DataPower Nano Gateway** → `FreeFlowPolicySequence` (4 stages: `monitoring`, `main`, `error`, `finally`)
- **webMethods API Gateway** → `StagedPolicySequence` (7 stages — see `references/policy-catalog.md` for stage definitions and allowed policies)

The PolicySequence **MUST** reference the Invoke policy in its primary execution stage (`main` for DataPower Nano Gateway, `routing` for webMethods API Gateway).

For **DataPower Nano Gateway**, also reference the Telemetry asset in the `monitoring` stage (`spec.monitoring.$ref`).

#### FreeFlowPolicySequence — Required Policy Reference Order

When adding policy references to the `main` stage of a `FreeFlowPolicySequence` (DataPower Nano Gateway), the following order **MUST** be respected:

1. **ExtractIdentity** — extracts the caller's identity (e.g. JWT, API key, basic auth)
2. **Authorize** — checks whether the caller is permitted to access the resource
3. **Authenticate** — validates the extracted identity against an identity provider
4. **RateLimit** — enforces request rate or quota limits
5. **Any other policies** — all remaining policies (e.g. Invoke, Transform, etc.) follow after

> Policies added out of this order will be rejected or behave incorrectly at runtime. Always validate the sequence order before saving.

Save to `<project>/policies/<api-name>-sequence.yaml`.

### Step 9: Generate URISchemes

Retrieve the URISchemes schema, generate from it. Save to `<project>/policies/<api-name>-uri-schemes.yaml`.

### Step 10: Link Assets onto the API

The API asset MUST have both of these fields before saving:

```yaml
spec:
  uriSchemes:
    $ref: <namespace>:<uri-schemes-name>:<version>       # direct ref to URISchemes asset
  policy-sequence:
    - $ref: <namespace>:<policy-sequence-name>:<version> # ref to PolicySequence asset
```

`uriSchemes` is a direct field on the API spec — not inside the policy sequence. The PolicySequence (not the API) is where Invoke and other policies are referenced.

### Step 11: Security (always after Steps 5–10 are complete)

> **Only proceed here once the API, PolicySequence, URISchemes, Invoke, and (for DataPower Nano Gateway) Telemetry assets are saved.**

Once the required assets are created, detect any security schemes from the OpenAPI spec (`components.securitySchemes` or `security`). **Only read `references/security-analysis.md` on demand if complex auth mapping or custom flows are required (do not load unconditionally).** Present the user with a clear prompt:

```
The required assets are ready. Before we finish, would you like to add security?

Recommended for <gateway-type> based on your API:
  <recommended pipeline derived from detected patterns, e.g.>
  ExtractIdentity (jwt) → Authenticate (jwt) → Authorize (jwt)   [DataPower Nano Gateway]
  IAM with JWT                                                     [webMethods API Gateway]

Your options:
  1. Add the recommended security policy
  2. Add a custom security flow (describe what you need)
  3. Skip security for now
```

Wait for the user's choice before generating anything:

- **Option 1** — retrieve the relevant schemas; if any required fields have no safe default (e.g., provider names, JWKS URIs, audience claims), collect them all in a single consolidated prompt, then show a confirmation summary before generating
- **Option 2** — ask the user to describe the flow, map it to the appropriate policy types, collect all required inputs in one prompt, show a confirmation summary, then generate after confirmation
- **Option 3** — skip; no security assets are created

**Gateway-specific security policies — never mix these up:**

**DataPower Nano Gateway** — use `ExtractIdentity` + `Authenticate` + `Authorize`:
- JWT Bearer → `ExtractIdentity` (jwt) → `Authenticate` (jwt) → `Authorize` (jwt)
- API Key → `ExtractIdentity` (apiKey) → `Authenticate` (subscription) → `Authorize` (subscription)
- OAuth2 → `ExtractIdentity` (oauth2) → `Authenticate` (oauth2) → `Authorize` (oauth2)
- HTTP Basic → `ExtractIdentity` (httpBasic) → `Authenticate` (subscriptionCredentials) → `Authorize` (subscriptionCredentials)

**webMethods API Gateway** — use `IAM` only:
- All auth patterns (JWT, API Key, OAuth2, Basic) → `IAM`

If security policies are added:
- **Save every security policy file under `<project>/security/`** — never under `policies/` or the project root. This applies to all security-related asset kinds: `ExtractIdentity`, `Authenticate`, `Authorize` (DataPower Nano Gateway) and `IAM` (webMethods API Gateway), as well as any custom security assets.
- Update the PolicySequence to reference them in the correct stage (`main` for DataPower Nano Gateway, `security` for webMethods API Gateway).

### Step 12: OWASP Scan + Policy Suggestions (always after Step 11 is resolved)

> **Only proceed here once security is either added or explicitly skipped.**

This step runs an OWASP API Security Top 10 scan and general policy signal analysis **together**, presenting a single combined list of recommendations — not two separate prompts.

#### 11a: OWASP API Security Top 10 Scan

Scan the OpenAPI spec (and codebase if available) using the in-skill summary checklist below. **Only load `references/owasp-api-top10.md` or `references/policy-catalog.md` on demand if deep troubleshooting or complex policy mapping is explicitly required.**

**Key patterns to always check:**

- **API1 (BOLA)** — path parameters like `{id}`, `{userId}`, `{orderId}` without ownership-scoped `Authorize` / `IAM`
- **API2 (Broken Auth)** — missing `securitySchemes`, `security: []` on non-GET operations, or no auth policy in the sequence. If Step 10 already added auth, mark this ✓ rather than recommending duplicate policies.
- **API3 (BOPLA / Excessive Data)** — response schema fields named `password`, `ssn`, `creditCard`, `cvv`, `secret`, `hash`, `token`, `adminFlag`, `role`, `isAdmin`, `salary`, `dob`, `nationalId`. Suggest `Redact` (DataPower Nano Gateway) or `DataMasking` (webMethods API Gateway).
- **API4 (Resource Consumption)** — no `RateLimit` / `CountLimit` in the sequence; upload endpoints (`multipart/form-data`); paginated endpoints with no `maxItems` constraint.
- **API5 (BFLA — broken function-level auth)** — paths containing `/admin`, `/internal`, `/manage`, `/staff`, `/backoffice`; DELETE or PUT operations on resource collections without elevated-privilege security; operations tagged `admin` sharing the same security scheme as user endpoints. **Default-deny rule:** any destructive operation (DELETE, PUT) on an admin or collection resource where the caller cannot be verified as an admin must be blocked. Generate an `OperationSwitch` + `Block` (DataPower Nano Gateway) or `AuthorizeUser` (webMethods API Gateway) that returns HTTP 403 for non-admin callers.
- **API6 (Business Flow Abuse)** — paths like `/checkout`, `/purchase`, `/reset-password`, `/signup`, `/export`, `/bulk` without tighter per-operation rate limits.
- **API7 (SSRF)** — request fields named `url`, `callbackUrl`, `redirect`, `webhook`, `destination` that could be user-supplied. Suggest an allowlist check via `If` + `Block` (DataPower Nano Gateway) or `TransformRequest` (webMethods API Gateway), and note that backend-side validation is also needed.
- **API8 (Misconfiguration)** — no `CORS` policy or wildcard `allowOrigins: ["*"]`; no `Set` policy injecting security headers (`Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`).
- **API9 (Inventory)** — multiple version path prefixes (`/v1/`, `/v2/`, `/beta/`, `/legacy/`); mixed versioning schemes.
- **API10 (Unsafe Upstream)** — Invoke policies targeting external third-party URLs with no `ValidateAPISpecification` on the response.

#### 11b: General Policy Signal Analysis

In parallel with the OWASP scan, also check for general improvement signals from `references/policy-catalog.md`:

- **High-traffic or public endpoints** (many paths, no rate limit) → `RateLimit` / `RateLimitDef`
- **Multiple backend targets or failover patterns** → `LoadBalancer`
- **No error handling stage populated** → `Try` / `Retry` / `Throw` (DataPower Nano Gateway) or `ErrorProcessing` (webMethods API Gateway)
- **Response caching opportunities** (GET-heavy, stable data) → `CacheServiceResult` / `Cache`
- **No observability** → `Telemetry` (DataPower Nano Gateway) or `Log` / `MonitorTraffic` (webMethods API Gateway)
- **Complex conditional routing** → `OperationSwitch` / `If` (DataPower Nano Gateway) or `Route` (webMethods API Gateway)

#### 11c: Combine and Present

Merge OWASP findings and general signals into **one unified recommendation prompt**. Deduplicate: if both sources recommend the same policy (e.g. RateLimit from API4 and from the general scan), list it once with both rationales.

```
Security & Policy Analysis — <api-name>

OWASP API Top 10 Findings:
  ✗ API3 (Excessive Data)  — Response exposes: password, ssn, creditCardNumber
  ✗ API4 (Resource)        — No rate limiting; file upload at /upload detected
  ✗ API5 (BFLA)            — DELETE /admin/users shares security with user endpoints
  ✗ API8 (Misconfiguration)— No CORS policy; no security response headers
  ✓ API2 (Auth)            — Addressed: JWT auth configured in Step 10
  – API1, API6, API7, API9, API10 — No signals detected

Recommended policies:
  • Redact (API3)           — Strip: password, ssn, creditCardNumber from responses
  • RateLimit (API4)        — Request limits per consumer; tighter limit on /upload
  • OperationSwitch+Block (API5) — Default-deny DELETE /admin/users for non-admin callers
  • Set — Security headers: X-Frame-Options, X-Content-Type-Options, HSTS
  • CORS — Restrict allowed origins
  • Telemetry               — No observability policy detected

Your options:
  1. Add all recommended policies
  2. Select specific policies to add (tell me which ones)
  3. Proceed to build without additional policies
```

Wait for the user's choice before generating anything.

#### 11d: Generate Selected Policies

- **Option 1 / specific selection** — for each selected policy, retrieve its schema (`apic schema get <Kind> --gateway <type>`), apply sensible defaults, collect any required context-specific fields in a single consolidated prompt (e.g. field names to redact, rate limit thresholds, allowed CORS origins), show a confirmation summary, then generate and add to the PolicySequence. **Security policy files** (`ExtractIdentity`, `Authenticate`, `Authorize`, `IAM`, or any auth-related policy) **must be saved under `<project>/security/`**; all other policies go under `<project>/policies/`.
- **Option 2 custom** — ask the user to describe what they want; consult `references/policy-catalog.md` to map intent to policy types, then follow the same retrieve → defaults → prompt → confirm → generate flow.
- **Option 3** — skip; proceed directly to the build step.

After generating any additional policies, update the PolicySequence to reference them in the correct stage for the gateway type (consult `references/policy-catalog.md` and `references/owasp-api-top10.md` for stage placement rules).

> **On-demand OWASP scan:** If the user explicitly requests an OWASP scan at any point — even outside the normal API creation flow — run the scan immediately, present the report, and offer to generate the mitigation policies. You do not need to be in the middle of Step 11 to do this.

### Step 13: Offer to Publish

> **Only proceed here once Step 12 is fully resolved (policies added or skipped).**

After all assets are saved and the OWASP/policy step is complete, ask the user whether they want to publish the project:

```
All assets for <api-name> are ready.

Would you like to publish the project now?
  1. Yes — publish it now
  2. No — I'll publish it later
```

- **Option 1** — invoke the `publish-project` skill to handle the publish flow.
- **Option 2** — acknowledge and close:
  ```
  Done. You can publish later by asking me to "publish <project-name>".
  ```

Never publish silently or automatically — always wait for the user's explicit choice.

## Gateway Conversion (DataPower Nano Gateway ↔ webMethods API Gateway)

When a user asks to convert an existing project between gateway types, read `references/policy-catalog.md` — the **"Converting Between Gateway Types"** section covers:

- Policy sequence substitution (`FreeFlowPolicySequence` ↔ `StagedPolicySequence`)
- Stage mapping between the two models
- Policy-by-policy conversion table (direct ports, substitutes, dropped policies)
- Schema re-validation requirements
- Conversion checklist

Always re-fetch every policy schema for the target gateway — never assume schemas are identical across gateways.

## Policy Discovery and Selection

This process runs in two contexts:

**During API creation** — Step 11 proactively analyses the spec/codebase and presents recommendations. Follow the Step 11 flow.

**On explicit user request** (add functionality to an existing API):

1. **Understand intent** — what behaviour do they want (transform, rate-limit, cache, log, etc.)?
2. **Consult `references/policy-catalog.md`** — use the category tables and user-request mappings to identify 2–3 candidate policies for the target gateway
3. **Retrieve and verify schemas** — `apic schema get <Kind> --gateway <type>` confirms the policy can do what you need
4. **Present options** — show the user the candidates with a brief description and recommended choice
5. **Collect inputs** — apply sensible defaults silently; prompt for any required context-specific fields in one consolidated prompt; show confirmation summary
6. **Generate** — once confirmed, generate the policy asset from the schema and add it to the PolicySequence

## Complete Asset Set Structure

```
<project>/
├── apis/
│   └── <api-name>.yaml
├── spec/
│   └── <api-name>-openapi.yaml
├── policies/
│   ├── <api-name>-sequence.yaml
│   ├── <api-name>-invoke.yaml
│   └── <api-name>-uri-schemes.yaml
├── security/
│   └── <api-name>-security.yaml
├── quotas/
│   └── <quota-name>.yaml
├── plans/
│   └── <plan-name>.yaml
└── products/
    └── <product-name>.yaml
```

## Reference Files

Load only on demand when explicitly needed:

- `references/openapi-generation.md` — Workspace analysis and OpenAPI spec generation
- `references/security-analysis.md` — Deep security pattern detection and policy generation
- `references/policy-catalog.md` — Policy catalog, stage definitions, gateway comparison, gateway conversion guide
- `references/owasp-api-top10.md` — Full OWASP API Security Top 10 mitigation catalogs
- `references/products-plans-quotas.md` — Products, Plans, and Quotas schemas and subscription tiers


## Command Reference

```bash
apic schema list [--gateway <type>]                          # list available asset kinds
apic schema get <kind> [--gateway <type>] [--format <fmt>]  # get schema for a kind (run in parallel)
```

### 1. Use CLI Help if in doubt

```bash
apic schema -h
```

### 2. Project Operations Always Use `project-manager` Skill

Asset Manager **never** creates, lists, renames, or deletes projects. If at any point during an asset workflow the user needs a project operation — or a project does not yet exist — **stop and invoke the `project-manager` skill**. Do not resume asset creation until a confirmed project is in scope.

Failure to delegate results in missing project metadata (namespace, directory structure, config), which will cause all subsequent asset commands to fail.

### 3. Create Complete Asset Sets

When creating an API, ALWAYS create these four required assets first:
- API asset
- PolicySequence (FreeFlowPolicySequence for DataPower Nano Gateway, StagedPolicySequence for webMethods API Gateway)
- URISchemes
- Invoke policy

Then follow Step 10 to handle security — only after the four required assets are saved.

### 4. Always include `namespace` and `tags` in every asset

Every generated asset MUST have:
```yaml
metadata:
  namespace: <namespace>          # defaults to project name; confirm with user if different
  tags:
    - <context-tag-1>             # 1-2 business/domain tags, or [] if none apply
```

### 5. Security is Always Optional — But Always Ask

Never generate security policies silently or pre-emptively. Always complete the four required assets first (API, PolicySequence, URISchemes, Invoke), then ask the user whether they want security, the recommended flow, or a custom flow. The user may also choose to skip it entirely.

### 6. Defaults, Prompts, and Confirmation Summary

This rule applies to **all assets**, not just the Invoke policy:

| Category | Rule |
|---|---|
| **Always default silently** | `timeout`, `version`, `urlType` (`jsonata` for DataPower Nano Gateway, `plain` for webMethods API Gateway), TLS Client Profile. List in confirmation summary. Do not populate `cache` unless the user explicitly requests it. |
| **Always prompt explicitly** | Endpoint URL, asset names, custom identifiers, provider names, JWKS URIs, audience/scope values — any field that is required and context-specific with no safe default. Collect all missing required fields in **one consolidated prompt**. |
| **Never prompt** | Fields that already have a sensible default, unless the user has indicated they want to customise them. |
| **Confirmation before executing** | After collecting all inputs, show a concise summary (values used + which were defaulted) and wait for user confirmation before running any `apic` command or writing any file. |

**TLS Client Profile** — special rule: when a TLS Client Profile is required and the user has not specified one, silently default to `tls-client-profile-default:1.0.0`. Only prompt if the user explicitly states they want a custom profile.

### 7. Use Descriptive Names

Asset names should be:
- Lowercase with hyphens (e.g., `weather-api`)
- Descriptive and meaningful
- Consistent across related assets

## Example Workflow

```
User: "Create an API for my weather service"

1. Ask user: Add to existing project or create new project?
   - If existing: List projects with `apic list`, let user select
   - If new: **Invoke `project-manager` skill — do not proceed until it returns a confirmed project**
2. Use DataPower Nano Gateway (default, unless user specifies webMethods API Gateway)
3. Check if OpenAPI spec exists
4. If not:
   - Analyze workspace
   - Read references/openapi-generation.md
   - Generate OpenAPI spec
5. Retrieve schemas:
   apic schema get API --gateway lwgw
   apic schema get FreeFlowPolicySequence --gateway lwgw
   apic schema get Invoke --gateway lwgw
   apic schema get URISchemes --gateway lwgw
6. Generate API asset
7. Prompt user for endpoint URL (required — no default)
   Show confirmation summary of all Invoke field values (endpoint + defaults)
   Wait for confirmation, then generate Invoke policy
8. Generate FreeFlowPolicySequence
9. Generate URISchemes
10. Link URISchemes and PolicySequence onto the API asset (Step 9)
11. Save all four required assets (API, PolicySequence, URISchemes, Invoke)
12. Detect auth patterns from spec/code (load `references/security-analysis.md` only on demand)
13. Present security options to user:
    - Recommended policy for their gateway + detected auth pattern
    - Custom security flow
    - Skip security
14. If security chosen: retrieve schemas in parallel, generate, update PolicySequence refs
15. Run OWASP API Top 10 scan & policy analysis using in-skill criteria (load reference docs only on demand)
17. Run general policy signal analysis simultaneously
18. Present ONE combined list: OWASP findings + general policy recommendations
19. If policies chosen: retrieve schemas, generate, update PolicySequence refs
20. Ask the user: "Would you like to publish the project now?"
    - Yes → invoke publish-project skill
    - No  → confirm done and remind them they can publish later

## Command Reference

```bash
apic schema list [--gateway <type>]                          # list available asset kinds
apic schema get <kind> [--gateway <type>] [--format <fmt>]  # get schema for a kind (run in parallel)
```

Gateway options: `lwgw` (DataPower Nano Gateway, default), `wmgw` (webMethods API Gateway). Format options: `json` (default), `yaml`.
