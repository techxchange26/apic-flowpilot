---
name: setup-mcp-asset
description: Register an MCP server in the current agent workspace — either a subscribed IBM API Connect / IDIG MCP asset (from a creds file) or an external MCP server specified by URL. For subscribed assets, reads the creds file produced by the publish-and-subscribe flow. For external MCP servers by URL, uses MCPToMCPGenerator to generate IDIG Kind files. Triggers on phrases like "set up my subscribed MCP asset", "register my subscription", "I subscribed to an MCP asset now what", "add my MCP asset to my agent", "register MCP server at <url>", "add external MCP server", "register external MCP", or as an optional follow-up after publish-project completes a subscription.
---

# Setup MCP Asset

Register an MCP server in your AI agent — either a subscribed IBM API Connect / IDIG MCP asset (from a creds file) or an external MCP server specified directly by URL.

---

## Step 0 — Detect MCP Servers and Route

Before asking the user anything, check which MCP servers are available in this session and classify the user's request:

### Server Detection

| Detected | External MCP Route | Subscribed Asset Route |
|---|---|---|
| `interact-gateway-onprem-mcp-server` or `ai-gateway-management-mcp-server` present | ✅ Proceed | ✅ Proceed |
| Neither present | → **HARD STOP** for External MCP Route — tell the user: _"Registering an external MCP server requires `interact-gateway-onprem-mcp-server` or `ai-gateway-management-mcp-server` to be configured and running. Please run `/setup-agent-kit` first."_ | ✅ Proceed (subscribed asset registration does not require an IDIG MCP server) |

### Request Classification

| Signal | Route |
|---|---|
| User provides a URL (e.g. `https://mcp.example.com/mcp`) with or without auth, and does **not** mention a creds file or subscription | → **External MCP Route** |
| User mentions "subscribed asset", "creds file", "subscription", or no URL is given | → **Subscribed Asset Route** (Step 1 onwards) |
| Ambiguous — could be either | Ask: _"Are you registering an external MCP server by URL, or a subscribed IBM API Connect / IDIG asset from a creds file?"_ Wait for the response before continuing. |

---

## External MCP Route

Use this path when the user provides an MCP server URL directly (e.g. `Register MCP server at https://mcp.deepwiki.com/mcp having no form of authentication in the project my-external-mcp`).

**Do not** look for a creds file or proceed to Step 1 of the Subscribed Asset Route.

### External MCP Step 1 — Collect Parameters

Extract the following from the user's request:

| Variable | Source | Required |
|---|---|---|
| `MCP_SERVER_URL` | User's prompt | ✅ Yes |
| `X_IBM_PROJECT` | User's prompt (e.g. "in the project my-external-mcp") | ✅ Yes — ask if not provided |
| `MCP_SERVER_NAME` | User's prompt or derive from URL hostname (e.g. `deepwiki` from `mcp.deepwiki.com`) | No |
| `AUTH_TOKEN` | User's prompt | No |
| `AUTH_API_KEY` | User's prompt | No |

If `X_IBM_PROJECT` was not provided in the prompt, ask:
> "Which project should this MCP server be registered in? (e.g. `my-external-mcp`)"

Wait for the response before continuing.

### External MCP Step 2 — Call `MCPToMCPGenerator`

Call `MCPToMCPGenerator` on whichever IDIG MCP server is available (`interact-gateway-onprem-mcp-server` preferred; fall back to `ai-gateway-management-mcp-server`):

| Parameter | Value |
|---|---|
| `mcpServerUrl` | `MCP_SERVER_URL` |
| `xIbmProject` | `X_IBM_PROJECT` |
| `mcpServerName` | `MCP_SERVER_NAME` (omit if not available) |
| `token` | `AUTH_TOKEN` (omit if not provided) |
| `apiKey` | `AUTH_API_KEY` (omit if not provided) |

On MCP error → inform the user of the error and **HARD STOP**. Do not attempt to write the config manually.

### External MCP Step 3 — Report Result

Display the tool result to the user and confirm what was registered. Then **stop** — do not continue to the Subscribed Asset Route below.

---

> **Subscribed Asset Prerequisites**: The user must have already created, published, and subscribed to an MCP asset. The subscribe step produces creds files under `./subscriptions/` in the workspace root.

---

## Step 1 — Locate Subscriptions

Scan for creds files in the workspace:

```bash
ls ./subscriptions/*-creds.json 2>/dev/null
```

**If no `subscriptions/` folder or no `*-creds.json` files are found:**

> "No subscription creds files were found at `./subscriptions/`. Please make sure you have subscribed to an MCP asset first. The subscribe step creates files at `./subscriptions/<product-name>-creds.json`."

**HARD STOP** — do not proceed.

---

## Step 2 — Parse and Validate Creds Files

