# OWASP API Security Top 10 — Vulnerability Analysis & Policy Mitigations

This reference maps each OWASP API Security Top 10 vulnerability to detectable signals in an OpenAPI specification or codebase, and to the IBM API Connect policies that mitigate it. Always retrieve each policy schema with `apic schema get <Kind> --gateway <type>` before generating.

---

## How to Use This Reference

When the user asks for an OWASP scan, or when running the integrated OWASP analysis during the policy suggestion phase:

1. **Scan for signals** — For each OWASP item, check the OpenAPI spec and any available source code for the detection signals listed below.
2. **Build a findings list** — Record each detected vulnerability with the specific evidence (path, field, scheme name, etc.).
3. **Map to policies** — Use the mitigation table for the detected gateway type.
4. **Present a unified report** — Show findings and policy recommendations together; do not spam the user with one-by-one questions.
5. **Merge with general policy suggestions** — OWASP mitigations and general policy suggestions (rate limiting, telemetry, etc.) are presented **in one combined list**, not as two separate prompts.

---

## OWASP API Top 10 — Detection Signals & Mitigations

---

### API1: Broken Object Level Authorization (BOLA)

**What it is:** Endpoints accept user-supplied IDs (path or query params) without checking whether the caller owns the referenced object.

**Detection signals:**
- Path parameters named `id`, `userId`, `accountId`, `orderId`, `customerId`, or any `{*Id}` pattern
- GET/PUT/DELETE endpoints that accept a resource identifier without a `security` scheme requiring ownership validation
- No `Authorize` / `IAM` policy in the sequence referencing ownership scopes

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `Authorize` | Enforce ownership scopes per resource operation |
| DataPower Nano Gateway | `ExtractIdentity` + `Authorize` | Extract caller identity then validate against resource scope |
| webMethods API Gateway | `IAM` with `AuthorizeUser` | Enforce per-resource authorization |
| Both | `OperationSwitch` / `Route` | Route by operation to apply tighter per-operation checks |

**Generation note:** Configure `Authorize` with the relevant resource scope (e.g., `read:orders:own`, `write:account:own`). Collect scope names from the user — never guess them.

---

### API2: Broken Authentication

**What it is:** Missing, weak, or incorrectly implemented authentication allows attackers to impersonate users.

**Detection signals:**
- No `securitySchemes` defined in the OpenAPI spec
- `security: []` at the global or operation level (security explicitly disabled)
- Endpoints with HTTP methods other than GET that have no security requirement
- Authentication scheme present but no corresponding `ExtractIdentity` / `IAM` in the sequence

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `ExtractIdentity` → `Authenticate` | Validate token/credential on every request |
| webMethods API Gateway | `IAM` | Unified identity and access management |
| Both | `RateLimit` | Slow brute-force attempts on auth endpoints |

**Generation note:** If authentication is already configured (Step 10 was completed), note this finding as "addressed by security step" rather than creating duplicate policies. Only create new policies if a gap is detected.

---

### API3: Broken Object Property Level Authorization (BOPLA)

**What it is:** API responses return more object properties than the caller is authorised to see (excessive data exposure), or write endpoints accept properties the caller should not be able to set (mass assignment).

**Detection signals:**
- Response schemas with fields named `password`, `hash`, `secret`, `ssn`, `creditCard`, `cvv`, `pin`, `internalId`, `adminFlag`, `role`, `isAdmin`, `permissions`, `salary`, `dob`, `nationalId`, `taxId`
- Request bodies with writable properties that appear to be privilege-controlling (`role`, `isAdmin`, `status`, `verified`, `accountLevel`)
- No `Redact` (DataPower Nano Gateway) or `DataMasking` (webMethods API Gateway) policy in the sequence

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `Redact` | Strip or mask sensitive response fields before returning to caller |
| webMethods API Gateway | `DataMasking` | Mask sensitive fields in responses |
| DataPower Nano Gateway | `Transform` / `Remove` | Remove writable privilege fields from request before forwarding |
| webMethods API Gateway | `TransformRequest` | Strip privilege fields from inbound requests |

**Generation note:** When generating `Redact`, prompt the user for the list of field names to redact. Pre-populate with any detected sensitive fields but let the user confirm or expand the list.

---

### API4: Unrestricted Resource Consumption

**What it is:** No limits on request rate, payload size, query complexity, or number of records returned, enabling DoS through resource exhaustion.

**Detection signals:**
- No `RateLimit` or `CountLimit` policy in the sequence
- Endpoints that accept `limit` / `page_size` / `count` query params with no maximum enforced in the spec
- File upload endpoints (POST with `multipart/form-data`) without size constraints
- Batch endpoints or array request bodies with no `maxItems` defined

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| Both | `RateLimit` + `RateLimitDef` | Limit requests per time window per consumer |
| Both | `CountLimit` + `CountLimitDef` | Limit total call count over a longer window |
| DataPower Nano Gateway | `EnforceCircuitBreaker` | Trip and recover when backend is overwhelmed |
| webMethods API Gateway | `InboundBulkHead` | Concurrency cap on inbound requests |

