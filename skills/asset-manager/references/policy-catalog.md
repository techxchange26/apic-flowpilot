# Policy Catalog and Discovery Guide

This reference provides a comprehensive catalog of available IBM API Connect / APIC policies organized by category, along with common user request mappings to help identify the right policy for specific use cases.

## Complete Policy Lists by Gateway

### DataPower Nano Gateway (lwgw) - 68 Kinds

**Core Assets:**
- `API`, `Scope`, `Project`

**Policy Sequences:**
- `FreeFlowPolicySequence`

**API Management:**
- `CORS`, `Quota`, `Plan`, `Product`, `URISchemes`, `Properties`, `properties`, `Telemetry`, `ValidateAPISpecification`, `GlobalPolicy`

**Invocation & Routing:**
- `Invoke`, `InvokeAWSLambda`, `MCPInvoke`, `LoadBalancer`, `Route`, `HTTPEndpoint`, `MockEndpoint`, `MockResponse`

**Security & Authentication:**
- `SetAuthorization`, `TokenMediation`, `ExtractIdentity`, `Authorize`, `Block`

**Rate Limiting:**
- `RateLimit`, `RateLimitDef`, `CountLimit`, `CountLimitDef`, `EnforceCircuitBreaker`

**Caching & Performance:**
- `CacheServiceResult`, `Cache`

**Transformation & Data:**
- `Set`, `Transform`, `Redact`, `Remove`, `Parse`, `HandlebarsTemplate`

**Control Flow:**
- `If`, `Switch`, `OperationSwitch`, `Try`, `Return`, `Retry`, `Throw`, `Or`

**Scripting:**
- `JavaScript`, `LuaScript`

**Security Filters:**
- `Antivirus`, `SQLInjectionFilter`

**AI/LLM - WatsonX:**
- `InvokeWatsonxModels`, `InvokeWatsonxTokenize`, `InvokeWatsonxTextGen`

**AI/LLM - OpenAI:**
- `InvokeOpenAiChatCompletions`, `InvokeOpenAiEmbeddings`, `InvokeOpenAiModelsId`, `InvokeOpenAiModels`

**AI/LLM - Azure OpenAI:**
- `InvokeAzureOpenAiChatCompletions`, `InvokeAzureOpenAiEmbeddings`, `InvokeAzureOpenAiModelsId`, `InvokeAzureOpenAiModels`

**AI/LLM - Google Gemini:**
- `InvokeGeminiBatchEmbedContents`, `InvokeGeminiCountTokens`, `InvokeGeminiEmbedContent`, `InvokeGeminiGenerateContent`, `InvokeGeminiModelsId`, `InvokeGeminiModels`

**AI/LLM - General:**
- `LLMProvider`

### webMethods API Gateway (wmgw) - 51 Kinds

**Core Assets:**
- `API`, `Scope`, `Project`

**Policy Sequences:**
- `StagedPolicySequence`

**API Management:**
- `CORS`, `Quota`, `Plan`, `Product`, `URISchemes`, `Properties`, `Telemetry`, `ValidateAPISpecification`, `GlobalPolicy`

**Invocation & Routing:**
- `Invoke`, `InvokeAWSLambda`, `LoadBalancer`, `HTTPInvoke`, `Route`, `HTTPEndpoint`, `MockEndpoint`, `MockResponse`

**WebMethods Integration:**
- `WebMethodsISService` (available in v1: api.ibm.com/v1 and v2: api.ibm.com/v2)

**Security & Authentication:**
- `IAM`, `SetAuthorization`, `AuthorizeUser`, `InboundAuthMessage`

**Rate Limiting:**
- `RateLimit`, `RateLimitDef`, `CountLimit`, `CountLimitDef`

**Caching:**
- `CacheServiceResult`

**Transformation & Data:**
- `Set`, `TransformRequest`, `TransformResponse`, `DataMasking`, `SetMediaType`, `SetContextVariable`