Read each `*-creds.json` file found. For each file, check for the minimum required fields:

| Field | Required | Notes |
|---|---|---|
| `product_name` | ✅ | Used as the server key in the MCP config; also used to derive the asset display name |
| `published_assets` | ✅ | Array; must contain at least one entry with a non-empty `gateway_endpoints` array |
| `client_id` | ❌ optional | When present, passed as `X-IBM-Client-Id` header. Absence means auth bypass is enabled on the gateway — this is valid by design |
| `client_secret` | ❌ optional | When present, paired with `client_id`. If `client_id` is absent, `client_secret` is also ignored |

Classify each file:

- **`READY`** — `product_name` and `published_assets` present, and at least one `gateway_endpoints` URL ends with `/mcp` (confirming it is an MCP asset). `client_id`/`client_secret` may or may not be present
- **`NOT_MCP`** — required fields are present, but none of the `gateway_endpoints` URLs end with `/mcp`; this is a non-MCP asset (e.g. an LLM provider) and cannot be registered with this skill
- **`INCOMPLETE`** — `product_name` or `published_assets` is missing or empty; note which fields

Also check the agent's current MCP config file (determined in Step 3) for each product name. Mark assets already registered there as **`CONFIGURED`**.

---

## Step 3 — Identify the Agent

Check the current conversation and workspace context for signals of which AI agent is running:

- If the agent can be determined with confidence (e.g. running inside IBM Bob, `.bob/` folder present, or the session was started via a known agent), set the variables below automatically and inform the user:
  > "I can see you're using **<agent display name>**. I'll write the config to `<MCP_CONFIG_FILE>`."

- If the agent **cannot be determined**, ask:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Which AI agent are you using?

[1] IBM Bob
    MCP config: .bob/mcp.json

[2] GitHub Copilot (VS Code)
    MCP config: .vscode/mcp.json

[3] Other — I'll provide the path
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for the user's answer. For **Other**, ask for the config file path and its top-level JSON key (`mcpServers`, `servers`, etc.).

Set these variables for use in all subsequent steps:

| Variable | IBM Bob | GitHub Copilot (VS Code) | Other |
|---|---|---|---|
| `AGENT` | `bob` | `github-copilot` | user-provided |
| `CONFIG_DIR` | `.bob` | `.vscode` | derived from path |
| `MCP_CONFIG_FILE` | `.bob/mcp.json` | `.vscode/mcp.json` | user-provided |
| `TOP_LEVEL_KEY` | `mcpServers` | `servers` | user-provided |
| `NEEDS_TYPE_FIELD` | `false` | `true` | ask if unsure |

> **Note**: GitHub Copilot (VS Code) uses `"servers"` (not `"mcpServers"`) and requires a `"type": "stdio"` field on each entry. See Step 6.

---

## Step 4 — Present Asset Selection

Display a checklist of all found creds files with their status. Pre-check `READY` assets that are not yet `CONFIGURED`.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Subscribed Assets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select the MCP assets you want to register in your agent.

[x] bookstore-0wm3a                              [ready — mcp asset]
    Endpoint : https://…nanogw.fyre…/1.0/mcp
    Auth     : client credentials
    Plan     : plan-bookstore-0wm3a:1.0

[x] car-resale-mcp-noauth                        [ready — mcp asset, no auth]
    Endpoint : https://…nanogw.fyre…/2.0/mcp
    Auth     : none (auth bypass enabled)

[ ] petstore-s4pnv                               [already configured]
    Endpoint : https://…apiconnect.test…/1.0/mcp
    Auth     : client credentials

[ ] product-llm-provider-example                 [not an mcp asset — endpoint does not end with /mcp]

[ ] product-watsonx-3ga2h                        [not an mcp asset — endpoint does not end with /mcp]

[ ] product-broken-example                       [incomplete — missing: published_assets]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select at least one ready MCP asset to continue.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Rules**:
- `NOT_MCP` assets are shown with `[not an mcp asset]` and cannot be selected. No further explanation is needed beyond the label.
- `INCOMPLETE` assets are shown but cannot be selected. Note which fields are missing.
- `CONFIGURED` assets are shown greyed-out with `[already configured]`. The user can still select them to **overwrite** the existing entry (e.g. after credential rotation) — if they do, confirm before overwriting.
- Assets without `client_id`/`client_secret` are labelled `no auth` — this is not an error.
- The user must select at least one `READY` asset.
- Register assets **one at a time** — complete all steps for each selected asset before moving to the next. This avoids errors caused by partial writes.

---

## Step 5 — Resolve Endpoint and Optional Rename

For each selected asset, **one at a time**:

### 5a — Resolve Endpoint

Filter `published_assets` to only include entries whose `gateway_endpoints` URLs end with `/mcp`. From the filtered set, if there is still more than one URL, present the options and ask the user to pick one:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
product-watsonx-example has multiple MCP endpoints.
Which one should be registered?

