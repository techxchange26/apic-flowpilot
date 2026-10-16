# Assertion File Instructions

Instructions for generating assertion files in IBM API Connect test projects.

Always retrieve the official schema before generating:

```bash
apic schema get assertion --gateway common
```

## Assertion Key ENUM

Only these values are valid for the `key` field:

| Key | Description |
|-----|-------------|
| `response` | Complete response object |
| `requestHeaders` | Headers sent in request |
| `responseHeaders` | Headers received in response |
| `requestBody` | Body sent in request |
| `responseBody` | Body received in response |
| `requestUrl` | URL of the request |
| `requestMethod` | HTTP method used |
| `responseStatus` | HTTP status code (always a NUMBER — see rule 1 below) |
| `responseStatusText` | HTTP status text (e.g., "OK") |
| `responseTime` | Response time in milliseconds |

No other key values are valid. Do not use dot-notation shortcuts — use the full ENUM name:
- ❌ `request.body` → ✅ `requestBody`
- ❌ `response.status` → ✅ `responseStatus`
- ❌ `response.headers` → ✅ `responseHeaders`
- ❌ `status` → ✅ `responseStatus`

> **Note**: for nested paths within a body object, dot-notation _is_ valid — e.g., `responseBody.api_info` navigates into the `api_info` object inside the body. The ENUM rule applies only to the top-level key prefix.

## Assertion Action ENUM

Only these values are valid for the `action` field:

`equals`, `notEquals`, `haveProperty`, `notHaveProperty`, `lessThan`, `greaterThan`, `validateSchema`, `inValidateSchema`, `lengthOf`, `include`, `matches`, `type`

Do not use `schema` — use `validateSchema`. No other actions are valid.

## Three Enforced Rules

### Rule 1 — `responseStatus` value is ALWAYS an unquoted integer (no exceptions)

The `responseStatus` key expects a numeric type. Quoting the value (e.g., `"200"`) produces a string, which causes a type-mismatch — the test will always fail even when the actual status code is correct. This is the most common mistake when generating assertion files.

```yaml
# ✅ Correct — bare integer, no quotes
- name: Validate status
  key: responseStatus
  value: 200
  action: equals

# ❌ Wrong — quoted string causes type mismatch; test always fails
- name: Validate status
  key: responseStatus
  value: "200"
  action: equals
```

**Every time you write a `responseStatus` assertion, verify the value is a bare integer before saving the file.**

### Rule 2 — `haveProperty`: property name in `value`, parent path in `key`

The property you are checking goes in `value`. The `key` stops at the parent object.

```yaml
# ✅ Correct — check responseBody has "items"
- key: responseBody
  value: items
  action: haveProperty

# ✅ Correct — check nested object has "status"
- key: responseBody.api_info
  value: status
  action: haveProperty

# ❌ Wrong — property name embedded in key
- key: responseBody.items
  value: ""
  action: haveProperty

# ❌ Wrong — key goes too deep
- key: responseBody.api_info.status
  value: ""
  action: haveProperty
```

### Rule 3 — Keys are from the ENUM

Do not invent key names. Use the ENUM values above as the top-level prefix.

## Standard Assertions Per Test Case

Include these in every assertion file (where applicable):

1. **Status code** — always required
   ```yaml
   - name: Validate response status code
     key: responseStatus
     value: 200        # unquoted integer
     action: equals
     stopOnFail: false
   ```

2. **Content-Type** — for JSON endpoints
   ```yaml
   - name: Validate content type
     key: responseHeaders.content-type   # header names in key MUST be strictly lowercased
     value: application/json
     action: equals
     stopOnFail: false
   ```

3. **Schema validation** — when a response schema is defined in the OpenAPI spec
   ```yaml
   - name: Validate response schema
     key: responseBody
     value: '{"type":"object","required":["id","name"],"properties":{"id":{"type":"integer"},"name":{"type":"string"}}}'
     action: validateSchema
     stopOnFail: false
   ```
   Extract the schema from `components.schemas` in the OpenAPI spec and convert it to a compact JSON string.
   
   > **OWASP Redact / DataMasking note:** If `Redact` (DataPower) or `DataMasking` (webMethods) policies are configured to strip response fields (e.g., `ssn`, `creditCard`), remove those fields from the `required` list in `validateSchema` to prevent schema validation failures on redacted responses.

4. **Required properties** — one entry per required field from the schema's `required` array
   ```yaml
   - name: "Validate required property: id"
     key: responseBody
     value: id
     action: haveProperty
     stopOnFail: false
   ```

5. **OWASP Security Headers (when `Set` response header policy is present)**
   ```yaml
   - name: Validate security header X-Frame-Options
     key: responseHeaders.x-frame-options   # MUST be strictly lowercased
     value: DENY
     action: equals
     stopOnFail: false
   ```

## Assertion File Metadata

```yaml
kind: assertion
apiVersion: api.ibm.com/v1
metadata:
  name: <code>-<scenario>          # e.g., 200-success, 404-not-found
  namespace: <namespace>
  version: "1.0"
  tags:
    - assertion
spec:
  - name: <descriptive assertion name>
    key: <key from ENUM>
    value: <expected value>
    action: <action from ENUM>
    stopOnFail: false
```

## File Naming and Reuse Strategy

Name files `<code>-<scenario>.yml` — e.g., `200-success.yml`, `400-bad-request.yml`, `200-pet-response.yml`.

Create one shared file per status/scenario and reuse it across test cases. Most APIs need only 5–7 files:

```
tests/assertions/
├── 200-success.yml          # status + content-type only (shared)
├── 200-<resource>.yml       # adds schema + properties (per resource type)
├── 201-created.yml          # POST creation (shared)
├── 400-bad-request.yml      # validation errors (shared)
├── 404-not-found.yml        # not found (shared)
└── 401-unauthorized.yml     # auth failures (shared)
```

Create a resource-specific file when the response schema or required properties differ between resources.

See [`examples/assertions/`](../examples/assertions/) for complete YAML templates.
