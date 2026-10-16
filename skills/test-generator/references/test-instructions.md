# Test File Instructions

Instructions for generating test files in IBM API Connect test projects.

Always retrieve the official schema before generating:

```bash
apic schema get test --gateway common
```

## Test File Structure

```yaml
kind: test
apiVersion: api.ibm.com/v1
metadata:
  name: <api-name>-test
  namespace: <namespace>
  version: "1.0"
  tags: []
spec:
  api:
    $endpoint: https://gateway:port/api/path
  request:
    - method: POST
      resource: /pet
      headers:
        - key: content-type
          value: application/json
        - key: Authorization
          value: Bearer ${bearer_token}
      payload:
        raw:
          json: |-
            {
              "id": 10,
              "name": "doggie",
              "photoUrls": ["string"]
            }
      parameters: []
      assertions:
        - $ref: <namespace>:200-pet-response:1.0
  environment:
    $ref: <namespace>:<test-name>-environment:1.0
```

## API Endpoint

Always use `spec.api.$endpoint` with the gateway URL — never use `spec.api.$ref` in test files:

```yaml
spec:
  api:
    $endpoint: https://gateway:port/api/path
```

## Assertions Field Rules

The `assertions` field is always an array, even for a single reference. There is no `expressions` field.

```yaml
# ✅ Single assertion — still use array format
assertions:
  - $ref: namespace:200-pet-response:1.0

# ✅ Multiple assertions
assertions:
  - $ref: namespace:200-pet-response:1.0
  - $ref: namespace:custom-validation:1.0

# ❌ Wrong — scalar, not array
assertions:
  $ref: namespace:200-pet-response:1.0
```

## Request Selection Rules

Select 2–4 representative requests per test file.

**Allowed:**
- ✅ `POST /resource` — create operations
- ✅ `PUT /resource` — update operations
- ✅ `GET /resources` — collection endpoints (no ID path parameter)
- ✅ `POST /resource` with invalid payload — test 400 error

**Forbidden:**
- ❌ `GET /resource/{id}` — cannot guarantee the ID exists (non-deterministic)
- ❌ `DELETE /resource/{id}` — same reason
- ❌ `GET /resource/999` — 404 tests require knowing a non-existent ID

## Headers

Always include standard headers when the endpoint requires them:

```yaml
headers:
  - key: accept
    value: application/json
  - key: content-type
    value: application/json
  - key: Authorization
    value: Bearer ${bearer_token}   # references environment variable
```

**Client-credentials headers (Extract Identity / Authenticate / Authorize / IAM policy sequence):**

When the project's policy sequence contains `ExtractIdentity`, `Authenticate`, `Authorize`, or `IAM`, check the policy configuration for custom header keys (e.g. `X-Client-ID`). If specified, use those header keys; otherwise, default to `X-IBM-Client-Id` and `X-IBM-Client-Secret` on **every request** in the test file:

```yaml
headers:
  - key: X-IBM-Client-Id
    value: ${client_id}
  - key: X-IBM-Client-Secret
    value: ${client_secret}
```

Both values reference environment variables defined in the environment file. These headers must appear on every request — not just the first one. If the API also uses bearer-token auth, include all three headers together:

```yaml
headers:
  - key: content-type
    value: application/json
  - key: Authorization
    value: Bearer ${bearer_token}
  - key: X-IBM-Client-Id
    value: ${client_id}
  - key: X-IBM-Client-Secret
    value: ${client_secret}
```

## Path and Query Parameters

```yaml
# Path parameter (when required by the resource)
parameters:
  - key: petId
    value: "10"
    type: path

# Query parameter
parameters:
  - key: status
    value: available
    type: query
```

## Payload Format

```yaml
payload:
  raw:
    json: |-
      {
        "id": 10,
        "name": "doggie",
        "photoUrls": ["string"]
      }
```

Use realistic but minimal data from the OpenAPI spec's example values or schema defaults.

## Reference Format

All `$ref` values follow the pattern `namespace:name:version`:

```yaml
assertions:
  - $ref: dev:200-pet-response:1.0
environment:
  $ref: dev:petstore-environment:1.0
```

See [`examples/test-patterns/`](../examples/test-patterns/) for complete YAML templates.