**Messaging:**
- `InboundMessaging`, `InvokeMessagingExtension`, `MessageConfig`, `InboundBulkHead`, `OutboundAlias`, `OutboundAnonymous`

**SOAP Support:**
- `SOAPToRESTMapping`, `SOAPInboundBulkHead`, `SOAPEndpoint`, `SOAPMessageConfig`

**Monitoring & Logging:**
- `Log`, `MonitorTraffic`

**Error Handling:**
- `ErrorProcessing`

## Gateway Comparison

### DataPower Nano Gateway — Exclusive Policies (17 unique + all AI/LLM)

**Control Flow & Error Handling:**
- `Return`, `Retry`, `Throw`, `Or`

**Transformation:**
- `Transform`, `Remove`, `Parse`, `HandlebarsTemplate`

**Security:**
- `ExtractIdentity`, `Authorize`, `Block`, `TokenMediation`, `EnforceCircuitBreaker`

**Scripting:**
- `JavaScript`, `LuaScript`

**Security Filters:**
- `Antivirus`, `SQLInjectionFilter`

**Caching:**
- `Cache`

**Control Flow:**
- `OperationSwitch`

**Invocation:**
- `MCPInvoke`

**Policy Sequences:**
- `FreeFlowPolicySequence`

**AI/LLM Integration (21 policies):**
- All WatsonX, OpenAI, Azure OpenAI, and Google Gemini invoke policies
- `LLMProvider`

### webMethods API Gateway — Exclusive Policies (14 unique)

**WebMethods Integration:**
- `WebMethodsISService` (v1 and v2)

**Transformation:**
- `TransformRequest`, `TransformResponse`, `DataMasking`, `SetMediaType`, `SetContextVariable`

**Messaging:**
- `InboundMessaging`, `InvokeMessagingExtension`, `MessageConfig`, `InboundBulkHead`, `OutboundAlias`, `OutboundAnonymous`

**SOAP Support:**
- `SOAPToRESTMapping`, `SOAPInboundBulkHead`, `SOAPEndpoint`, `SOAPMessageConfig`

**Monitoring:**
- `Log`, `MonitorTraffic`

**Error Handling:**
- `ErrorProcessing`

**Security:**
- `AuthorizeUser`, `InboundAuthMessage`

### Shared Policies (Both Gateways)

**Core Assets:**
- `API`, `Scope`, `Project`

**API Management:**
- `CORS`, `Quota`, `Plan`, `Product`, `URISchemes`, `Properties`, `Telemetry`, `ValidateAPISpecification`, `GlobalPolicy`

**Invocation:**
- `Invoke`, `InvokeAWSLambda`, `LoadBalancer`, `HTTPInvoke`, `Route`, `HTTPEndpoint`, `MockEndpoint`, `MockResponse`

**Security:**
- `IAM`, `SetAuthorization`

**Rate Limiting:**
- `RateLimit`, `RateLimitDef`, `CountLimit`, `CountLimitDef`

**Caching:**
- `CacheServiceResult`

**Transformation:**
- `Set`

## Policy Categories

### Security & Authentication

**DataPower Nano Gateway:**
- `SetAuthorization`, `Authenticate`, `ExtractIdentity`, `Authorize`, `Block`, `TokenMediation`

**webMethods API Gateway:**
- `IAM`, `SetAuthorization`, `AuthorizeUser`, `InboundAuthMessage`

### Traffic Management & Routing

**DataPower Nano Gateway:**
- `Invoke`, `InvokeAWSLambda`, `MCPInvoke`, `LoadBalancer`, `Route`, `HTTPEndpoint`, `MockEndpoint`, `MockResponse`

**webMethods API Gateway:**
- `Invoke`, `InvokeAWSLambda`, `HTTPInvoke`, `LoadBalancer`, `Route`, `HTTPEndpoint`, `MockEndpoint`, `MockResponse`, `WebMethodsISService`

