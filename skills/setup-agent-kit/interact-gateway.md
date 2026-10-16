---
name: interact-gateway
description: Install and configure the IBM DataPower Interactive Gateway on-premises MCP server (interact-gateway-onprem-mcp-server)
---

# Interact Gateway MCP Server setup

Install and configure the `interact-gateway-onprem-mcp-server` for a standalone IBM DataPower Interactive Gateway deployment.

> **Agent context**: These instructions use the variables `AGENT`, `CONFIG_DIR`, `MCP_CONFIG_FILE`, `MCP_TEMPLATE_FILE`, and `MCP_SERVERS_DIR` set during the Agent Selection and MCP Servers Discovery steps in `SKILL.md`. Do not re-run discovery here — use the values already established.

## Server Installed

| Server package | Folder under `mcp-servers/` |
| --- | --- |
| `interact-gateway-onprem-mcp-server` | `interact-gateway-onprem` |

**Required credentials** (no IBM API Connect instance needed):

| Environment variable | Description |
| --- | --- |
| `STANDALONE_URL` | Base URL of your standalone Interact Gateway instance (e.g. `https://gateway.example.com`) |
| `STANDALONE_USERNAME` | Username for authentication |
| `STANDALONE_PASSWORD` | Password for authentication |
| `NODE_TLS_REJECT_UNAUTHORIZED` | `0` to disable cert validation (self-signed certs), `1` to enable (default `1`) |

## Prerequisites Verification

