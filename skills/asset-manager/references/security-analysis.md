# Security Policy Analysis and Suggestions

This reference provides detailed guidance for analyzing workspace code to suggest appropriate security policies for IBM API Connect / APIC assets.

## CRITICAL: Always Verify with CLI

**The security policies listed in this document are for reference only**

Before suggesting or generating any security policy, you MUST:

1. **Discover current security policies:**
   ```bash
   apic schema list --gateway <gateway-type>
   ```
   This ensures you have the latest list and can detect any newly added security policies.

2. **Verify the schema before generation:**
   ```bash
   apic schema get <PolicyName> --gateway <gateway-type>
   ```
   Always retrieve and verify the actual schema structure before generating any security policy asset.

**Never rely solely on the policy lists in this document.** The CLI is the source of truth for available policies and their schemas.

## Overview

Security is critical for API deployments. This guide helps identify security requirements from:
- OpenAPI security schemes
- Code-based authentication patterns
- Workspace security implementations

## Available Security Assets

### For DataPower Nano Gateway (lwgw)

```bash
# Discover security assets
apic schema list --gateway lwgw | grep -i "auth\|identity"
```

**Supported security policies (3 total):**
- `Authorize` - Authorization policy — validates that the caller has permission to access the resource
- `Authenticate` - Authentication policy — verifies the identity of the caller (subscription, JWT, OAuth2)
- `ExtractIdentity` - Extracts credential information from inbound requests before auth checks

### For webMethods API Gateway (wmgw)

```bash
# Discover security assets
apic schema list --gateway wmgw | grep -i "iam"
```

**Supported security policies (1 total):**
- `IAM` - Identity and Access Management (comprehensive security with JWT, OAuth2, API keys, Basic auth)

## Security Analysis Process

### Step 1: Analyze OpenAPI Security Schemes

If an OpenAPI spec exists, check the `securitySchemes` section:

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    apiKey:
      type: apiKey
      in: header
      name: X-API-Key
    oauth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/oauth/authorize
          tokenUrl: https://auth.example.com/oauth/token
          scopes:
            read: Read access
            write: Write access
```

### Step 2: Detect Authentication Patterns in Code

#### JWT Token Authentication

**Node.js/Express:**
```javascript
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
```

**Python/Flask:**
```python
from flask_jwt_extended import jwt_required, get_jwt_identity

@app.route('/api/protected')
@jwt_required()
def protected():
    current_user = get_jwt_identity()
    return {'user': current_user}
```

**Detection indicators:**
- JWT library imports (`jsonwebtoken`, `flask-jwt-extended`, `spring-security-oauth2`)
- Token verification in middleware/filters
- `Authorization: Bearer` header checks
- JWT secret configuration

#### API Key Authentication

**Node.js:**
```javascript
const verifyApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey || !isValidApiKey(apiKey)) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  next();
};
```

**Detection indicators:**
- API key header checks (`X-API-Key`, `Api-Key`)
- API key validation functions
- API key storage/lookup

#### OAuth2 Authentication

**Detection indicators:**
- OAuth2 library usage (`passport-oauth2`, `authlib`)
- Authorization/token URLs
- Client ID/secret configuration
- Scope definitions

#### Basic Authentication

**Detection indicators:**
- Basic auth middleware
- `Authorization: Basic` header checks
- Base64 credential decoding

### Step 3: Map to IBM API Connect Security Assets

Based on detected patterns, suggest the appropriate security policy for the target gateway.

#### For DataPower Nano Gateway — Use `ExtractIdentity` + `Authenticate` + `Authorize`

The recommended pipeline for DataPower Nano Gateway is:

```
ExtractIdentity → Authenticate → Authorize → Invoke
```

- **`ExtractIdentity`** pulls the credential out of the request (header, query, cookie, payload, etc.)
- **`Authenticate`** validates that credential against a provider (JWT, OAuth2, subscription)
- **`Authorize`** confirms the caller has the required permissions/scopes

Get schemas from CLI before generating:
```bash
apic schema get ExtractIdentity --gateway lwgw
apic schema get Authenticate --gateway lwgw
apic schema get Authorize --gateway lwgw
```

#### For webMethods API Gateway — Use `IAM`

`IAM` is the only supported security policy for webMethods API Gateway and handles all authentication patterns:
```bash
apic schema get IAM --gateway wmgw
```

## Policy Schemas

> ⚠️ **The examples below are partial and for illustration purposes only.**
> Always retrieve the authoritative schema from the CLI before generating any asset:
> ```bash
> apic schema get <PolicyName> --gateway <gateway-type>
> ```
> The CLI is the single source of truth for field names, required fields, and allowed values.

### ExtractIdentity (DataPower Nano Gateway)

Pulls credential material out of the inbound request. The key field is `spec.credentialType`, which selects both what is extracted and where from.

**Supported credential types:** `hostname`, `ipAddress`, `httpBasic`, `oauth2`, `jwt`, `apiKey`, `subscriptionCredentials`, `certificate`, `httpHeaders`, `payloadElement`

**Source options** (where applicable): `httpHeader`, `contextVar`, `query`, `payload`, `cookie`

**Example — JWT from Authorization header** *(partial; verify full schema with CLI)*:
```yaml
kind: ExtractIdentity
metadata:
  name: ei-jwt
  namespace: security
  version: 1.0