---

### API5: Broken Function Level Authorization (BFLA)

**What it is:** Administrative or privileged functions are accessible to regular users because no function-level authorization is enforced.

**Detection signals:**
- Paths containing `/admin`, `/internal`, `/manage`, `/staff`, `/backoffice`, `/ops`, `/system`, `/superuser`
- DELETE, PATCH, or PUT operations on resource collections (not individual items) without admin-level security requirements
- Operations tagged `admin`, `internal`, or `management` in the OpenAPI spec with the same security scheme as user-facing endpoints
- No `Block` (DataPower Nano Gateway) or `AuthorizeUser` (webMethods API Gateway) policy enforcing role-based denial on admin paths

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `Block` | Deny requests that do not match an admin identity claim |
| DataPower Nano Gateway | `Authorize` | Enforce admin role/scope on privileged operations |
| DataPower Nano Gateway | `OperationSwitch` + `Block` | Route by operation; block non-admin calls to admin operations |
| webMethods API Gateway | `AuthorizeUser` | Enforce role-based access on specific operations |
| webMethods API Gateway | `IAM` with role assertion | Validate admin role claim from the identity token |
| Both | `If` / `Route` + deny branch | Conditional routing to a deny response for unauthorized callers |

**Default-deny rule for admin operations:**
When admin paths or DELETE operations on collections are detected, generate an `OperationSwitch` (DataPower Nano Gateway) or `Route` (webMethods API Gateway) that routes admin operations through an additional `Authorize` / `AuthorizeUser` check. Regular users who do not hold the admin role claim are routed to a `Throw` (DataPower Nano Gateway) or `ErrorProcessing` (webMethods API Gateway) that returns HTTP 403.

**Generation note — this is the "delete administrative assets" pattern the user mentioned:** Create a dedicated authorization policy that explicitly denies DELETE (and other destructive methods) on admin resources unless the caller holds an admin role. Show the user the exact operations being protected before generating.

---

### API6: Unrestricted Access to Sensitive Business Flows

**What it is:** Legitimate business flows (checkout, password reset, account signup, bulk export) can be abused at scale.

**Detection signals:**
- Paths like `/checkout`, `/purchase`, `/order`, `/reset-password`, `/signup`, `/register`, `/export`, `/bulk`
- No rate limiting specifically on those paths
- No CAPTCHA or bot-detection signal in the spec (out of gateway scope, but flag it)

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| Both | `RateLimit` with per-operation config | Tighter rate limit specifically on sensitive business flows |
| Both | `CountLimit` | Hard cap on e.g. daily exports per consumer |
| DataPower Nano Gateway | `EnforceCircuitBreaker` | Trip on anomalous call volumes |

---

### API7: Server-Side Request Forgery (SSRF)

**What it is:** The API fetches a URL supplied by the caller, allowing attackers to probe internal networks.

**Detection signals:**
- Request body or query parameter fields named `url`, `endpoint`, `callbackUrl`, `redirect`, `target`, `webhook`, `destination`, `fetchUrl`, `imageUrl`
- Invoke policies pointing at user-controllable URLs (dynamic `urlType` with user-supplied values)

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `If` + `Block` | Validate URL field is on an allowlist before invoking |
| DataPower Nano Gateway | `JavaScript` | Allowlist validation of user-supplied URL values |
| DataPower Nano Gateway | `Transform` | Strip or replace user-supplied URL fields before invoke |
| webMethods API Gateway | `TransformRequest` | Strip or normalise user-supplied URL fields |

**Generation note:** The gateway cannot fully mitigate SSRF on its own — note this to the user and recommend backend-side validation as a complementary control. The gateway mitigation is to add an allowlist check before the Invoke.

---

### API8: Security Misconfiguration

**What it is:** Missing security headers, permissive CORS, debug information in error responses, unpatched components.

**Detection signals:**
- No `CORS` policy or overly permissive CORS (`allowOrigins: ["*"]`) in the spec
- No `Set` policy adding security headers (`Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`)
- Error responses with stack traces or internal field names visible in `schema` definitions
- TLS not enforced on the Invoke policy

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| Both | `CORS` | Restrict allowed origins, headers, methods |
| Both | `Set` | Inject security response headers |
| DataPower Nano Gateway | `Redact` / `Transform` | Sanitise error response bodies before returning |
| webMethods API Gateway | `DataMasking` | Sanitise error response fields |
| Both | Invoke TLS profile | Enforce TLS on backend connection |

---

### API9: Improper Inventory Management

**What it is:** Old or undocumented API versions remain accessible; no lifecycle management.

