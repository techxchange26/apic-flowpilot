---
name: setup-agent-kit
description: Initialize IBM API Connect or IBM DataPower Interactive Gateway AI assets — MCP servers and skills
---

Set up all AI assets for your IBM product in this workspace: MCP servers and agent skills. The right set of assets is determined by identifying which agent the user is running and which product they have access to.

## Interaction Style

Whenever this skill needs to ask the user a question or present a selection, output the plain-text prompt shown in this skill. If the agent has a native interactive UI tool (e.g. `ask_followup_question` in IBM Bob), use it instead.

Never print internal state to the chat — variables, resolved paths, detected server lists, routing decisions, and similar bookkeeping are for the agent's internal use only.

## MCP Servers Discovery

Run this discovery step **silently, before any user interaction**. Do not display progress or results yet — the output is used to populate the consent screen in the next step.

Search the workspace for the `mcp-servers` folder:

```bash
# macOS/Linux
find . -type d -name "mcp-servers" -not -path "./__MACOSX/*" 2>/dev/null

# Windows (PowerShell)
Get-ChildItem -Recurse -Directory -Filter "mcp-servers" | Where-Object { $_.FullName -notlike "*\__MACOSX\*" } | Select-Object -ExpandProperty FullName
```

- If exactly one match is found, set `MCP_SERVERS_DIR` to its absolute path and continue.
- If multiple matches are found, present them to the user and ask which one to use:

  ```text
  Multiple mcp-servers folders found. Which one should be used?
  [1] /path/to/first/mcp-servers
  [2] /path/to/second/mcp-servers
  Enter a number: _
  ```

- If no match is found, tell the user:

  > ⚠️ No `mcp-servers` folder was found in this workspace. Please ensure your IBM project package files are present in the current workspace and try again.

  Do not proceed until `MCP_SERVERS_DIR` is resolved.

**Validation Checkpoint**: `MCP_SERVERS_DIR` resolves to a directory that exists on disk before continuing.

### Inspect Present Sub-folders

Once `MCP_SERVERS_DIR` is set, check which of the known sub-folders are present:

```bash
# macOS/Linux
for folder in analytics governance management genai-spec ai-gateway-management interact-gateway-onprem; do
  [ -d "<MCP_SERVERS_DIR>/$folder" ] && echo "PRESENT: $folder"; done; true

# Windows (PowerShell)
foreach ($folder in @("analytics","governance","management","genai-spec","ai-gateway-management","interact-gateway-onprem")) {
  if (Test-Path "<MCP_SERVERS_DIR>\$folder") { Write-Host "PRESENT: $folder" }
}
```

Classify the results into two groups:

| Group | Folder names that belong to it |
|---|---|
| **APIC servers** | `analytics`, `governance`, `management`, `genai-spec`, `ai-gateway-management` |
| **IDIG server** | `interact-gateway-onprem` |

Set:
- `APIC_PRESENT` — list of APIC-group folder names found on disk (may be empty)
- `IDIG_PRESENT` — `true` if `interact-gateway-onprem` was found, otherwise `false`

Build `DETECTED_SERVERS` — the list of entries for all present folders, using this master mapping:

| Folder | Server package name | Consent screen description |
|---|---|---|
| `analytics` | `apic-analytics-mcp-server` | API usage, latency, and status analytics |
| `governance` | `apic-governance-mcp-server` | API validation and rule management |
| `management` | `apic-management-mcp-server` | APIs, products, catalogs, and subscriptions |
| `genai-spec` | `apic-genai-spec-mcp-server` | GenAI spec generation and enhancement |
| `ai-gateway-management` | `ai-gateway-management-mcp-server` | LLM provider management, REST-to-MCP conversion |
| `interact-gateway-onprem` | `interact-gateway-onprem-mcp-server` | Standalone DataPower Gateway integration |

Each entry in `DETECTED_SERVERS` carries the server package name and its description. Do **not** display anything to the user yet. Proceed immediately to the consent check.

## New Installation Consent

Using the config files and `DETECTED_SERVERS` from the previous step, determine whether the consent screen must be shown:

1. Read each of `.bob/mcp.json` and `.vscode/mcp.json` that exists on disk.
2. Scan their content for the presence of any server package name from `DETECTED_SERVERS`.
3. If **none** of the detected server names appear in any config file (including the case where neither file exists), this is a new installation — display the consent screen below and wait for the user to confirm before continuing.
4. If at least one detected server name is found in any config file, skip the consent screen entirely.