[1] https://endpoint-a.example.com/1.0/mcp  (asset: product-watsonx-example)
[2] https://endpoint-b.example.com/1.0/mcp  (asset: product-watsonx-example-v2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If there is exactly one `/mcp` endpoint across all assets, use it automatically without asking.

Set `MCP_ENDPOINT` directly to the chosen URL — do **not** append `/mcp`; the endpoint is already complete.

### 5b — Optional Server Key Rename

The default server key is `product_name` from the creds file (e.g. `product-watsonx-0wm3a`).

Ask **once and briefly**:

> "I'll register this as `product-watsonx-0wm3a` in your agent config. Press Enter to keep this name, or type a different key name:"

If the user presses Enter (no input), use `product_name` as-is. If the user provides a name, use that as `SERVER_KEY`.

> **Gemini CLI users**: server keys must use hyphens, not underscores. Auto-correct any underscores to hyphens and inform the user.

---

## Step 6 — Probe the Endpoint (Connection Validation)

Before writing the config, verify the endpoint is reachable and retrieve the available tools using a direct JSON-RPC call.

Build the curl command using the resolved `MCP_ENDPOINT` and credentials (if any):

**With client credentials:**

```bash
curl -s -k -X POST "<MCP_ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "X-IBM-Client-Id: <client_id>" \
  -H "X-IBM-Client-Secret: <client_secret>" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  --max-time 15
```

**Without credentials (auth bypass):**

```bash
curl -s -k -X POST "<MCP_ENDPOINT>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  --max-time 15
```

Parse the response and handle:

| Response | Meaning | Action |
|---|---|---|
| `result.tools` array present | ✅ Endpoint reachable, tools retrieved | Store as `TOOLS_LIST`, continue to Step 7 |
| HTTP 401 / `error.code -32000` | Auth required but credentials missing or wrong | Inform user: _"The endpoint requires credentials. Please check `client_id` and `client_secret` in the creds file."_ — **HARD STOP** |
| HTTP 404 | Endpoint not found | Inform user: _"The endpoint returned 404 — the MCP asset may not be deployed yet. Please re-publish and re-subscribe."_ — **HARD STOP** |
| Connection refused / timeout | Endpoint unreachable | Inform user: _"Could not reach `<MCP_ENDPOINT>`. Please check that the gateway is running and the URL is correct."_ — **HARD STOP** |
| Any other error | Unexpected failure | Show the raw error to the user and **HARD STOP** |

Display a brief confirmation once the probe succeeds:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Connection verified — <product_name>
  Endpoint : <MCP_ENDPOINT>
  Tools    : <N> tools available
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 7 — Build the MCP Config Entry

Use `SERVER_KEY` and `MCP_ENDPOINT` (already the complete `/mcp` URL). Include auth headers only when `client_id` is present in the creds file.

### Standard JSON — Bob, Claude Desktop, Cursor, Windsurf, Continue, Cline, Roo Code, Warp, Gemini CLI, Amazon Q, Kiro, Antigravity

**With client credentials:**

```json
"<SERVER_KEY>": {
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>",
    "--header",
    "X-IBM-Client-Id: <client_id>",
    "--header",
    "X-IBM-Client-Secret: <client_secret>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

**Without credentials (auth bypass):**

```json
"<SERVER_KEY>": {
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

### VS Code Native / GitHub Copilot — requires `"type": "stdio"` and `"servers"` key

**With client credentials:**

```json
"<SERVER_KEY>": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>",
    "--header",
    "X-IBM-Client-Id: <client_id>",
    "--header",
    "X-IBM-Client-Secret: <client_secret>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

**Without credentials (auth bypass):**

```json
"<SERVER_KEY>": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

### Claude Code — requires `"type": "stdio"`

**With client credentials:**

```json
"<SERVER_KEY>": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>",
    "--header",
    "X-IBM-Client-Id: <client_id>",
    "--header",
    "X-IBM-Client-Secret: <client_secret>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

**Without credentials (auth bypass):**

```json
"<SERVER_KEY>": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote",
    "<MCP_ENDPOINT>"
  ],
  "env": {
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}
```

> **Security**: When present, `client_id` and `client_secret` are written into the config file as `--header` arg strings since `mcp-remote` does not support env-var expansion in `--header` values. Never echo these values to the terminal or to chat output beyond what is necessary for the config write.

---

## Step 8 — Write the Config Entry

### 8a — Ensure the Config File Exists

```bash
# macOS/Linux
[ -f <MCP_CONFIG_FILE> ] || (mkdir -p <CONFIG_DIR> && echo '{"<TOP_LEVEL_KEY>":{}}' > <MCP_CONFIG_FILE>)