### Rate Limiting & Throttling

**Both:**
- `RateLimit`, `RateLimitDef`, `CountLimit`, `CountLimitDef`

**DataPower Nano Gateway only:**
- `EnforceCircuitBreaker`

**webMethods API Gateway only:**
- `InboundBulkHead`, `SOAPInboundBulkHead`

### Caching & Performance

**DataPower Nano Gateway:**
- `CacheServiceResult`, `Cache`

**webMethods API Gateway:**
- `CacheServiceResult`

### Transformation & Data Manipulation

**DataPower Nano Gateway:**
- `Set`, `Transform`, `Redact`, `Remove`, `Parse`, `HandlebarsTemplate`

**webMethods API Gateway:**
- `Set`, `TransformRequest`, `TransformResponse`, `DataMasking`, `SetMediaType`, `SetContextVariable`, `SOAPToRESTMapping`

### Monitoring & Logging

**DataPower Nano Gateway:**
- `Telemetry`

**webMethods API Gateway:**
- `Log`, `MonitorTraffic`, `Telemetry`

### Error Handling & Control Flow

**DataPower Nano Gateway:**
- `If`, `Switch`, `OperationSwitch`, `Try`, `Return`, `Retry`, `Throw`, `Or`

**webMethods API Gateway:**
- `ErrorProcessing`

### Scripting & Custom Logic

**DataPower Nano Gateway only:**
- `JavaScript`, `LuaScript`

### Messaging & Integration

**webMethods API Gateway only:**
- `InboundMessaging`, `InvokeMessagingExtension`, `MessageConfig`, `OutboundAlias`, `OutboundAnonymous`

### SOAP Support

**webMethods API Gateway only:**
- `SOAPToRESTMapping`, `SOAPEndpoint`, `SOAPMessageConfig`

### Security Filters

**DataPower Nano Gateway only:**
- `Antivirus`, `SQLInjectionFilter`

### AI/LLM Integration

**DataPower Nano Gateway only - 21 policies for WatsonX, OpenAI, Azure OpenAI, Google Gemini, and MCP**

## Policy Sequence Stages

### FreeFlowPolicySequence (DataPower Nano Gateway only)

FreeFlowPolicySequence organizes policies into four sections:

1. **monitoring** - Only `Telemetry` policy allowed
2. **main** - Any policy except `Telemetry` (array of policy references)
3. **error** - Any policy except `Telemetry` (array of objects with errorType and execute)
4. **finally** - Any policy except `Telemetry` (array of policy references)

**Example structure:**
```yaml
spec:
  monitoring:
    $ref: namespace:telemetry-policy:1.0
  main:
    - $ref: namespace:operation-switch:1.0
    - $ref: namespace:invoke-backend:1.0
    - $ref: namespace:iam-policy:1.0
  error:
    - errorType: ["BadRequestError", "InternalError"]
      execute:
        - $ref: namespace:error-handler:1.0
  finally:
    - $ref: namespace:cleanup-policy:1.0
```

### StagedPolicySequence (webMethods API Gateway only)

StagedPolicySequence organizes policies into **7 predefined stages**. Each stage only allows specific types of policies:

#### 1. Transport Stage
**Allowed policies:**
- `InboundBulkHead` - Inbound bulkhead
- `SetMediaType` - Set media type
- `InboundMessaging` - Inbound messaging

#### 2. Security Stage (Identify and Authorize)
**Allowed policies:**
- `IAM` - Identify and authorize
- `AuthorizeUser` - Authorize user
- `InboundAuthMessage` - Inbound auth message
- `SetContextVariable` - Set context variable
- `InvokeMessagingExtension` - Messaging
- `HTTPInvoke` - External endpoint
- `InvokeAWSLambda` - AWS lambda