spec:
  credentialType:
    jwt:
      httpHeader:
        name: Authorization
```

**Example — API Key from custom header** *(partial)*:
```yaml
kind: ExtractIdentity
metadata:
  name: ei-apikey
  namespace: security
  version: 1.0
spec:
  credentialType:
    apiKey:
      httpHeader:
        name: X-API-Key
```

---

### Authenticate (DataPower Nano Gateway)

Validates the extracted credential against a provider. The key field is `spec.operation`, which selects the auth method.

**Supported operation types:** `subscription`, `subscriptionCredentials`, `jwt`, `oauth2`

**Example — JWT** *(partial; verify full schema with CLI)*:
```yaml
kind: Authenticate
apiVersion: api.ibm.com/v1
metadata:
  name: authenticate-jwt
  namespace: security
  version: 1.0
spec:
  operation:
    jwt:
      providers:
        - 'my-provider'
      audClaim:
        - 'my-audience'
```

---

### Authorize (DataPower Nano Gateway)

Confirms the authenticated caller has the required permissions. The key field is `spec.operation`.

**Supported operation types:** `subscription`, `jwt`, `oauth2`

**Example — OAuth2 with scopes** *(partial; verify full schema with CLI)*:
```yaml
kind: Authorize
apiVersion: api.ibm.com/v1
metadata:
  name: authorize-oauth2
  namespace: security
  version: 1.0
spec:
  operation:
    oauth2:
      issClaim: ''
      requiredScopes:
        - provider: 'my-provider'
          scopes:
            - 'read:user'
```

---

### Invoke (DataPower Nano Gateway + webMethods API Gateway)

The `Invoke` policy must always set `tlsClientProfile` at `spec.endpoint.http.target.tlsClientProfile`.

**Example — showing TLS field placement** *(partial; verify full schema with CLI)*:
```yaml
kind: Invoke
apiVersion: apim.ibm.com/v1
metadata:
  name: my-api-invoke
  version: 1.0
  namespace: default
spec:
  endpoint:
    http:
      target:
        tlsClientProfile: tls-client-profile-default:1.0.0   # ALWAYS required
        url: 'https://your-backend-host/path'
```

---

### IAM (webMethods API Gateway only)

`IAM` is the sole security policy for webMethods API Gateway. Key structural points:
- `spec.accessControl` is a **list-of-lists**: outer list = OR alternatives, inner list = AND conditions
- `spec.extensions.webm-gateway` adds webMethods API Gateway exclusive credential types (kerberos, openIdConnect, wsSecurityUsernameToken, wsSecurityX509Certificate)

**Supported credential types (core):** `httpBasic`, `apiKey`, `oauth`, `jwt`, `hostname`, `ipAddress`, `certificate`, `payloadElement`, `httpHeaders`

**Supported credential types (webMethods API Gateway extension):** `kerberos`, `openIdConnect`, `payloadElement`, `wsSecurityUsernameToken`, `wsSecurityX509Certificate`

**Example — OAuth2** *(partial; verify full schema with CLI)*:
```yaml
kind: IAM
apiVersion: api.ibm.com/v1
metadata:
  name: my-api-iam
  version: 1.0
  namespace: default
