---
name: apic
description: Install and configure IBM API Connect MCP servers (analytics, governance, management, ai-gateway-management, genai-spec)
---

# API Connect MCP servers setup

Install and configure the IBM API Connect MCP servers from the `mcp-servers` directory. The user chooses which servers to install — only those servers are set up in the final configuration.

> **Agent context**: These instructions use the variables `AGENT`, `CONFIG_DIR`, `MCP_CONFIG_FILE`, `MCP_TEMPLATE_FILE`, `MCP_SERVERS_DIR`, and `APIC_PRESENT` set during the Agent Selection and MCP Servers Discovery steps in `SKILL.md`. Do not re-run discovery here — use the values already established. Substitute the correct values for the agent the user chose:
>
> | Variable | IBM Bob | GitHub Copilot (VS Code) |
> | --- | --- | --- |
> | `AGENT` | `bob` | `github-copilot` |
> | `CONFIG_DIR` | `.bob` | `.vscode` |
> | `MCP_CONFIG_FILE` | `.bob/mcp.json` | `.vscode/mcp.json` |
> | `MCP_TEMPLATE_FILE` | `mcp.bob.json` | `mcp.vscode.json` |

## Servers Available

| Server package | Folder under `mcp-servers/` |
| --- | --- |
| `apic-analytics-mcp-server` | `analytics` |
| `apic-governance-mcp-server` | `governance` |
| `apic-management-mcp-server` | `management` |
| `apic-genai-spec-mcp-server` | `genai-spec` |
| `ai-gateway-management-mcp-server` | `ai-gateway-management` |

## Prerequisites Verification

Before starting, verify the following are met:

1. **Node.js ≥ 24 and npm**:

   ```bash
   node --version
   npm --version
   ```

   Download from [https://nodejs.org/](https://nodejs.org/) if not present. **Node.js version 24 is required.**

2. **Disk space**: At least 500 MB free.

**Validation Checkpoint**: All prerequisites must pass before proceeding.

## Installation Workflow

### Step 1: Show Server Selection

Using `APIC_PRESENT` from the discovery step, build the server list. The server-to-folder mapping is:

| Server package | Folder |
| --- | --- |
| `apic-analytics-mcp-server` | `analytics` |
| `apic-governance-mcp-server` | `governance` |
| `apic-management-mcp-server` | `management` |
| `apic-genai-spec-mcp-server` | `genai-spec` |
| `ai-gateway-management-mcp-server` | `ai-gateway-management` |

Record `ALREADY_INSTALLED`: the list of servers already configured in `MCP_CONFIG_FILE`.

**Single-server shortcut**: If `APIC_PRESENT` contains exactly one folder, skip the checklist entirely and proceed directly to Step 2 with that server as the sole `SELECTED_SERVERS` entry.

Otherwise, present the checklist below showing **only** the servers whose folders appear in `APIC_PRESENT`. Pre-check any server that is already in `ALREADY_INSTALLED` and label it `[installed]`.

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Available IBM API Connect MCP Servers
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select the servers you want to configure.
Servers marked [installed] are already present in your MCP config file.

[ ] <server-name>
    <description>

[ ] <server-name>
    <description>
    ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select at least one server to continue.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Server descriptions for use in the checklist:

| Server | Description |
| --- | --- |
| `apic-analytics-mcp-server` | Analytics tools for API usage, latency, and status monitoring |
| `apic-governance-mcp-server` | Governance tools for API validation and rule management |
| `apic-management-mcp-server` | Management tools for APIs, products, catalogs, and subscriptions |
| `apic-genai-spec-mcp-server` | GenAI MCP tools for enhancing, updating, generating and fixing OpenAPIs and Policy files |
| `ai-gateway-management-mcp-server` | AI Gateway tools for LLM provider management and REST-to-MCP conversion |

**Rules**:

- Only show servers whose folder is present in `APIC_PRESENT`.
- The user must select at least one server.
- Record `SELECTED_SERVERS` (server package names) and `SELECTED_FOLDERS` (corresponding folder names).

**Validation Checkpoint**: Every selected server's folder exists under `<MCP_SERVERS_DIR>` and contains a `<MCP_TEMPLATE_FILE>` and a `*.tgz` file.

### Step 2: Create Workspace Configuration Directory

```bash
# All platforms (run from workspace root)
mkdir -p <CONFIG_DIR>
```

Substitute `<CONFIG_DIR>` with the value of `CONFIG_DIR` for the chosen agent (`.bob` for IBM Bob, `.vscode` for GitHub Copilot).

### Step 3: Initialize MCP Configuration File

Check if `<MCP_CONFIG_FILE>` exists. If not, create it with the correct empty structure for the chosen agent:

| `AGENT` | Empty initialiser |
| --- | --- |
| `bob` (and other `mcpServers` agents) | `{"mcpServers":{}}` |
| `github-copilot` | `{"servers":{}}` |

```bash
# macOS/Linux  (CONFIG_DIR = .bob or .vscode)
[ ! -f <MCP_CONFIG_FILE> ] && echo '<initialiser>' > <MCP_CONFIG_FILE>

# Windows (PowerShell)
if (-not (Test-Path "<CONFIG_DIR>\mcp.json")) {
  '<initialiser>' | Out-File -FilePath "<CONFIG_DIR>\mcp.json" -Encoding utf8
}
```

### Step 4: Install API Studio CLI (`ai-gateway-management-mcp-server` only)

If `ai-gateway-management-mcp-server` is among the selected servers, verify the CLI by running:

```bash
apic schema list
```

Interpret the result as follows:

| Result | Meaning | Action |
| --- | --- | --- |
| Returns a list of assets and versions | `apim-cli` installed correctly | ✅ Proceed |
| `error: unknown command 'schema'` | Old `apic` toolkit installed — `schema` command not available | Run `apic version --debug`; if output identifies as _APIConnect toolkit client_, ask the user to upgrade to the latest toolkit — **HARD STOP** until they confirm the upgrade, then re-run `apic schema list` |
| `error: unknown command 'version'` | `apim-cli` present but outdated | Run `npm i -g @apistudio/apim-cli@latest`, then re-run `apic schema list` |
| `command not found: apic` | CLI not installed | Run `npm i -g @apistudio/apim-cli@latest`, then re-run `apic schema list` |

NOTE: The `bin` command to invoke the APIM CLI package is `apic`.

If `apic schema list` does not return a valid asset list after following the steps above — **HARD STOP**. Do not proceed. Ask the user to resolve the CLI issue first.

### Step 5: Parse Server Configurations

For each selected server, read its template using the `MCP_TEMPLATE_FILE` variable set during Agent Selection in `SKILL.md`. The local path is:

```text
<MCP_SERVERS_DIR>/<service-folder>/<MCP_TEMPLATE_FILE>
```

Service folder mapping:

| Server | Folder |
| --- | --- |
| `apic-analytics-mcp-server` | `analytics` |
| `apic-governance-mcp-server` | `governance` |
| `apic-management-mcp-server` | `management` |
| `apic-genai-spec-mcp-server` | `genai-spec` |
| `ai-gateway-management-mcp-server` | `ai-gateway-management` |

All servers in this group share the same set of credentials:

| Environment variable | Description | Required |
| --- | --- | --- |
| `API_KEY` | API key for your API Connect instance | ✅ |
| `client_id` | Client ID configured on your API Connect instance | ✅ |
| `client_secret` | Client secret configured on your API Connect instance | ✅ |
| `PROVIDER_ORG` | Provider organization name | ✅ |
| `APIC_PLATFORM_URL` | Platform endpoint URL | ✅ |
| `APIC_MANAGEMENT_URL` | Management endpoint URL | ✅ |
| `NODE_TLS_REJECT_UNAUTHORIZED` | Set to `0` to disable cert validation (self-signed certs), `1` to enable | optional, default `1` |

**Validation Checkpoint**: All selected template files are valid JSON and parseable.

### Step 6: Identify Deployment Type

Ask the user which deployment model they are using:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Which IBM API Connect deployment are you using?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] Software as a Service (SaaS)
    — IBM-hosted; you log in at a reserved.ibm.com or ibm.com subdomain

[2] IBM webMethods Hybrid Integration (IWHI)
    — Accessed through the IBM Technology Zone or a Flow Pilot environment

[3] On-premises
    — Installed in your own data center or private cloud (OpenShift, VMware, etc.)

Enter your choice [1, 2, or 3]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Store the answer as `DEPLOYMENT_TYPE`:

| Choice | Value |
| --- | --- |
| 1 | `saas` |
| 2 | `iwhi` |
| 3 | `on-prem` |

**Validation Checkpoint**: `DEPLOYMENT_TYPE` is set to `saas`, `iwhi`, or `on-prem` before proceeding.