#### 3. Request Processing Stage
**Allowed policies:**
- `TransformRequest` - Request transformation
- `DataMasking` - Data masking
- `WebMethodsISService` - Invoke webMethods IS
- `SetContextVariable` - Set context variable
- `ValidateAPISpecification` - Validate API specification
- `Set` - Custom HTTP header
- `InvokeMessagingExtension` - Messaging
- `HTTPInvoke` - External endpoint
- `InvokeAWSLambda` - AWS lambda

#### 4. Traffic Monitoring Stage
**Allowed policies:**
- `Log` - Log
- `MonitorTraffic` - Monitor traffic
- `CacheServiceResult` - Service result cache
- `RateLimit` - Rate limiter (can reference `RateLimitDef`)

#### 5. Routing Stage
**Allowed policies:**
- `Invoke` - Invoke
- `Route` - Conditional routing, Content based routing, Dynamic routing, JMS/AMQP rest routing, JMS/AMQP soap routing (can reference `HTTPEndpoint` or `SOAPEndpoint`)
- `LoadBalancer` - Load balancer
- `WebMethodsISService` - Invoke webMethods IS
- `SetContextVariable` - Set context variable
- `SetAuthorization` - SetAuthorization
- `OutboundAnonymous` - Outbound anonymous
- `OutboundAlias` - Outbound alias
- `InvokeMessagingExtension` - Messaging
- `HTTPInvoke` - External endpoint
- `InvokeAWSLambda` - AWS lambda

#### 6. Error Handling Stage
**Allowed policies:**
- `ErrorProcessing` - Conditional error processing
- `DataMasking` - Data masking
- `WebMethodsISService` - Invoke webMethods IS
- `SetContextVariable` - Set context variable
- `InvokeMessagingExtension` - Messaging
- `HTTPInvoke` - External endpoint
- `InvokeAWSLambda` - AWS lambda

#### 7. Response Processing Stage
**Allowed policies:**
- `TransformResponse` - Response transformation
- `ValidateAPISpecification` - Validate API specification
- `DataMasking` - Data masking
- `Set` - Custom HTTP header
- `WebMethodsISService` - Invoke webMethods IS
- `HTTPInvoke` - External endpoint

**Example structure:**
```yaml
spec:
  transport:
    - $ref: namespace:inbound-bulkhead:1.0
  security:
    - $ref: namespace:iam-policy:1.0
  req-processing:
    - $ref: namespace:transform-request:1.0
  monitoring:
    - $ref: namespace:rate-limit:1.0
  routing:
    - $ref: namespace:invoke-backend:1.0
  error-handling:
    - $ref: namespace:error-processor:1.0
  res-processing:
    - $ref: namespace:transform-response:1.0
```

**Important Notes:**
- Some policies can have references to inner policies:
  - `RateLimit` can reference `RateLimitDef`
  - `CountLimit` can reference `CountLimitDef`
  - `Route` can reference `HTTPEndpoint` or `SOAPEndpoint`
- Policies like `WebMethodsISService`, `SetContextVariable`, `InvokeMessagingExtension`, `HTTPInvoke`, and `InvokeAWSLambda` can be used in multiple stages

## Common User Request Mappings

