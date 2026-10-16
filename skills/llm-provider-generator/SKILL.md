---
name: llm-provider-generator
description: Generate LLM Provider KIND documents for IBM API Connect / APIC / IDIG projects. Use this skill when the user wants to create, generate, or scaffold LLM provider configuration files for watsonx, gemini, openai, azure-openai, or custom providers. Triggers on phrases like "generate LLM provider", "create LLM provider", "add LLM provider to project", "set up watsonx connection", "configure openai in my project", "generate AI provider config", or any request to wire an LLM provider into an APIC/IDIG project.
---

# LLM Provider Generator Skill

> **Never attempt to generate LLM provider files manually or via curl.** All generation goes through the MCP tool call below.

---

## Step 0: Detect MCP Servers and Route

Before asking the user anything, check which MCP servers are available in this session:

| Detected | Route |
|---|---|
| `ai-gateway-management-mcp-server` only | → [IBM API Connect Path](#apic-path) |
| `interact-gateway-onprem-mcp-server` only | → [IBM DataPower Interact Gateway Standalone Path](#idig-standalone-path) |
| Both | → [IBM API Connect Path](#apic-path) by default |
| Neither | → **HARD STOP** — tell the user: _"Required tools are not available. Please ensure either `ai-gateway-management-mcp-server` or `interact-gateway-onprem-mcp-server` is configured and running."_ Do not proceed, do not attempt curl or manual generation. |

When both servers are present, inform the user:
> "I'll use `ai-gateway-management-mcp-server` (IBM API Connect path). Let me know if you want to target IBM DataPower Interact Gateway standalone instead."

---

## MCP Error Handling (Both Paths)

If any MCP tool call returns an error or `Unauthorized`:

1. Tell the user: _"The MCP server returned an error — this is usually an expired or invalid API key in `~/.bob/settings/mcp.json`. Please update the key and let me know to retry."_
2. Wait for confirmation, then retry the failed tool call once.
3. If it still fails, **HARD STOP** — do not try curl or any other workaround.

---

## Step 1: Create Project

Invoke the **project-manager** skill to create a new project (or confirm an existing one).

- Ask the user: _"What should the project be named?"_ (or confirm if they already specified one).
- Pass the project name to `project-manager` and let it handle creation.
- Store the project name as `PROJECT_NAME` — it is used as `xIbmProject` in all MCP tool calls.
- Capture the **absolute project directory path** returned by `project-manager` as `PROJECT_DIR`. Do not resolve it independently — use the path returned by the skill. See `project-manager`'s **Return Contract** for the format.

`PROJECT_DIR` is passed as the `directory` parameter in the `LLMProviderGenerator` call so the MCP server writes files directly into the project.

**HARD STOP if project creation fails** — do not proceed.

---

## IBM API Connect Path

Uses `ai-gateway-management-mcp-server`. The MCP server handles auth internally — no separate authentication step needed.

### IBM API Connect Step 1: List Available LLM Providers — `ListLLMProviders`

Call `ListLLMProviders` on `ai-gateway-management-mcp-server` (no parameters required).

The response lists providers with `display_name`, `name`, and `description`:

| display_name | name | description |
|---|---|---|
| IBM watsonx | watsonx | IBM watsonx AI platform |
| Google Gemini | gemini | Google Gemini LLM |
| OpenAI | openai | OpenAI platform |
| Azure OpenAI | azure-openai | Microsoft Azure OpenAI |
| Custom (OpenAI-compatible) | custom | Any OpenAI-compatible endpoint |

Present this list to the user and ask which provider they want to generate.

Store the selected value as `PLATFORM` (must be one of: `watsonx`, `gemini`, `openai`, `azure-openai`, `custom`).

On MCP error → see **MCP Error Handling**.

---

### IBM API Connect Step 2: Gather Required Inputs

Ask the user for the **required** parameters based on the selected `PLATFORM`:

#### Always Required (all platforms)

| Parameter | Description | Example |
|---|---|---|
| `apiKeySecretName` | Name of the API key secret stored securely in the gateway — **not** the actual key value | `watsonx-api-key`, `openai-secret` |

#### Platform-Specific Required Inputs

**watsonx:**
- `region` — e.g. `us-south`, `eu-de`
- `projectId` — WatsonX project ID

**openai:**
- `orgId` — OpenAI organization ID
- `projectId` — OpenAI project ID

**azure-openai:**
- `deploymentId` — Azure deployment name (e.g. `gpt4-deploy`)
- `resourceId` — Azure resource ID

**custom:**
- `providerUrl` — Full URL of the OpenAI-compatible endpoint (e.g. `https://api.mistral.ai/`)

**gemini:** No platform-specific required inputs beyond `apiKeySecretName`.

---

### IBM API Connect Step 3: Gather Optional Inputs (Ask Once, Use Defaults Otherwise)

Ask the user if they want to customize any of the following. If they say no or skip, use the defaults shown:

| Parameter | Default | Description |
|---|---|---|
| `connectionName` | `<platform>-connection` | Human-readable connection name |
| `version` | `1.0` | API version |
| `basePath` | _(empty)_ | Base path for the provider API |
| `tags` | _(none)_ | Comma-separated tags (e.g. `production,ai`) |
| `tlsClientProfile` | `tls-client-profile-default:1.0.0` | TLS profile for secure connections |
| `opVersion` | _(none)_ | Operation version — WatsonX and Azure OpenAI only |
| `model` | _(empty)_ | Model name |
| `modelVersion` | `1.0` | Model version |
| `modelProvider` | _(empty)_ | Model provider name |
| `responseCaching` | `true` | Enable response caching |
| `cacheTTL` | `60` | Cache TTL in seconds |
| `maxTokens` | `1000` | Max tokens for rate limiting |
| `tokenTimeInterval` | `1` | Token rate limit window (seconds) |
| `maxRequests` | `1000` | Max requests for rate limiting |
| `requestTimeInterval` | `1` | Request rate limit window (seconds) |
| `intervalUnit` | `seconds` | Time unit: `seconds`, `minutes`, or `hours` |
| `exceedAction` | `continue` | When limits exceeded: `continue`, `return429`, `return500`, or `throttle` |
| `errorHandlingEnabled` | `false` | Enable custom error handling |
| `errorHandlingType` | `plain` | Error format: `plain` or `json` |
| `errorMessage` | `An error occurred while processing your request.` | Custom error message |
| `errorCode` | `400` | HTTP error code to return |
| `telemetryEnabled` | `true` | Enable telemetry |
| `telemetryLogLevel` | `default` | Telemetry log level: `default` or `debug` |

---

### IBM API Connect Step 4: Generate — `LLMProviderGenerator`

Call `LLMProviderGenerator` on `ai-gateway-management-mcp-server` with the collected parameters:

```
platform:          <PLATFORM>
xIbmProject:       <PROJECT_NAME>
apiKeySecretName:  <value from user>
directory:         <PROJECT_DIR>        ← absolute path to the project folder
connectionName:    <value or default>
basePath:          <value or default>
version:           <value or default>
tags:              <array or empty>
tlsClientProfile:  <value or default>
// Platform-specific (include only if applicable):
region:            <watsonx only>
projectId:         <watsonx / openai only>
orgId:             <openai only>
opVersion:         <watsonx / azure-openai only>
deploymentId:      <azure-openai only>
resourceId:        <azure-openai only>
providerUrl:       <custom only>
// Advanced options (include only if user customized):
model / modelVersion / modelProvider
responseCaching / cacheTTL
maxTokens / tokenTimeInterval
maxRequests / requestTimeInterval
intervalUnit / exceedAction
errorHandlingEnabled / errorHandlingType / errorMessage / errorCode
telemetryEnabled / telemetryLogLevel
```

Do **not** pass platform-specific parameters that do not apply to the selected platform.

On MCP error → see **MCP Error Handling**.

#### After the tool call — write files to project

The MCP server returns generated files as base64-encoded attachments in the response.
Each attachment has: `fileNameWithExtension`, `fileContent` (base64).

**Write every attachment into `PROJECT_DIR`:**

- For each attachment in the response:
  1. Decode `fileContent` from base64.
  2. Write the decoded content to `<PROJECT_DIR>/<fileNameWithExtension>`.
  3. Create any intermediate directories if needed.
  4. If the file already exists, **skip it** (do not overwrite) unless the user explicitly asked to overwrite.

> When `EXTERNAL_CLIENT=true` the server writes the files automatically (the `directory` param is used server-side). Skip the manual write step in that case — the server's response summary will list the written paths.

After all files are written, confirm to the user:
> _"Generated `<N>` LLM Provider file(s) into `<PROJECT_DIR>`:"_
> _(list each filename)_

Verify the files are present:
```bash
ls <PROJECT_DIR>/
```

If any file is missing, write it manually from the attachment content before proceeding.

Proceed to **Step 5** only when all generated files are confirmed present in `PROJECT_DIR`.

---

### IBM API Connect Step 5: Publish

All generated files are confirmed present in `PROJECT_DIR`. Invoke the **publish-project** skill to lint, build, and publish the project from `PROJECT_DIR`.

---

## IBM DataPower Interact Gateway Standalone Path

Uses `interact-gateway-onprem-mcp-server`. Authentication is handled internally by the server — no separate auth step needed.

### IBM DataPower Interact Gateway Step 1: List Available LLM Providers — `ListLLMProviders`

Call `ListLLMProviders` on `interact-gateway-onprem-mcp-server` (no parameters required).

Present the returned provider list to the user and ask which provider they want to generate.

Store the selected value as `PLATFORM`.

On MCP error → see **MCP Error Handling**.

---

### IBM DataPower Interact Gateway Step 2: Gather Required Inputs

Collect the same parameters as the IBM API Connect path:

**Always required (all platforms):** `apiKeySecretName`

**Platform-specific required inputs:**
- `watsonx` → `region`, `projectId`
- `openai` → `orgId`, `projectId`
- `azure-openai` → `deploymentId`, `resourceId`
- `custom` → `providerUrl`
- `gemini` → no extras

**Optional inputs:** ask the user once — `connectionName` (default `<platform>-connection`), `version` (default `1.0`), `basePath`, `tags`, `tlsClientProfile` (default `tls-client-profile-default:1.0.0`), `model`, `responseCaching`, `cacheTTL`, `maxTokens`, `maxRequests`, `errorHandlingEnabled`, `telemetryEnabled`, and related sub-options. Use defaults for anything not specified.

---

### IBM DataPower Interact Gateway Step 3: Generate — `LLMProviderGenerator`

Call `LLMProviderGenerator` on `interact-gateway-onprem-mcp-server` with the same parameter set as the IBM API Connect path — `platform`, `xIbmProject`, `apiKeySecretName`, `directory: <PROJECT_DIR>`, plus all platform-specific and optional parameters collected in Step 2.

On MCP error → see **MCP Error Handling**.

After the tool call, apply the same **write files to project** procedure described in IBM API Connect Step 4 to ensure all attachment files land in `PROJECT_DIR`.

Verify files are present before proceeding:
```bash
ls <PROJECT_DIR>/
```

Proceed to **Step 4** only when all generated files are confirmed present in `PROJECT_DIR`.

---

### IBM DataPower Interact Gateway Step 4: Publish

All generated files are confirmed present in `PROJECT_DIR`. Invoke the **publish-project** skill to lint, build, and publish the project from `PROJECT_DIR`.

---

## Parameter Quick Reference

| Platform | Required extras |
|---|---|
| `watsonx` | `region`, `projectId`, `apiKeySecretName` |
| `gemini` | `apiKeySecretName` |
| `openai` | `orgId`, `projectId`, `apiKeySecretName` |
| `azure-openai` | `deploymentId`, `resourceId`, `apiKeySecretName` |
| `custom` | `providerUrl`, `apiKeySecretName` |

## Example Calls Reference

| User intent | platform | extras |
|---|---|---|
| "Generate watsonx provider in project `test` with API key secret `wx-key`" | `watsonx` | `region`, `projectId` |
| "Set up Gemini connection `dev-gemini-conn` in project `p1` with secret `gemini-key`" | `gemini` | `connectionName` |
| "Create OpenAI provider for project `dev`, orgId `my-org`, projectId `proj-123`, secret `openai`" | `openai` | `orgId`, `projectId` |
| "Azure OpenAI for project `az-proj`, deployment `gpt4`, resource `my-res`, secret `azure`" | `azure-openai` | `deploymentId`, `resourceId` |
| "Custom Mistral provider, URL `https://api.mistral.ai/`, project `dev`, secret `mistral-key`" | `custom` | `providerUrl` |

## Related Skills

- **project-manager** — creates and manages projects (used in Step 1)
- **publish-project** — lints, builds, and publishes the project (used in final step)
- **asset-manager** — manage other asset types (APIs, Products, Plans, Policies)