After storing `DEPLOYMENT_TYPE`, immediately display the matching credential guide below — show **only** the section that applies.

---

#### How to find your credentials (Software as a Service — SaaS)

> Show this section when `DEPLOYMENT_TYPE` is `saas`.

**APIC Management URL (`APIC_MANAGEMENT_URL`)**

Navigate to your API Connect instance. The APIC Management URL is the base URL of your API Manager — for example:
`https://api-manager.d-v12e.apiconnect.dev.automation.ibm.com`
The APIC Management URL depends on the region where your SaaS instance is provisioned. Use the table below to find yours:

| Region | AWS Region | APIC Management URL |
| --- | --- | --- |
| N. Virginia | us-east-1 | `https://api-manager.us-east-a.apiconnect.automation.ibm.com` |
| Frankfurt | eu-central-1 | `https://api-manager.eu-central-a.apiconnect.automation.ibm.com` |
| London | eu-west-2 | `https://api-manager.eu-west-a.apiconnect.automation.ibm.com` |
| Mumbai | ap-south-1 | `https://api-manager.ap-south-a.apiconnect.automation.ibm.com` |
| Sydney | ap-southeast-2 | `https://api-manager.ap-southeast-a.apiconnect.automation.ibm.com` |
| Jakarta | ap-southeast-3 | `https://api-manager.ap-southeast-b.apiconnect.automation.ibm.com` |


**API Key (`API_KEY`)**

1. Log in to the APIC Management URL.
2. Click the **profile icon** (your initials) in the top-right corner of the header.
3. Select **My API Keys** from the dropdown.
4. Either use an existing API key from the list, or click **Add** (top-right corner of the page) to create a new one.
   - Give it a title and description.
   - Set a suitable timeout (e.g. 8000 Hours).
   - ✅ Check **Enable multiple use**.
   - Click **Create**.
5. Copy the displayed key value — this is your `API_KEY`.

**Platform URL (`APIC_PLATFORM_URL`)**

On the **My API Keys** page, scroll down to the **Authenticating for the platform REST API** section. You will see a `curl` command similar to:

```
curl -X POST https://platform-api.d-v12e.apiconnect.dev.automation.ibm.com/api/token ...
```

Use **only the base URL without the `/api/token` path** as your `APIC_PLATFORM_URL`. Example:
`https://platform-api.d-v12e.apiconnect.dev.automation.ibm.com`

**Client ID and Client Secret (`client_id` / `client_secret`)**

In the same **Authenticating for the platform REST API** `curl` block you will find `client_id` and `client_secret` fields highlighted in the request body. Copy both values.

**Provider Org (`PROVIDER_ORG`)**

The provider org name is shown in the **top-left breadcrumb** of the API Manager header (e.g. `ibm`).

---

#### How to find your credentials (IBM webMethods Hybrid Integration — IWHI)

> Show this section when `DEPLOYMENT_TYPE` is `iwhi`.

**APIC Management URL (`APIC_MANAGEMENT_URL`)**

Navigate to your IBM webMethods Hybrid Integration (IWHI) instance in the IBM Technology Zone or Flow Pilot environment. The APIC Management URL is the base URL of your API Manager — for example:
`https://prod608833.m-yqb-c1.apiconnect.ipaas.test.automation.ibm.com`

**API Key (`API_KEY`)**

1. Log in to the APIC Management URL.
2. Click the **profile icon** (your initials) in the top-right corner of the header.
3. Select **My API Keys** from the dropdown.
4. Either use an existing API key from the list, or click **Add** (top-right corner of the page) to create a new one.
   - Give it a title and description.
   - Set a suitable timeout (e.g. 8000 Hours).
   - ✅ Check **Enable multiple use**.
   - Click **Create**.
5. Copy the displayed key value — this is your `API_KEY`.

**Platform URL (`APIC_PLATFORM_URL`)**

On the **My API Keys** page, scroll down to the **Authenticating for the platform REST API** section. You will see a `curl` command similar to:

```
curl -X POST https://platform-api.m-yqb.apiconnect.ipaas.test.automation.ibm.com/api/token ...
```

Use **only the base URL without the `/api/token` path** as your `APIC_PLATFORM_URL`. Example:
`https://platform-api.m-yqb.apiconnect.ipaas.test.automation.ibm.com`

**Client ID and Client Secret (`client_id` / `client_secret`)**