| User Request | Gateway | Candidate Policies |
|--------------|---------|-------------------|
| Transform request headers | DataPower Nano Gateway | `Set`, `Transform`, `HandlebarsTemplate` |
| Transform request headers | webMethods API Gateway | `Set`, `TransformRequest`, `SetContextVariable` |
| Transform response | DataPower Nano Gateway | `Set`, `Transform`, `Redact` |
| Transform response | webMethods API Gateway | `Set`, `TransformResponse` |
| Add load balancing | Both | `LoadBalancer` |
| Rate limiting | Both | `RateLimit`, `RateLimitDef`, `CountLimit`, `CountLimitDef` |
| Cache responses | DataPower Nano Gateway | `CacheServiceResult`, `Cache` |
| Cache responses | webMethods API Gateway | `CacheServiceResult` |
| Add logging | DataPower Nano Gateway | `Telemetry` |
| Add logging | webMethods API Gateway | `Log`, `MonitorTraffic` |
| Mask sensitive data | DataPower Nano Gateway | `Redact`, `Remove` |
| Mask sensitive data | webMethods API Gateway | `DataMasking` |
| Error handling | DataPower Nano Gateway | `Try`, `Retry`, `Throw`, `Return` |
| Error handling | webMethods API Gateway | `ErrorProcessing` |
| Conditional logic | DataPower Nano Gateway | `If`, `Switch`, `OperationSwitch`, `Or` |
| Add authentication | DataPower Nano Gateway | `SetAuthorization`, `ExtractIdentity`, `Authorize`, `Authenticate` |
| Add authentication | webMethods API Gateway | `IAM`, `SetAuthorization`, `AuthorizeUser`, `InboundAuthMessage` |
| Mock responses | Both | `MockEndpoint`, `MockResponse` |
| Custom scripting | DataPower Nano Gateway | `JavaScript`, `LuaScript` |
| Circuit breaker | DataPower Nano Gateway | `EnforceCircuitBreaker` |
| Invoke AI/LLM | DataPower Nano Gateway | `InvokeWatsonx*`, `InvokeOpenAi*`, `InvokeAzureOpenAi*`, `InvokeGemini*`, `MCPInvoke` |
| Invoke backend | Both | `Invoke`, `HTTPInvoke`, `LoadBalancer` |
| Invoke Lambda | Both | `InvokeAWSLambda` |
| Invoke WebMethods | webMethods API Gateway | `WebMethodsISService` (v1 or v2) |
| SOAP integration | webMethods API Gateway | `SOAPEndpoint`, `SOAPMessageConfig`, `SOAPToRESTMapping` |
| Template processing | DataPower Nano Gateway | `HandlebarsTemplate` |
| Messaging | webMethods API Gateway | `InboundMessaging`, `InvokeMessagingExtension`, `MessageConfig` |
| Security scanning | DataPower Nano Gateway | `Antivirus`, `SQLInjectionFilter` |
| Parse data | DataPower Nano Gateway | `Parse` |
| Block requests | DataPower Nano Gateway | `Block` |

## Discovery Workflow

When a user asks to add specific functionality:

1. **Identify the gateway type** (DataPower Nano Gateway or webMethods API Gateway)
2. **Understand user intent** from the request
3. **Check the category mappings** above to find candidate policies
4. **Verify policy availability** for the specific gateway using the lists above
5. **Retrieve schema** using `apic schema get <PolicyKind> --gateway <type>`
6. **Present options** to the user with descriptions from the schema
7. **Generate policy asset** once user confirms

## Important Notes

### API Versioning

Some assets support multiple API versions (v1 and v2). When an asset has multiple versions:
- The `kind` name remains the same
- The `apiVersion` field specifies the version (e.g., `api.ibm.com/v1` or `api.ibm.com/v2`)
- v2 versions may include schema improvements, additional fields, or enhanced capabilities
- Always check the schema using `apic schema get <Kind> --gateway <type>` to see available versions and their differences

### Gateway Capabilities

- **DataPower Nano Gateway** has extensive AI/LLM integration capabilities (21 AI-specific policies)
- **webMethods API Gateway** has extensive SOAP and webMethods integration capabilities
- **FreeFlowPolicySequence** is only available in DataPower Nano Gateway
- **StagedPolicySequence** is only available in webMethods API Gateway

## Usage Guidelines

- Always retrieve the actual schema from CLI before generating any policy
- Use the category mappings to narrow down candidates quickly
- Verify schema capabilities before presenting options to users
- Consider gateway-specific policies when making recommendations
- Check the complete policy lists above to confirm availability for the target gateway

## Converting Between Gateway Types