spec:
  accessControl:
    - - oauth:
          applicationSecurity:
            mode: authorize      # authorize | authenticate | identify
          providers:
            - my-provider
          requiredScopes:
            - provider: my-provider
              scopes:
                - read
                - write
```

## Security Suggestion Workflow

### 1. Analyze and Detect

```
1. Check OpenAPI spec for securitySchemes
2. Search code for authentication patterns:
   - JWT:    grep -r "jwt\|jsonwebtoken\|JWT" .
   - API Key: grep -r "api.key\|apikey\|x-api-key" .
   - OAuth:   grep -r "oauth\|OAuth2" .
   - Basic:   grep -r "basic.auth\|basicAuth" .
3. Identify the primary authentication method
```

### 2. Present Options to User

**Template for user prompt (DataPower Nano Gateway):**

```
Security Analysis for DataPower Nano Gateway:
I've analyzed your API and detected the following security patterns:

Detected: JWT Bearer token authentication
- Found JWT verification in middleware
- Token expected in Authorization header

Supported security policies for DataPower Nano Gateway (3 total):
1. ExtractIdentity — Pulls the credential from the request
   - Supports: hostname, ipAddress, httpBasic, oauth2, jwt,
     apiKey, subscriptionCredentials, certificate, httpHeaders,
     payloadElement
   - Typically placed first in the sequence

2. Authenticate — Validates the extracted credential
   - Supports: subscription, subscriptionCredentials, jwt, oauth2
   - Typically placed after ExtractIdentity

3. Authorize — Enforces access permissions
   - Supports: subscription, jwt (issClaim), oauth2 (scopes)
   - Typically placed after Authenticate

Recommendation: ExtractIdentity (jwt) → Authenticate (jwt) → Authorize (jwt)

Note: The Invoke policy in the sequence will have
tlsClientProfile: tls-client-profile-default:1.0.0 set automatically.

Which credential type and auth method would you like to use?
```

**Template for user prompt (webMethods API Gateway):**

```
Security Analysis for webMethods API Gateway:
I've analyzed your API and detected the following security patterns:

Detected: JWT Bearer token authentication
- Found JWT verification in middleware
- Token expected in Authorization header

Supported security policies for webMethods API Gateway (1 total):
1. IAM — Comprehensive identity and access management
   - Supports JWT, OAuth2, API keys, Basic auth
   - Recommended for all authentication patterns on webMethods API Gateway

Would you like me to add the IAM security policy?
```

### 3. Generate Security Policy

Based on user choice, retrieve the schema and generate the policy:

```bash
# DataPower Nano Gateway — get schemas for the three security policies
apic schema get ExtractIdentity --gateway lwgw
apic schema get Authenticate --gateway lwgw
apic schema get Authorize --gateway lwgw

# webMethods API Gateway — IAM is the only security policy
apic schema get IAM --gateway wmgw

# Save generated files to: <project>/security/<api-name>-<policy-type>.yaml
```

Use the schema templates in the **Policy Schemas** section above as starting points, then fill in values from the detected patterns. The `tlsClientProfile` field belongs only on the `Invoke` policy — not on `ExtractIdentity`, `Authenticate`, or `Authorize`.

### 4. Reference in Policy Sequence

#### For DataPower Nano Gateway — FreeFlowPolicySequence

Security policies go in the **main** stage in order: `ExtractIdentity` → `Authenticate` → `Authorize` → `Invoke`. The `Invoke` policy must carry `tlsClientProfile: tls-client-profile-default:1.0.0`.

```yaml
kind: FreeFlowPolicySequence
apiVersion: api.ibm.com/v1
metadata:
  name: my-api-sequence
  version: 1.0.0
spec:
  monitoring:
    $ref: default:my-api-telemetry:1.0.0        # Only Telemetry allowed here
  main:
    - $ref: default:my-api-extract-identity:1.0.0  # ExtractIdentity first
    - $ref: default:my-api-authenticate:1.0.0       # Authenticate second
    - $ref: default:my-api-authorize:1.0.0          # Authorize third
    - $ref: default:my-api-invoke:1.0.0             # Invoke last
  error:
    - errorType: ["*"]
      execute:
        - $ref: default:error-handler:1.0.0
  finally:
    - $ref: default:cleanup:1.0.0
```

#### For webMethods API Gateway — StagedPolicySequence

`IAM` goes in the **security** stage:

```yaml
kind: StagedPolicySequence
apiVersion: api.ibm.com/v1
metadata:
  name: my-api-sequence
  version: 1.0.0