**Detection signals:**
- Multiple version prefixes in paths (`/v1/`, `/v2/`, `/beta/`, `/legacy/`, `/old/`)
- No `URISchemes` or `Route` policy enforcing a canonical version
- Mixed versioning schemes (URL + header) in the same spec

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| DataPower Nano Gateway | `Route` + `Block` | Block requests to deprecated version paths |
| webMethods API Gateway | `Route` | Redirect deprecated paths to current version |
| Both | `Set` | Add `Deprecation` and `Sunset` response headers on old paths |

**Generation note:** Flag detected legacy path prefixes to the user and ask if deprecated versions should be blocked or redirected.

---

### API10: Unsafe Consumption of APIs

**What it is:** The API blindly trusts and forwards data from third-party or upstream APIs without validation, allowing injection or unexpected data into the system.

**Detection signals:**
- Invoke policies calling third-party or external URLs (non-internal hostnames)
- No response validation (`ValidateAPISpecification`) on the downstream response
- Response data passed directly to another backend without transformation

**Policy mitigations:**

| Gateway | Policy | Purpose |
|---------|--------|---------|
| Both | `ValidateAPISpecification` | Validate upstream response against schema before forwarding |
| DataPower Nano Gateway | `Transform` / `Parse` | Parse and sanitise upstream response fields |
| webMethods API Gateway | `TransformResponse` | Sanitise upstream response before forwarding |
| DataPower Nano Gateway | `SQLInjectionFilter` | Filter SQL injection in upstream-sourced data |
| DataPower Nano Gateway | `Antivirus` | Scan file content from upstream APIs |

---

## Presenting the OWASP Report

After scanning, present findings in this format:

```
OWASP API Security Scan — <api-name>

Findings:
  ✗ API1 (BOLA)         — Path params {userId}, {orderId} with no ownership scope
  ✗ API3 (BOPLA)        — Response schema exposes: password, ssn, creditCardNumber
  ✗ API4 (Resource)     — No rate limiting; file upload endpoint /upload detected
  ✗ API5 (BFLA)         — DELETE /admin/users has same security as user endpoints
  ✓ API2 (Auth)         — Addressed: JWT ExtractIdentity + Authenticate configured
  – API6 (Business)     — No sensitive business flow paths detected
  – API7 (SSRF)         — No user-supplied URL fields detected
  ✗ API8 (Misconfig)    — No security headers; CORS policy missing
  – API9 (Inventory)    — Single version prefix detected
  – API10 (Upstream)    — No third-party invocations detected

Legend: ✗ = vulnerability detected  ✓ = already mitigated  – = not applicable

Recommended policies to add:
  • Authorize (BOLA)       — Ownership scope enforcement on {userId}, {orderId} paths
  • Redact (BOPLA)         — Strip: password, ssn, creditCardNumber from responses
  • RateLimit (API4)       — Limit requests per consumer; tighten on /upload
  • OperationSwitch+Block (BFLA) — Deny DELETE /admin/users for non-admin callers
  • Set — Security headers (X-Frame-Options, X-Content-Type-Options, HSTS)
  • CORS — Restrict allowed origins

Your options:
  1. Add all recommended OWASP mitigations
  2. Select specific findings to address
  3. Skip OWASP mitigations
```

Wait for the user's choice before generating anything.

---

## Integration with General Policy Suggestions

The OWASP scan runs **inside** the policy suggestion phase (Step 11). The output of the OWASP scan feeds directly into the policy recommendations list — OWASP mitigation policies are shown alongside general suggestions (RateLimit, Telemetry, etc.) in a single combined prompt. Do not present two separate rounds of questions.

**Deduplication rule:** If a policy is recommended by both the OWASP scan and the general signal analysis, list it once with both rationales combined. For example, if general analysis detects "no rate limiting" AND API4 also flags rate limiting, merge them into one `RateLimit` recommendation.

**Authentication deduplication:** If Step 10 already configured authentication (JWT, API Key, OAuth2, etc.), mark API2 as "✓ Already mitigated" rather than recommending duplicate auth policies.

---

## Policy Placement in Sequence

| Policy | DataPower Nano Gateway stage | webMethods API Gateway stage |
|--------|-----------|-----------|
| `Authorize` (BOLA, BFLA) | `main` (after ExtractIdentity) | `security` |
| `Redact` (BOPLA) | `main` (after Invoke) | `res-processing` |
| `DataMasking` (BOPLA) | — | `req-processing` or `res-processing` |
| `RateLimit` (API4, API6) | `main` | `monitoring` |
| `Block` (BFLA) | `main` | — |
| `AuthorizeUser` (BFLA) | — | `security` |
| `CORS` (API8) | — (API-level) | — (API-level) |
| `Set` headers (API8) | `main` | `res-processing` |
| `ValidateAPISpecification` (API10) | `main` | `req-processing` or `res-processing` |
| `SQLInjectionFilter` (API10) | `main` | — |