# Windows (PowerShell)
if (-not (Test-Path "<MCP_CONFIG_FILE>")) {
  New-Item -ItemType Directory -Force -Path "<CONFIG_DIR>" | Out-Null
  '{"<TOP_LEVEL_KEY>":{}}' | Out-File -FilePath "<MCP_CONFIG_FILE>" -Encoding utf8
}
```

Replace `<TOP_LEVEL_KEY>` with `mcpServers` (or `servers` for VS Code / GitHub Copilot).

### 8b — Merge the New Entry

1. Read and parse the existing `<MCP_CONFIG_FILE>`.
2. If `SERVER_KEY` already exists and the user confirmed overwrite in Step 4, replace it. Otherwise skip (should not reach here).
3. Add the new entry under `<TOP_LEVEL_KEY>`.
4. Preserve all existing entries.
5. Write with 2-space indentation.

### 8c — Validate

```bash
# macOS/Linux
cat <MCP_CONFIG_FILE> | python -m json.tool > /dev/null && echo "Valid JSON"

# Windows (PowerShell)
try { Get-Content "<MCP_CONFIG_FILE>" | ConvertFrom-Json; Write-Host "Valid JSON" } catch { Write-Host "Invalid JSON" }
```

**If validation fails**: back up the corrupted file as `<MCP_CONFIG_FILE>.backup`, attempt to repair (trailing commas, quote fixes). If repair fails, restore the backup and **HARD STOP** with instructions to fix manually.

---

## Step 9 — Repeat for Remaining Selected Assets

Return to Step 5 and process the next selected asset. Complete Steps 5–8 fully before moving on.

---

## Step 10 — Report

After all selected assets are processed, present a final summary that includes the tools list retrieved during probing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MCP Asset Registration Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent          : <agent display name>
Config File    : <MCP_CONFIG_FILE>

Registered:
  ✓ <SERVER_KEY_1>  →  <MCP_ENDPOINT_1>
  ✓ <SERVER_KEY_2>  →  <MCP_ENDPOINT_2>

Skipped (already configured, not re-selected):
  - <asset-name>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After the summary block, for each registered asset display the tools retrieved in Step 6:

```
Available tools in <SERVER_KEY>:
  • <tool-name-1>  — <tool-description-1>
  • <tool-name-2>  — <tool-description-2>
  …

You can now ask your agent to use any of these tools directly.
For example: "Use <tool-name-1> to …"
```

If multiple assets were registered, group the tools by asset.

Agent-specific reload instructions (use the instruction for the registered agent):

| Agent | Reload instruction |
|---|---|
| IBM Bob | Restart Bob or open a new session. |
| GitHub Copilot (VS Code) | Run `Developer: Reload Window` or restart VS Code. |
| Claude Code | Open a new shell session and run `claude`. |
| Claude Desktop | Fully quit and relaunch the app. |
| Cursor | No restart needed — config hot-reloads. |
| Windsurf | Restart Windsurf. |
| Warp | Changes take effect at next session start. |
| Gemini CLI | Open a new shell and run `gemini`. |
| Amazon Q | No restart needed — loads at next session start. |
| Kiro | Ensure MCP is enabled in Settings, then reload the window. |

---

## Important Rules

1. **One asset at a time**: Complete Steps 5–8 fully for each asset before starting the next. Never batch-write multiple assets in a single file edit.
2. **Preserve existing config**: Never overwrite entries that were not explicitly selected for overwrite.
3. **Absolute paths only**: All file paths written to the config must be absolute. Resolve `~` to the full home directory.
4. **Secrets in config**: When present, `client_id` and `client_secret` are written to the config file as `--header` arg strings. Do not display them in chat output; use `••••••` in any user-facing summary.
5. **Auth is optional**: The absence of `client_id` and `client_secret` is valid by design — auth bypass is intentionally enabled on the gateway for those assets. Do not treat missing credentials as an error.
6. **Do not ask unnecessary questions**: If agent, endpoint, and asset name can be inferred, do not ask — only prompt when genuinely ambiguous or when the user must make a choice between multiple options.
7. **MCP assets only**: This skill only registers MCP assets — those whose `gateway_endpoints` URLs end with `/mcp`. Assets whose endpoints do not end with `/mcp` (e.g. LLM providers) are automatically classified as `NOT_MCP` and excluded from selection.
8. **Optional `catalog` / `plan` fields**: The `catalog`, `plan`, `app`, and other metadata fields in the creds file are informational only. Their absence must not block registration.

## Related Skills

- **publish-project**: Publish and subscribe to MCP assets; produces the `subscriptions/` creds files this skill consumes
- **setup-agent-kit**: Configure the core IBM API Connect MCP servers (management, analytics, idig, etc.)
- **rest-to-mcp-generator**: Generate and publish an MCP server from a REST OpenAPI spec