In the same **Authenticating for the platform REST API** `curl` block you will find `client_id` and `client_secret` fields highlighted in the request body. Copy both values.

**Provider Org (`PROVIDER_ORG`)**

From the API Connect home page, goto Settings in the left navigation. Under Overview, you can get the Organisation name (e.g. `ibm`).

---

#### How to find your credentials (On-premises)

> Show this section when `DEPLOYMENT_TYPE` is `on-prem`.

**APIC Management URL (`APIC_MANAGEMENT_URL`)**

The APIC Management URL is the base URL of your API Manager — for example:
`https://manager.studio2708.joker.dev.ciondemand.com`

**Platform URL (`APIC_PLATFORM_URL`)**

The Platform URL typically follows the pattern `https://api.<host>`, for example:
`https://api.studio2708.joker.dev.ciondemand.com`

> Note: The exact URL may vary depending on how the platform API is configured in your on-premises environment. Confirm with your administrator if unsure.

**Provider Org (`PROVIDER_ORG`)**

The provider org name is shown in the **top-right corner** of the API Manager header (e.g. `ibm`).

**API Key (`API_KEY`)**

1. Navigate to `<APIC_MANAGEMENT_URL>/manager/<PROVIDER_ORG>/apikeys` — for example:
   `https://manager.studio2708.joker.dev.ciondemand.com/manager/ibm/apikeys`
2. Either use an existing API key from the list, or click **Add** (top-right corner) to create a new one.
   - ✅ Enable **multiple use**.
3. Copy the displayed key value — this is your `API_KEY`.

**Client ID and Client Secret (`client_id` / `client_secret`)**

1. From the API Manager **Home** page, click **Download Tools** (in the "Get started" panel on the right).
2. Under **Toolkit**, click **Download** next to **Toolkit credentials**.
3. Open the downloaded `credentials.json` file. Locate the `toolkit` section:

```json
{
  "toolkit": {
    "endpoint": "https://api.studio2708.joker.dev.ciondemand.com/api",
    "client_id": "<your-client-id>",
    "client_secret": "<your-client-secret>"
  }
}
```

4. Use the `client_id` and `client_secret` from the `toolkit` section.

---

### Step 7: Choose Configuration Mode

**Single-server shortcut**: If `SELECTED_SERVERS` contains exactly one server, skip this step entirely and proceed directly to Step 8 using Mode 2 (shared values).

Otherwise, ask the user how they want to provide configuration values:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Configuration Mode
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You have selected N servers. All share the same API Connect credentials.

[1] Configure all servers at once (recommended)
    — Provide the shared credential values once
    — Applied to all selected servers automatically

[2] Configure servers individually
    — Provide values for each server one at a time
    — Use if servers need different credentials

Enter your choice [1 or 2]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Collect Configuration Values

**IMPORTANT**: Ask for each value **ONE AT A TIME**. Wait for the user to respond before asking the next. Never ask for all values at once or request JSON.

**Secret values** (`API_KEY`, `client_secret`) **must NOT be collected here** for either agent:
- `mcpServers`-based agents → write `REPLACE_ME`; line numbers reported in Step 12
- GitHub Copilot → leave as `${input:api-key}` / `${input:cSecret}`; VS Code prompts securely

`client_id` is **not** a secret (it is not marked `password: true` in the VS Code template) and **must** be collected for both agents.

#### Mode 1 (recommended) — Shared values across all servers

Since all selected servers use the same credentials, ask once:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
API Connect Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

These values will be applied to all N selected servers.

APIC_PLATFORM_URL (required):
Enter your API Connect platform URL: _

[wait for response]

APIC_MANAGEMENT_URL (required):
Enter your API Connect management URL: _

[wait for response]

PROVIDER_ORG (required):
Enter your provider organization name: _

[wait for response]

client_id (required):
Enter your client ID: _

[wait for response]

NODE_TLS_REJECT_UNAUTHORIZED (optional, default: 1):
Enter 0 to disable certificate validation or press Enter to keep the default (1): _

[wait for response]

✓ Configuration values collected.
  API_KEY and client_secret will be set to "REPLACE_ME" (mcpServers-based agents) or "${input:...}" (GitHub Copilot) —
  you will be shown where to update them after setup.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Mode 2 — Individual server configuration

For each selected server in turn, ask for the same values above (URLs, PROVIDER_ORG, client_id, NODE_TLS_REJECT_UNAUTHORIZED), labelling the server number clearly (e.g. `[1/3] Configuring: apic-analytics-mcp-server`). Do not prompt for `API_KEY` or `client_secret`.