When a user asks to convert an existing DataPower Nano Gateway project to webMethods API Gateway (or vice versa), follow this process. The policy lists and stage definitions above are the source of truth — refer back to them throughout.

### Key Structural Difference

| | DataPower Nano Gateway | webMethods API Gateway |
|-|------|------|
| Policy sequence | `FreeFlowPolicySequence` (4 stages) | `StagedPolicySequence` (7 stages) |
| Stage model | `monitoring` / `main` / `error` / `finally` | `transport` / `security` / `req-processing` / `monitoring` / `routing` / `error-handling` / `res-processing` |

The policy sequence **cannot be copied** between gateways — regenerate it from the target gateway's schema.

---

### DataPower Nano Gateway → webMethods API Gateway

**Step 1 — Replace the policy sequence**

Discard the `FreeFlowPolicySequence`. Generate a new `StagedPolicySequence` from the webMethods API Gateway schema. Map stages as follows:

| DataPower Nano Gateway stage | webMethods API Gateway stage(s) |
|------------|---------------|
| `monitoring` | `monitoring` |
| `main` — security policies | `security` |
| `main` — request transformation | `req-processing` |
| `main` — routing / invoke | `routing` |
| `main` — general policies | distribute across appropriate stages above |
| `error` | `error-handling` |
| `finally` | `res-processing` |

For which policies are allowed in each webMethods API Gateway stage, see the **StagedPolicySequence** stage definitions above.

**Step 2 — Handle each policy**

Cross-reference the **DataPower Nano Gateway — Exclusive Policies** and **Shared Policies** sections above.

- **Shared policies** (both gateways) — port across, but always re-fetch the webMethods API Gateway schema before generating. Field names and required fields can differ.
- **DataPower Nano Gateway exclusive policies** — see substitution and drop rules below:

| DataPower Nano Gateway Policy | Action | webMethods API Gateway Equivalent |
|-------------|--------|-----------------|
| `Transform` | Substitute | `TransformRequest` (inbound, `req-processing`) or `TransformResponse` (outbound, `res-processing`) |
| `Redact` / `Remove` | Substitute | `DataMasking` |
| `HandlebarsTemplate` / `Parse` | Substitute | `TransformRequest` / `TransformResponse` |
| `ExtractIdentity` | Substitute | `IAM` or `InboundAuthMessage` (check webMethods API Gateway IAM schema) |
| `Authorize` | Substitute | `AuthorizeUser` (`security` stage) |
| `Block` | Substitute | Deny rules within `IAM` or `AuthorizeUser` |
| `TokenMediation` | Substitute | `IAM` with token validation config |
| `OperationSwitch` / `If` / `Switch` / `Or` | Substitute | `Route` (`routing` stage) |
| `Try` / `Retry` / `Throw` / `Return` | Substitute | `ErrorProcessing` (`error-handling` stage) |
| `Cache` | Substitute | `CacheServiceResult` |
| `EnforceCircuitBreaker` | Drop | No equivalent — consider `LoadBalancer` with health checks, or remove |
| `JavaScript` / `LuaScript` | Drop | Re-implement using `WebMethodsISService` if available |
| `MCPInvoke` | Drop | Not available in webMethods API Gateway |
| `Antivirus` / `SQLInjectionFilter` | Drop | Not available in webMethods API Gateway |
| All AI/LLM policies | Drop | Not available in webMethods API Gateway |

Tell the user which policies were dropped and why.

**Step 3 — Update the API asset**

`spec.uriSchemes` and `spec.policy-sequence` stay on the API asset with the same structure — just update the `$ref` values to point to the new webMethods API Gateway assets.

**Step 4 — Delete source gateway assets**

Once the new webMethods API Gateway assets are generated and verified, delete all files that belonged exclusively to the old DataPower Nano Gateway project:
- The `FreeFlowPolicySequence` file
- Any dropped policy files (JavaScript, LuaScript, MCPInvoke, AI/LLM, Antivirus, SQLInjectionFilter, EnforceCircuitBreaker if not replaced)
- Any DataPower Nano Gateway exclusive policy files that were substituted (the originals, not the replacements)