1. **Node.js ≥ 24 and npm**:

   ```bash
   node --version
   npm --version
   ```

   Download from [https://nodejs.org/](https://nodejs.org/) if not present. **Node.js version 24 is required.**

2. **Disk space**: At least 200 MB free.

**Validation Checkpoint**: All prerequisites must pass before proceeding.

## Installation Workflow

### Step 1: Create Workspace Configuration Directory

```bash
# All platforms (run from workspace root)
mkdir -p <CONFIG_DIR>
```

Substitute `<CONFIG_DIR>` with the value of `CONFIG_DIR` for the chosen agent (`.bob` for IBM Bob, `.vscode` for GitHub Copilot).

### Step 2: Initialize MCP Configuration File

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

### Step 3: Install API Studio CLI

Verify the CLI by running:

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

NOTE: The `bin` command to invoke the APIM CLI is `apic`.

If `apic schema list` does not return a valid asset list after following the steps above — **HARD STOP**. Do not proceed. Ask the user to resolve the CLI issue first.

### Step 4: Collect Configuration Values

**IMPORTANT**: Ask for each value **ONE AT A TIME**. Wait for the user to respond before asking the next. Never ask for all values at once or request JSON.

**`STANDALONE_PASSWORD` must NOT be collected during setup** for any agent. For `mcpServers`-based agents write `REPLACE_ME`; for GitHub Copilot leave `${input:password}` so VS Code prompts securely. Report the line number to the user after setup (see Step 8).

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Interact Gateway On-Premises Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STANDALONE_URL (required):
Enter your Interact Gateway base URL (e.g. https://gateway.example.com): _

[wait for response]

STANDALONE_USERNAME (required):
Enter your Interact Gateway username: _

[wait for response]

NODE_TLS_REJECT_UNAUTHORIZED (optional, default: 1):
Enter 0 to disable certificate validation or press Enter to keep the default (1): _

[wait for response]

✓ Configuration values collected.
  STANDALONE_PASSWORD will be handled per the agent's secret convention —
  you will be shown where to update it after setup.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Critical Rules**:

- ❌ DO NOT ask for multiple values in a single prompt
- ❌ DO NOT ask the user to provide JSON or structured data
- ❌ DO NOT ask for the password or any other secret/credential value
- ✅ DO ask ONE value at a time
- ✅ DO wait for user response after each prompt
- ✅ DO validate URLs (must start with `http://` or `https://`) and non-empty strings
- ✅ DO show defaults for optional fields

**Validation Checkpoint**: All required non-secret values collected before proceeding.

### Step 5: Resolve `.tgz` Path

Find the `.tgz` file inside the `interact-gateway-onprem` service folder:

```bash
# macOS/Linux
ls "<MCP_SERVERS_DIR>/interact-gateway-onprem"/*.tgz

# Windows (PowerShell)
Get-ChildItem "<MCP_SERVERS_DIR>\interact-gateway-onprem" -Filter "*.tgz"
```

The full path used in the config will be:

```text
<MCP_SERVERS_DIR>/interact-gateway-onprem/interact-gateway-onprem-mcp-server-<version>.tgz
```

Example: `/Users/alice/flow-pilot/.agents/mcp-servers/interact-gateway-onprem/interact-gateway-onprem-mcp-server-0.0.1.tgz`

**Validation Checkpoint**: The `.tgz` file exists at the resolved path.

### Step 6: Update `<MCP_CONFIG_FILE>`

1. Read and parse the existing `<MCP_CONFIG_FILE>`.
2. Read the `<MCP_TEMPLATE_FILE>` from `<MCP_SERVERS_DIR>/interact-gateway-onprem/<MCP_TEMPLATE_FILE>`. Substitute all collected values and the resolved `.tgz` path into the template.
3. Secrets not collected during setup: use `REPLACE_ME` (`mcpServers`-based agents) or leave as the original `${input:xxx}` reference (GitHub Copilot).
4. Merge the server block into `<MCP_CONFIG_FILE>`, preserving any existing entries.
5. Write the result with indentation consistent with the template file.

**Example output — IBM Bob** (`AGENT = bob`):

```json
{
  "mcpServers": {
    "interact-gateway-onprem-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "-p",
        "/Users/alice/flow-pilot/.agents/mcp-servers/interact-gateway-onprem/interact-gateway-onprem-mcp-server-0.0.1.tgz",
        "interact-gateway-onprem-mcp-server"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "1",
        "STANDALONE_URL": "https://gateway.example.com",
        "STANDALONE_USERNAME": "alice",
        "STANDALONE_PASSWORD": "REPLACE_ME"
      }
    }
  }
}
```

**Example output — GitHub Copilot** (`AGENT = github-copilot`):

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "username",
      "description": "Standalone Username",
      "password": false
    },
    {
      "type": "promptString",
      "id": "password",
      "description": "Standalone password",
      "password": true
    },
    {
      "type": "promptString",
      "id": "tarPath",
      "description": "Path to NPM package tar file",
      "password": false
    },
    {
      "type": "promptString",
      "id": "standaloneUrl",
      "description": "Standalone Platform Base URL",
      "password": false
    },
    {
      "type": "promptString",
      "id": "validateCertificates",
      "description": "Whether to validate certificates for Standalone instance, set to '0' to disable validation or '1' to enable validation. Should be set to '0' if using self-signed certificates.",
      "required": false,
      "password": false,
      "default": "1"
    }
  ],
  "servers": {
    "interact-gateway-onprem-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "-p",
        "/Users/alice/flow-pilot/.agents/mcp-servers/interact-gateway-onprem/interact-gateway-onprem-mcp-server-0.0.1.tgz",
        "interact-gateway-onprem-mcp-server"
      ],
      "env": {
        "STANDALONE_USERNAME": "${input:username}",
        "STANDALONE_PASSWORD": "${input:password}",
        "STANDALONE_URL": "${input:standaloneUrl}",
        "NODE_TLS_REJECT_UNAUTHORIZED": "${input:validateCertificates}"
      }
    }
  }
}
```

> ⚠️ Use **only** the example that matches your `AGENT` value. Never write `mcpServers` for GitHub Copilot or `servers`/`inputs` for IBM Bob.

**Validation Checkpoint**: Validate the final JSON:

```bash
# macOS/Linux
cat <MCP_CONFIG_FILE> | python -m json.tool > /dev/null && echo "Valid JSON"