**Critical Rules**:

- ❌ DO NOT ask for multiple values in a single prompt
- ❌ DO NOT ask the user to provide JSON or structured data
- ❌ DO NOT ask for `API_KEY` or `client_secret`
- ✅ DO ask ONE value at a time
- ✅ DO wait for user response after each prompt
- ✅ DO validate each value before moving on (URLs must start with `http://` or `https://`, strings must be non-empty)
- ✅ DO show defaults for optional fields

**Validation Checkpoint**: All required non-secret values (including `client_id`) collected for every selected server before proceeding.

### Step 9: Generate Absolute Paths

`MCP_SERVERS_DIR` is already an absolute path set in `SKILL.md`. Confirm it resolves correctly:

```bash
# macOS/Linux
INSTALL_DIR=$(cd "<MCP_SERVERS_DIR>" && pwd)

# Windows (PowerShell)
$INSTALL_DIR = (Resolve-Path "<MCP_SERVERS_DIR>").Path
```

For each selected server, the `.tgz` path is:

```text
${INSTALL_DIR}/<service-folder>/<server-package>-<version>.tgz
```

Examples:

- `/Users/alice/flow-pilot/IBM_API_Connect_Flow_Pilot/mcp-servers/analytics/apic-analytics-mcp-server-0.0.1.tgz`
- `/Users/alice/flow-pilot/IBM_API_Connect_Flow_Pilot/mcp-servers/ai-gateway-management/ai-gateway-management-mcp-server-0.0.1.tgz`

**Validation Checkpoint**: Every `.tgz` file for the selected servers exists at the resolved path.

### Step 10: Update `<MCP_CONFIG_FILE>`

1. Read and parse the existing `<MCP_CONFIG_FILE>`.
2. For each selected server, read its `<MCP_TEMPLATE_FILE>` from `<MCP_SERVERS_DIR>/<service-folder>/<MCP_TEMPLATE_FILE>`. Substitute all collected values and the resolved `.tgz` path into the template.
3. Secrets not collected during setup: use `REPLACE_ME` (`mcpServers`-based agents) or leave as the original `${input:xxx}` reference (GitHub Copilot).
4. Merge each server's block into `<MCP_CONFIG_FILE>`, preserving any existing entries.
5. Write the result with indentation consistent with the template file.

**Example output** (one server shown):

```json
{
  "mcpServers": {
    "apic-analytics-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "-p",
        "/Users/alice/flow-pilot/mcp-servers/analytics/apic-analytics-mcp-server-0.0.1.tgz",
        "apic-analytics-mcp-server"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "1",
        "PROVIDER_ORG": "my-org",
        "API_KEY": "REPLACE_ME",
        "client_id": "my-client-id",
        "client_secret": "REPLACE_ME",
        "APIC_PLATFORM_URL": "https://platform.example.com",
        "APIC_MANAGEMENT_URL": "https://manager.example.com"
      }
    }
  }
}
```

**Validation Checkpoint**: Validate the final JSON:

```bash
# macOS/Linux
cat <MCP_CONFIG_FILE> | python -m json.tool > /dev/null && echo "Valid JSON"

# Windows (PowerShell)
try { Get-Content "<CONFIG_DIR>\mcp.json" | ConvertFrom-Json; Write-Host "Valid JSON" } catch { Write-Host "Invalid JSON" }
```

### Step 11: Verify Installation

Check that every selected server is correctly set up:

1. ✓ `.tgz` file exists at the configured path
2. ✓ `<MCP_CONFIG_FILE>` is valid JSON
3. ✓ **`mcpServers`-based agents only**: No `<placeholder>` angle-bracket values remain in `<MCP_CONFIG_FILE>` (the `REPLACE_ME` for `API_KEY` and `client_secret` are expected and intentional)
4. ✓ **GitHub Copilot only**: Only `${input:api-key}` and `${input:cSecret}` remain as `${input:...}` references; all other env values and `args[2]` are hardcoded strings
5. ✓ If `ai-gateway-management-mcp-server` was selected: `apic schema list` returns a valid asset list

### Step 12: Report Installation Status

After setup, scan `<MCP_CONFIG_FILE>` for any remaining secrets that still need user action — either `REPLACE_ME` values (Bob) or `${input:xxx}` references for `password: true` fields (GitHub Copilot). List each one with its line number and the action required.

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IBM API Connect MCP Server Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent              : <AGENT display name>
MCP Servers Path   : <MCP_SERVERS_DIR>
Configuration File : <MCP_CONFIG_FILE>