> A config file that exists but contains none of the known server names (e.g. an empty `{}`, a file for an unrelated project, or a file with only other servers) is treated the same as no file — the consent screen is shown.

Build the MCP Servers section of the consent screen from `DETECTED_SERVERS`: for each entry, render one bullet as `• <server package name>  — <description>`. Show **only** servers that are in `DETECTED_SERVERS`. If more than one APIC server is detected, append the note shown below so the user knows they can choose which to install.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IBM Agent Kit — Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This setup will install and configure the following assets in your workspace:

  MCP Servers detected in mcp-servers/
    • <server-name-1>  — <description>
    • <server-name-2>  — <description>
    ...
    (If more than one APIC server is listed, you will be able to choose which to install in the next step.)

  Configuration files created
    • .bob/mcp.json    (for IBM Bob)
    • .vscode/mcp.json (for GitHub Copilot / VS Code)
    (Only the file for the agent you select will be created.)

  CLI dependency (include this section only if `ai-gateway-management-mcp-server` or `interact-gateway-onprem-mcp-server` is in DETECTED_SERVERS — omit entirely otherwise)
    • @apistudio/apim-cli  (installed globally via npm)

  Secrets handling
    • Sensitive values (API keys, passwords, tokens) will NOT be entered during setup.
    • Dummy placeholder values will be written to the config file.
    • You will be shown the exact line numbers to edit after setup completes.

Do you want to proceed with the installation?
Type "yes" to continue or "no" to cancel: _
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If the user types anything other than "yes" (case-insensitive), stop and inform them they can re-run the setup at any time.

## Agent Selection

After consent is confirmed (or skipped), ask the user which AI agent they are using:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Which AI agent are you setting this up for?

[1] IBM Bob
    - Configuration folder : .bob/
    - MCP config file      : .bob/mcp.json

[2] GitHub Copilot (VS Code)
    - Configuration folder : .vscode/
    - MCP config file      : .vscode/mcp.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for the user's answer, then set the following variables internally:

| Variable | Bob | GitHub Copilot |
|---|---|---|
| `AGENT` | `bob` | `github-copilot` |
| `CONFIG_DIR` | `.bob` | `.vscode` |
| `MCP_CONFIG_FILE` | `.bob/mcp.json` | `.vscode/mcp.json` |
| `MCP_TEMPLATE_FILE` | `mcp.bob.json` | `mcp.vscode.json` |

Do not proceed until the agent choice is confirmed.

## Product Selection

Use the table below to determine the next action. Do not ask the product question unless the table says so.

| `APIC_PRESENT` | `IDIG_PRESENT` | Action |
|---|---|---|
| Non-empty | `false` | **Go straight to `apic.md`** — no product question |
| Empty | `true` | **Go straight to `interact-gateway.md`** — no product question |
| Non-empty | `true` | **Ask the product question** (see below) |
| Empty | `false` | ⚠️ No known servers found — tell the user and stop |

### Product Question (only when `APIC_PRESENT` is non-empty AND `IDIG_PRESENT` is true)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Which IBM product are you setting up AI assets for?

[1] IBM API Connect (APIC)
    - Full API Connect instance (SaaS or on-prem v10/v12)
    - Sets up: <list only the server names in APIC_PRESENT>

[2] IBM DataPower Interactive Gateway (IDIG) — standalone / on-prem
    - Standalone Interact Gateway deployment without a full API Connect instance
    - Sets up: interact-gateway-onprem MCP server
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for the user's answer before proceeding.

**Rules**:
- If the user answers **1** (IBM API Connect), follow all steps in `apic.md`. Pass `MCP_SERVERS_DIR` and `APIC_PRESENT` into those instructions.
- If the user answers **2** (Interact Gateway standalone), follow all steps in `interact-gateway.md`. Pass `MCP_SERVERS_DIR` into those instructions.
- Carry `AGENT`, `CONFIG_DIR`, `MCP_CONFIG_FILE`, and `MCP_TEMPLATE_FILE` into whichever product instructions are followed.
- If the user is unsure which product to choose, briefly describe the difference:
  - IBM API Connect is the full API management platform — if they have an API manager URL and API keys they are an APIC user.
  - Interact Gateway standalone is a self-contained DataPower Gateway deployment — if they only have a gateway base URL, username, and password, they are an on-prem Interact Gateway user.
- Do not proceed to any installation steps until the routing is confirmed (either automatically or by user answer).