# Windows (PowerShell)
try { Get-Content "<CONFIG_DIR>\mcp.json" | ConvertFrom-Json; Write-Host "Valid JSON" } catch { Write-Host "Invalid JSON" }
```

### Step 7: Verify Installation

1. ✓ `.tgz` file exists at the configured path
2. ✓ `<MCP_CONFIG_FILE>` is valid JSON
3. ✓ No unresolved `<placeholder>` angle-bracket values remain (`REPLACE_ME` and `${input:xxx}` password references are expected and intentional)
4. ✓ `apic schema list` returns a valid asset list

### Step 8: Report Installation Status

After setup, scan `<MCP_CONFIG_FILE>` for any remaining secrets that still need user action — either `REPLACE_ME` values (`mcpServers`-based agents) or `${input:xxx}` references for `password: true` fields (GitHub Copilot). List each one with its line number and the action required.

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Interact Gateway On-Premises MCP Server Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent              : <AGENT display name>
MCP Servers Path   : <MCP_SERVERS_DIR>
Configuration File : <MCP_CONFIG_FILE>

Configured Server:
  ✓ interact-gateway-onprem-mcp-server

Additional Dependencies:
  ✓ @apistudio/apim-cli installed globally

⚠️  Secrets requiring action in <MCP_CONFIG_FILE>:
  Line <N>  — <field-name>  → <action: replace REPLACE_ME / will be prompted by agent on first use>
  ...
  (Omit this block if no secrets require action.)

Next Steps:
  1. Update any secrets listed above
  2. Reload your agent to pick up the new MCP server (restart your agent, or open <MCP_CONFIG_FILE> and click "Start" above the server entry if your agent supports it)
  3. Verify the server appears in your agent's MCP server list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Important Rules

1. **Use discovered paths**: `MCP_SERVERS_DIR` is resolved in `SKILL.md` before these instructions run. Do not re-run discovery.
2. **Absolute paths**: Always write the full absolute path of the `.tgz` file into `<MCP_CONFIG_FILE>`. Never use `~` or relative paths.
3. **Preserve existing config**: Never overwrite existing server entries in `<MCP_CONFIG_FILE>` without asking the user first.
4. **No secrets during setup**: Never prompt for `STANDALONE_PASSWORD` or any other secret/token/password during the setup conversation. For `mcpServers`-based agents (Bob, Claude, etc.) write `REPLACE_ME` for every secret field; for GitHub Copilot leave the original `${input:xxx}` reference from the template. In both cases, report the exact line numbers (or input IDs) to the user in the final step.
5. **One value at a time**: All prompts for configuration values must be issued one at a time.
6. **Execution order**: Complete Step 3 (APIM CLI) before collecting configuration values in Step 4.
7. **Agent variables**: Use the `AGENT`, `CONFIG_DIR`, and `MCP_CONFIG_FILE` values from the agent-selection step in `SKILL.md` consistently throughout all steps.

## Error Handling

### Missing `interact-gateway-onprem` Folder

If `<MCP_SERVERS_DIR>/interact-gateway-onprem/` does not exist, warn the user and ask them to verify the folder is present before continuing.

### Missing `.tgz` File

List the contents of the `interact-gateway-onprem` folder so the user can see what is there. Ask them to verify the server package is present.

### Invalid JSON Configuration

Backup the corrupted file (`<MCP_CONFIG_FILE>.backup`), attempt repair (trailing commas, quote fixes). If repair fails, recreate from the correct empty initialiser for the agent (`{"mcpServers":{}}` for IBM Bob; `{"servers":{}}` for GitHub Copilot) and re-apply user values.

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

### Backup Configuration

```bash
# macOS/Linux  (substitute <CONFIG_DIR> with .bob or .vscode)
cp <CONFIG_DIR>/mcp.json <CONFIG_DIR>/mcp.json.backup

# Windows (PowerShell)
Copy-Item "<CONFIG_DIR>\mcp.json" "<CONFIG_DIR>\mcp.json.backup"
```

### Uninstall

Remove the server entry from `<MCP_CONFIG_FILE>`. The local source files under `<MCP_SERVERS_DIR>` are left untouched.

```bash
# macOS/Linux  (substitute <CONFIG_DIR> with .bob or .vscode)
rm -rf ~/apic-mcp && rm -f <CONFIG_DIR>/mcp.json

# Windows (PowerShell)
Remove-Item -Path "$env:USERPROFILE\apic-mcp" -Recurse -Force
Remove-Item -Path "<CONFIG_DIR>\mcp.json" -Force
```