Configured Servers (N configured):
  ✓ <server-1>
  ✓ <server-2>
  ...

Skipped (not selected):
  - <server-N>
  ...

[If ai-gateway-management-mcp-server was selected:]
Additional Dependencies:
  ✓ @apistudio/apim-cli installed globally

⚠️  Secrets requiring action in <MCP_CONFIG_FILE>:
  Line <N>  — <field-name>  → <action: replace REPLACE_ME / will be prompted by agent on first use>
  ...
  (Omit this block if no secrets require action.)

Next Steps:
  1. Update any secrets listed above
  2. Reload your agent to pick up the new MCP servers (restart your agent, or open <MCP_CONFIG_FILE> and click "Start" above each server entry if your agent supports it)
  3. Verify servers appear in your agent's MCP server list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Important Rules

1. **Use discovered paths**: `MCP_SERVERS_DIR` and `APIC_PRESENT` are resolved in `SKILL.md` before these instructions run. Do not re-run discovery.
2. **Absolute paths**: Always write the full absolute path of each `.tgz` file into `<MCP_CONFIG_FILE>`. Never use `~` or relative paths.
3. **Preserve existing config**: Never overwrite existing server entries in `<MCP_CONFIG_FILE>` without asking the user first.
4. **No secrets during setup**: Never prompt for `API_KEY`, `client_secret`, or any other secret/token/password during the setup conversation. For `mcpServers`-based agents (Bob, Claude, etc.) write `REPLACE_ME` for every secret field; for GitHub Copilot leave the original `${input:xxx}` reference from the template. In both cases, report the exact line numbers (or input IDs) to the user in the final step.
5. **One value at a time**: All prompts for configuration values must be issued one at a time.
6. **Agent variables**: Use the `AGENT`, `CONFIG_DIR`, and `MCP_CONFIG_FILE` values from the agent-selection step in `SKILL.md` consistently throughout all steps.

## Error Handling

### Missing Service Folder

If a selected server's folder is not found under `<MCP_SERVERS_DIR>`:
1. Warn: `⚠️ <MCP_SERVERS_DIR>/<service-folder>/ was not found.`
2. Ask the user to verify the folder exists or deselect the server.

### Missing `.tgz` File

List the contents of the folder so the user can see what is there. Ask them to verify the server package is present.

### Invalid JSON Configuration

Backup the corrupted file (`<MCP_CONFIG_FILE>.backup`), attempt repair (trailing commas, quote fixes). If repair fails, recreate from the correct empty initialiser for the agent (`{"mcpServers":{}}` for `mcpServers`-based agents; `{"servers":{}}` for GitHub Copilot) and re-apply user values.

### API Studio CLI Installation Failure

**Error**: `npm i -g @apistudio/apim-cli@latest` fails

1. Check npm registry connectivity.
2. Check global prefix is writable: `npm config get prefix`.
3. Retry once. On continued failure, skip and include the manual command in the report:

   ```bash
   npm i -g @apistudio/apim-cli@latest
   ```

### Permission Denied

Check write permissions on `<CONFIG_DIR>` or suggest running from a different workspace directory.

## Maintenance

### Adding More Servers Later

Re-run this skill. The agent will re-detect present servers, pre-check already-configured ones, and let the user add more. Existing config entries are preserved.

### Backup Configuration

```bash
# macOS/Linux  (substitute <CONFIG_DIR> with .bob or .vscode)
cp <CONFIG_DIR>/mcp.json <CONFIG_DIR>/mcp.json.backup

# Windows (PowerShell)
Copy-Item "<CONFIG_DIR>\mcp.json" "<CONFIG_DIR>\mcp.json.backup"
```

### Uninstall

Remove the server entries from `<MCP_CONFIG_FILE>`. The local source files under `<MCP_SERVERS_DIR>` are left untouched.

To remove all IBM API Connect MCP entries, delete the relevant keys from the `mcpServers` (Bob) or `servers` (GitHub Copilot) object in `<MCP_CONFIG_FILE>`, or remove the file entirely if no other servers are configured:

```bash
# macOS/Linux
rm -f <CONFIG_DIR>/mcp.json

# Windows (PowerShell)
Remove-Item -Path "<CONFIG_DIR>\mcp.json" -Force
```