spec:
  security:
    - $ref: default:my-api-iam:1.0.0       # IAM in security stage
  routing:
    - $ref: default:my-api-invoke:1.0.0
```

See `references/policy-catalog.md` for complete stage definitions and allowed policies per stage.

## Common Security Patterns

### Pattern 1: JWT Authentication

**Detected when:** JWKS URI / public key in config, RS256/RS512 algorithm, issuer and audience validation

**DataPower Nano Gateway:**
- `ExtractIdentity` with `credentialType.jwt.httpHeader`
- `Authenticate` with `operation.jwt` (providers + audClaim)
- `Authorize` with `operation.jwt` (issClaim)

**webMethods API Gateway:** `IAM` with JWT and JWKS URI

### Pattern 2: API Key in Header

**Detected when:** Custom header checks (X-API-Key), API key lookup in DB/cache

**DataPower Nano Gateway:**
- `ExtractIdentity` with `credentialType.apiKey.httpHeader`
- `Authenticate` with `operation.subscription` or `subscriptionCredentials`

**webMethods API Gateway:** `IAM` with API key configuration

### Pattern 3: OAuth2 with Scopes

**Detected when:** OAuth2 authorization flow, scope-based access control, token introspection

**DataPower Nano Gateway:**
- `ExtractIdentity` with `credentialType.oauth2.httpHeader`
- `Authenticate` with `operation.oauth2` (providers + introspectionCredential)
- `Authorize` with `operation.oauth2` (issClaim + requiredScopes)

**webMethods API Gateway:** `IAM` with OAuth2 configuration

### Pattern 4: Subscription Credentials (clientId + clientSecret)

**Detected when:** API Connect subscription-based access, clientId/clientSecret pair

**DataPower Nano Gateway:**
- `ExtractIdentity` with `credentialType.subscriptionCredentials`
- `Authenticate` with `operation.subscriptionCredentials`
- `Authorize` with `operation.subscription`

## Security Best Practices

### 1. Always Prompt for Security

Never skip security analysis. Always ask the user about security even if no patterns are detected.

### 2. Use the Full Pipeline (DataPower Nano Gateway)

For DataPower Nano Gateway production APIs, use the complete `ExtractIdentity` → `Authenticate` → `Authorize` pipeline. For webMethods API Gateway, use `IAM`.

### 3. TLS Client Profile on Invoke Only

Only the `Invoke` policy carries the TLS client profile — never add it to `ExtractIdentity`, `Authenticate`, or `Authorize`. Always set it to `tls-client-profile-default:1.0.0` unless the user specifies otherwise.

### 4. Validate Configuration

Ensure security configuration includes:
- Correct `credentialType` in `ExtractIdentity` matching the actual auth mechanism
- Matching `operation` type in `Authenticate` and `Authorize`
- Providers list populated in `Authenticate` for JWT/OAuth2
- Scopes and issuer claim in `Authorize` for OAuth2

### 5. Document Security Requirements

Include security requirements in the generated assets:
```yaml
metadata:
  description: |
    This API requires JWT authentication.
    Tokens must be issued by https://auth.example.com
    and include the 'api-access' scope.
```

### 6. Test Security Configuration

Suggest testing security after generation:
```
Security policies created. To test:
1. Deploy the API to a gateway
2. Try accessing without authentication (should fail with 401)
3. Try with valid credential (should succeed)
4. Try with invalid/expired credential (should fail with 401/403)
```

## Summary

Security analysis workflow:

1. **Analyze** — Check OpenAPI spec and code for auth patterns
2. **Discover** — Run `apic schema list` and verify schemas via CLI
3. **Suggest** — Present `ExtractIdentity` + `Authenticate` + `Authorize` for DataPower Nano Gateway, or `IAM` for webMethods API Gateway
4. **Generate** — Create policies using CLI schema and templates in this file
5. **Reference** — Place security policies in `FreeFlowPolicySequence` main stage (DataPower Nano Gateway) or `StagedPolicySequence` security stage (webMethods API Gateway)
6. **Validate** — Confirm credential type and auth method alignment

Always guide DataPower Nano Gateway users toward the full `ExtractIdentity` → `Authenticate` → `Authorize` pipeline for robust API protection.