Confirm with the user before deleting. Do not delete shared assets (URISchemes, API spec, OpenAPI file) — those carry over.

---

### webMethods API Gateway → DataPower Nano Gateway

**Step 1 — Replace the policy sequence**

Discard the `StagedPolicySequence`. Generate a new `FreeFlowPolicySequence` from the DataPower Nano Gateway schema. Map stages as follows:

| webMethods API Gateway stage | DataPower Nano Gateway stage |
|------------|------------|
| `transport` | `main` |
| `security` | `main` |
| `req-processing` | `main` |
| `monitoring` | `monitoring` (Telemetry only) / `main` for other monitoring policies |
| `routing` | `main` |
| `error-handling` | `error` |
| `res-processing` | `finally` |

For which policies are allowed in each DataPower Nano Gateway stage, see the **FreeFlowPolicySequence** stage definitions above.

**Step 2 — Handle each policy**

Cross-reference the **webMethods API Gateway — Exclusive Policies** and **Shared Policies** sections above.

- **Shared policies** — port across, re-fetch the DataPower Nano Gateway schema before generating.
- **webMethods API Gateway exclusive policies** — see substitution and drop rules below:

| webMethods API Gateway Policy | Action | DataPower Nano Gateway Equivalent |
|-------------|--------|-----------------|
| `TransformRequest` | Substitute | `Transform` |
| `TransformResponse` | Substitute | `Transform` |
| `DataMasking` | Substitute | `Redact` or `Remove` |
| `SetMediaType` | Substitute | `Set` (header manipulation) |
| `SetContextVariable` | Substitute | `JavaScript` or `Set` |
| `AuthorizeUser` | Substitute | `Authorize` |
| `InboundAuthMessage` | Substitute | `ExtractIdentity` |
| `ErrorProcessing` | Substitute | `Try` / `Retry` / `Throw` / `Return` / `If` |
| `WebMethodsISService` | Drop | Not available in DataPower Nano Gateway — re-implement using `Invoke` or `JavaScript` |
| `InboundMessaging` / `InvokeMessagingExtension` / `MessageConfig` / `InboundBulkHead` / `OutboundAlias` / `OutboundAnonymous` | Drop | No equivalent — messaging is webMethods API Gateway specific |
| `SOAPToRESTMapping` / `SOAPEndpoint` / `SOAPMessageConfig` / `SOAPInboundBulkHead` | Drop | No equivalent — SOAP handling is webMethods API Gateway specific |
| `Log` / `MonitorTraffic` | Substitute | `Telemetry` (in `monitoring` stage) |
| `HTTPInvoke` | Substitute | `Invoke` |

Tell the user which policies were dropped and why.

**Step 3 — Update the API asset**

Update `$ref` values in `spec.uriSchemes` and `spec.policy-sequence` to point to the new DataPower Nano Gateway assets.

**Step 4 — Delete source gateway assets**

Once the new DataPower Nano Gateway assets are generated and verified, delete all files that belonged exclusively to the old webMethods API Gateway project:
- The `StagedPolicySequence` file
- Any dropped policy files (WebMethodsISService, messaging policies, SOAP policies if not replaced)
- Any webMethods API Gateway exclusive policy files that were substituted (the originals, not the replacements)

Confirm with the user before deleting. Do not delete shared assets (URISchemes, API spec, OpenAPI file) — those carry over.

---

### Schema Re-validation (Both Directions)

Even for policies that exist in both gateways, never copy the YAML directly. Always re-fetch and compare:

```bash
apic schema get <Kind> --gateway lwgw
apic schema get <Kind> --gateway wmgw
```

If field names, required fields, or enum values differ — regenerate the asset from the target gateway's schema.

