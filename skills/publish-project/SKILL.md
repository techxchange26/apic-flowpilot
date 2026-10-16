---
name: publish-project
description: Publish or republish IBM API Connect / APIC projects to IBM API Manager (APIM) or IDIG standalone platform. Use this skill when the user wants to deploy or redeploy API Connect / APIC projects to a gateway, publish/republish to catalogs or spaces, or manage API deployments. Triggers on any mention of IBM API Connect or API Connect (APIC) in the context of publishing, deploying, republishing, or staging. Also triggers on phrases like "publish project to APIM", "republish project", "redeploy API", "deploy to nano gateway", "publish to datapower nano", "deploy to webMethods", "publish to IDIG", or "publish to API Connect".
---

# API Connect Publish Project Skill

> **Never use `apic deploy`** — publishing always goes through the MCP tool or REST API workflow below.
> **Never use `apic publish`** — Such a cli command does not exist, never use this command for any use case related to publish.

---

## Republish vs. Publish — Key Differences

> **Republish = same workflow, same endpoint.** When the user asks to republish or redeploy, follow the exact same steps as a fresh publish. There is no separate republish endpoint or command.
>
> | | Publish (first time) | Republish |
> |---|---|---|
> | `migrate_subscriptions` | `true` (already the default in this skill) | `true` — same, always set |
> | All other steps | identical | identical |
>
> ### Republish Decision Rule
> When the agent detects **republish intent** (user says "republish", "redeploy", "re-publish", "update published API", "push new version", "push an update"), it must:
> 1. **Do not ask** about migrate_subscriptions — it is always `true`.
> 2. Follow the same path (MCP or curl fallback) as a fresh publish.
>
> **Example republish trigger phrases:** "republish", "redeploy", "re-publish", "push an update", "update the published API", "new version"

---

## Step 0: Detect MCP Servers and Route

Before asking the user anything, check which MCP servers are available in this session:

| Detected | Route |
|---|---|
| `ai-gateway-management-mcp-server` only | → [IBM API Connect Path](#apic-path) |
| `interact-gateway-onprem-mcp-server` only | → [IBM DataPower Interact Gateway Standalone Path](#idig-standalone-path) |
| Both | → [IBM API Connect Path](#apic-path) by default |
| Neither | → [IBM API Connect Path](#apic-path) using curl fallback |

If both servers are present and the user explicitly says "publish to IBM DataPower Interact Gateway" or "publish to IBM DataPower Interact Gateway standalone", use the [IBM DataPower Interact Gateway Standalone Path](#idig-standalone-path) instead.

When defaulting to IBM API Connect with both present, inform the user:
> "I'll publish to IBM API Connect (ai-gateway-management-mcp-server). Let me know if you want to target IBM DataPower Interact Gateway standalone instead."

**Do not search for IDIGPublishproject if ai-gateway-management-mcp-server or interact-gateway-onprem-mcp-server does not exist**
---

## Lint and Build (Both Paths)

If the project has not already been linted and built, do that first:

```bash
apic lint <project-name> --localDir . --format TABLE
apic build <project-name> --localDir . --output ./builds/<project-name>.zip
```
*(Note: If multiple projects are being linted/built or independent verification tasks are executed, run independent operations concurrently/in parallel batches where possible).*

Lint errors = **HARD STOP**. Warnings are acceptable — proceed with build.

Requires Node.js 24. **Skip the CLI check if a calling skill (e.g. `build-project` or `lint-project`) already verified it this session.**

If not yet verified, run `apic schema list` once:

| Result | Action |
|--------|--------|
| Returns asset list | ✅ Proceed |
| `error: unknown command 'schema'` | Run `apic version --debug`; if _APIConnect toolkit client_, ask user to upgrade — **HARD STOP** until confirmed, then re-run |
| `error: unknown command 'version'` | `npm i -g @apistudio/apim-cli@latest`, then re-run |
| `command not found: apic` | `npm i -g @apistudio/apim-cli@latest`, then re-run |

**HARD STOP** if `apic schema list` still fails after remediation.

---

## MCP Error Handling (Both Paths)

If any MCP tool call returns an error or `Unauthorized`:

1. Tell the user: _"The MCP server returned an error — this is usually an expired or invalid API key in `~/.bob/settings/mcp.json`. Please update the key and let me know to retry."_
2. Wait for confirmation, then retry the failed tool call once.
3. If it still fails, offer: _"Would you like me to fall back to the curl-based workflow instead?"_
4. If the user accepts, load [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md) and follow that workflow from the beginning.
---

## IBM DataPower Interact Gateway Standalone Path

Uses `interact-gateway-onprem-mcp-server`. Authentication is handled internally by the server via `STANDALONE_USERNAME` / `STANDALONE_PASSWORD` — no separate auth step needed.

### IBM DataPower Interact Gateway Step 1: Confirm ZIP Path

Default: `./builds/<project-name>.zip`. Confirm with the user if not already known.

### IBM DataPower Interact Gateway Step 2: Publish — `PublishProjectToInteractGateway`

Call `PublishProjectToInteractGateway` on `interact-gateway-onprem-mcp-server`:

| Parameter | Required | Description | Default |
|---|---|---|---|
| `zipFilePath` | Yes | Absolute path to the `.zip` file | — |
| `publishToPortal` | No | Also publish to the IBM DataPower Interact Gateway portal | `false` |
| `projectName` | No | Display name; defaults to ZIP filename without `.zip` | — |

Ask the user if they want to publish to the portal (`publishToPortal`). All other fields auto-fill from the build output.

On success, display the result. Done.

On MCP error → see **MCP Error Handling**.

---

## IBM API Connect Path

Uses `ai-gateway-management-mcp-server` for discovery and the `PublishProjectToInteractGateway` tool for publishing. If the MCP server is unavailable at any point, fall back to curl (see MCP Error Handling and [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md)).

### Gateway Matching Rule

| Project built for | `gateway_service_type` |
|---|---|
| DataPower Nano Gateway | `datapower-nano-gateway` |
| webMethods API Gateway | `wm-api-gateway` |

---

### IBM API Connect Step 1: Confirm Base URL

The MCP server's `APIC_MANAGEMENT_URL` is the base URL for all API Manager REST calls (used in the curl fallback). Offer it to the user before asking them to type anything:

> "I can see the IBM API Connect MCP server is configured with base URL `<APIC_MANAGEMENT_URL>`. Would you like to use this for publishing, or provide a different API Manager URL?"

**A — User accepts the MCP URL:** Set `APIM_BASE_URL` to the MCP-configured value and continue.

**B — User provides a different URL:** Ask which they prefer:
  - _"I can set up the MCP server for this new URL so it's used going forward."_
    - If yes: invoke the **setup-agent-kit** skill to reconfigure the MCP server, then restart from IBM API Connect Step 1.
    - If no: load [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md) and follow the full curl-based workflow using the user-provided URL.

**C — No `ai-gateway-management-mcp-server` detected:** Load [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md) and follow the full curl-based workflow.

---

### IBM API Connect Step 2: Select Catalog — `ListCatalogs`

Call `ListCatalogs`. The response looks like:

```json
[
  {
    "catalog_title": "Sandbox",
    "catalog": "sandbox",
    "gateways": ["DataPower Nano Gateway kr20"]
  }
]
```

- One catalog → auto-select and inform the user.
- Multiple → present (`catalog_title` + `gateways[]`) and ask the user to select.
- Store the `catalog` slug as `CATALOG_NAME` and its `id` as `CATALOG_ID`.

On error → see **MCP Error Handling**.

---

### IBM API Connect Step 3: Fetch Gateway Services — `ListGatewaysInCatalog`

Call `ListGatewaysInCatalog` with `catalog: <CATALOG_NAME>`. The response looks like:

```json
[
  {
    "gateway_service_title": "DataPower Nano Gateway kr20",
    "gateway_service_name": "apic-nano-kr20",
    "gateway_service_type": "datapower-nano-gateway",
    "gateway_service_state": "ready",
    "gateway_service_url": "https://api-n-kr20.example.ibmappdomain.cloud/my-org/sandbox"
  }
]
```

- Filter by `gateway_service_type` matching the project type (see Gateway Matching Rule).
- Only consider services with `gateway_service_state: "ready"`.
- One match → auto-select. Multiple → ask (show `gateway_service_title` + `gateway_service_url`). None → **HARD STOP**.
- Store `GATEWAY_SERVICE` = `gateway_service_type` (e.g. `datapower-nano-gateway`).

On error → see **MCP Error Handling**.

---

### IBM API Connect Step 4: Select Space (Optional) — `ListSpaces`

Call `ListSpaces` with `catalog: <CATALOG_NAME>`.

- No spaces → proceed without one.
- Spaces present → offer them plus "None (catalog level)".
- **Note:** `sandbox` catalog does not support spaces.
- Store the selected space `id` as `SPACE_ID`, otherwise leave unset.

On error → see **MCP Error Handling**.

---

### IBM API Connect Step 5: Publish — `PublishProjectToInteractGateway`

Call `PublishProjectToInteractGateway` on `ai-gateway-management-mcp-server`. The server handles auth internally — no token step needed.

| Parameter | Required | Description | Default |
|---|---|---|---|
| `zipFilePath` | Yes | Absolute path to the `.zip` file | — |
| `catalog` | No | Catalog to publish to | `sandbox` |
| `projectName` | No | Display name; defaults to ZIP filename without `.zip` | — |

Pass the selected `CATALOG_NAME` as `catalog`.

On success, display the published API names and gateway URLs. Done.

On MCP error → see **MCP Error Handling**. If curl fallback is chosen, proceed to IBM API Connect Step 6.

---

### IBM API Connect Step 6: curl fallback (only if PublishProjectToInteractGateway fails)

Load [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md) and follow that workflow from the beginning. It covers authentication, org/catalog/gateway/space discovery via curl, and the final publish call — all self-contained.

---

## Example Flows

**Both servers present — default to IBM API Connect:**
```
User: "Publish orders-api"
→ Both ai-gateway-management-mcp-server + interact-gateway-onprem-mcp-server detected → default IBM API Connect
→ Inform user: "Publishing to IBM API Connect. Say 'publish to IBM DataPower Interact Gateway standalone' to switch."
→ Lint ✓ → Build → ./builds/orders-api.zip
→ IBM API Connect Step 1: MCP URL offered → accepted
→ IBM API Connect Step 2: ListCatalogs → user picks "sandbox"
→ IBM API Connect Step 3: ListGatewaysInCatalog(sandbox) → datapower-nano-gateway → auto-select
→ IBM API Connect Step 4: ListSpaces(sandbox) → no spaces
→ IBM API Connect Step 5: PublishProjectToInteractGateway(zipFilePath="./builds/orders-api.zip", catalog="sandbox")
→ ✓ Published: orders-api v1.0
```

**Only standalone server present:**
```
User: "Publish orders-api"
→ Only interact-gateway-onprem-mcp-server detected → IBM DataPower Interact Gateway standalone path
→ Lint ✓ → Build → ./builds/orders-api.zip
→ IBM DataPower Interact Gateway Step 2: PublishProjectToInteractGateway(zipFilePath="./builds/orders-api.zip")
→ ✓ Published to IBM DataPower Interact Gateway standalone
```

**Both present, user targets IBM DataPower Interact Gateway explicitly:**
```
User: "Publish orders-api to IBM DataPower Interact Gateway standalone"
→ Both detected → user said "IBM DataPower Interact Gateway standalone" → IBM DataPower Interact Gateway path
→ IBM DataPower Interact Gateway Step 2: PublishProjectToInteractGateway(zipFilePath="./builds/orders-api.zip", publishToPortal=false)
→ ✓ Published to IBM DataPower Interact Gateway standalone
```

**IBM API Connect — MCP tool fails, curl fallback:**
```
→ IBM API Connect Step 5: PublishProjectToInteractGateway returns error → prompt user to check API key → retry fails
→ Offer curl fallback → user accepts
→ IBM API Connect Step 6: gather creds → POST /api/token → token ✓
→ IBM API Connect Step 7: POST /api/catalogs/{orgId}/{catalogId}/publish-project?gateway_services=datapower-nano-gateway
→ ✓ Published
```

---

## Error Reference

| HTTP | Error | Action |
|------|-------|--------|
| 401 | Invalid credentials | Verify env var; re-authenticate |
| 403 | "Manage APIs" privilege missing | Contact API Manager administrator |
| 404 | Org / catalog / space not found | Verify IDs from MCP tool responses |
| 400 | Invalid gateway service | Re-run `ListGatewaysInCatalog`; verify project gateway type |
| 400 | Invalid project package / ZIP | Rebuild; verify ZIP path |
| 400 | Schema validation failed | Fix errors in API definitions and rebuild |
| 400/404 | TLS client profile not found / mismatch | Go to API Manager → **Manage** → [catalog] → **Catalog Settings** → **TLS Client Profile** and configure the correct profile; see [`references/troubleshooting.md`](references/troubleshooting.md) |
| — | Connection refused / timeout | Verify API Manager URL and network |

---

## Security Rules

- **Never** log, display, or output the password, API key, or access token
- Password and API key always come from environment variables; never prompt the user to type them directly
- Always use HTTPS for API Manager communications
- Use `-k` only for self-signed certificates in development environments
- The MCP servers' internal credentials (`API_KEY`, `STANDALONE_PASSWORD`) are managed by the server — never expose them in user-facing output

---

## Related Skills

- **build-project**: Build projects before publishing
- **lint-project**: Validate projects before building
- **test-generator**: Test APIs after publishing
- **setup-agent-kit**: Configure MCP servers for a new API Manager URL

## Reference Files

- [`references/no-mcp-fallback.md`](references/no-mcp-fallback.md) — Full curl-based discovery + publish workflow when MCP is unavailable
- [`references/curl-samples.md`](references/curl-samples.md) — Standalone curl command examples
- [`references/debugging.md`](references/debugging.md) — Full debug shell script
- [`references/troubleshooting.md`](references/troubleshooting.md) — Issue-by-issue solutions
