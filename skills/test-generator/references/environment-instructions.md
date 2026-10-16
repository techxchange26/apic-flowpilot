# Environment File Instructions

Instructions for generating environment files in IBM API Connect test projects.

Always retrieve the official schema before generating:

```bash
apic schema get environment --gateway common
```

## Environment File Structure

```yaml
kind: environment
apiVersion: api.ibm.com/v1
metadata:
  name: <test-name>-environment
  namespace: <namespace>
  version: "1.0"
  tags: []
spec:
  variables:
    - key: bearer_token
      isSecret: true
      value: ""
    - key: api_key
      isSecret: true
      value: ""
```

## Variable Rules

- Leave `value` empty — the user supplies values at runtime via `--env bearer_token=<value>`
- Mark all credentials and tokens with `isSecret: true`
- Use snake_case for variable names (e.g., `bearer_token`, `api_key`, `client_id`)
- Reference variables in test files as `${variable_name}`

## Extracting Variables from the OpenAPI Spec

Look at the `securitySchemes` section of the OpenAPI spec to determine which variables to create:

| Security scheme type | Variable to create |
|---------------------|--------------------|
| `http` / `bearer` | `bearer_token` |
| `apiKey` | `api_key` (or the scheme name from `name` field) |
| `oauth2` | `bearer_token` |
| `http` / `basic` | `username`, `password` |
| Policy sequence: `ExtractIdentity`, `Authenticate`, `Authorize`, or `IAM` | `client_id`, `client_secret` |

**Policy-based client credentials:** If the project's policy sequence includes `ExtractIdentity`, `Authenticate`, `Authorize`, or `IAM`, always add `client_id` and `client_secret` (both `isSecret: true`) to the environment — regardless of what `securitySchemes` says. See SKILL.md Step 3 for when and how to prompt the user for these values.

Example:

```yaml
# OpenAPI spec securitySchemes
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
```

Produces:

```yaml
spec:
  variables:
    - key: bearer_token
      isSecret: true
      value: ""
    - key: api_key
      isSecret: true
      value: ""
```

## Non-Secret Variables

For non-sensitive configuration (e.g., base paths, timeout values), omit `isSecret` or set it to `false`:

```yaml
spec:
  variables:
    - key: bearer_token
      isSecret: true
      value: ""
    - key: api_version
      isSecret: false
      value: "v1"
```

