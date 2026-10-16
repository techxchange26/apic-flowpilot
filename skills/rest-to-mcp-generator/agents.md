# Agent Configuration Reference

MCP config file paths for each supported AI coding assistant.

`~` expands to the user's home directory. On Windows, replace `~/` with `%USERPROFILE%\` (cmd) or `$env:USERPROFILE\` (PowerShell).


---

## Per-Agent MCP Configuration

| # | Agent | Global Config Location | Project / Workspace Config | Top-Level JSON Key | Crucial Nuances |
|---|---|---|---|---|---|
| 1 | **Bob** (IBM Bob IDE) | `~/.bob/settings/mcp.json` | `.bob/mcp.json` | `"mcpServers"` | Standard format. Prefer workspace-level so each project has its own servers. Create `.bob/settings/` if it does not exist. |
| 2 | **Claude Code** (CLI) | `~/.claude.json` | `.mcp.json` (repository root) | `"mcpServers"` | Requires `"type": "stdio"` or `"type": "http"` on every entry — throws errors if missing. **Security gate**: project `.mcp.json` files are ignored by default; add `"enableAllProjectMcpServers": true` to `~/.claude.json` to trust them. MCP registrations live in `~/.claude.json`; `~/.claude/settings.json` stores permissions/hooks only, not MCP. Alternatively use: `claude mcp add <name> -- <cmd>` |
| 3 | **Claude Desktop** (App) | macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`<br>Windows: `%APPDATA%\Claude\claude_desktop_config.json` | Not supported (global only) | `"mcpServers"` | Open via app Settings ➔ Developer ➔ Edit Config. Requires a **full application relaunch** to recognise new or modified local stdio servers. |
| 4 | **VS Code Native** (Core) | User-profile `mcp.json` — open via command palette: `MCP: Open User Configuration` | `.vscode/mcp.json` | `"servers"` (**not** `"mcpServers"`) | **Major outlier**: uses `"servers"` not `"mcpServers"` — pasting standard configs silently fails. Each entry also needs a `"type"` field (`"stdio"`, `"http"`, etc.). Best managed via command palette. |
| 5 | **Cursor** | macOS: `~/.cursor/mcp.json`<br>Windows: `%APPDATA%\Cursor\mcp.json` | `.cursor/mcp.json` | `"mcpServers"` | Standard format. Also configurable via Settings ➔ Features ➔ MCP. Supports **hot-reloading** — no editor restart needed. |
| 6 | **Windsurf** | macOS: `~/.codeium/windsurf/mcp_config.json`<br>Windows: `%APPDATA%\Codeium\Windsurf\mcp_config.json` | Not supported (global only) | `"mcpServers"` | **No variable expansion**: does not recognise `${workspaceFolder}` or env injections. All commands, paths, and keys must be fully hardcoded. Docs: [docs.windsurf.com/windsurf/cascade/mcp](https://docs.windsurf.com/windsurf/cascade/mcp) |
| 7 | **Zed Editor** | `~/.config/zed/settings.json` | `.zed/settings.json` | `"context_servers"` | **Major outlier**: uses `"context_servers"` — avoids the "MCP" naming convention entirely. Nested directly in main settings JSON alongside other Zed settings. Requires an **editor reload** on changes. Docs: [zed.dev/docs/ai/mcp.html](https://zed.dev/docs/ai/mcp.html) |
| 8 | **Cline** (VS Code Extension) | macOS: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`<br>Windows: `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json` | `.vscode/settings.json` (under `"cline.mcpServers"`) | Global: `"mcpServers"`<br>Project: `"cline.mcpServers"` | Extension ID is `saoudrizwan.claude-dev` (still valid; publisher now presents as `cline.bot`). Modifying the global file directly can be overridden by the extension UI — prefer the Cline panel. Workspace scoping requires the `"cline.mcpServers"` namespace inside VS Code preferences. |
| 9 | **Roo Code** (Roo Cline) | macOS: `~/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json`<br>Windows: `%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline\settings\cline_mcp_settings.json` | `.vscode/settings.json` (under `"roo-cline.mcpServers"`) | Global: `"mcpServers"`<br>Project: `"roo-cline.mcpServers"` | Extension ID `rooveterinaryinc.roo-cline`. Identical architecture to Cline but isolated under its own extension storage. Safest to configure via the Roo Code panel in the sidebar. Publisher now presents as `roocode.com`. |
| 10 | **Continue** | `~/.continue/config.yaml` (v1) or `~/.continue/config.json` (legacy) | `.continue/config.yaml` | `"mcpServers"` | Standard syntax, nested inside the broader Continue config alongside models and context providers. YAML format is default in v1; JSON still accepted for backward compatibility. Docs: [docs.continue.dev](https://docs.continue.dev) |
| 11 | **GitHub Copilot** (VS Code) | User-profile `mcp.json` — open via `MCP: Open User Configuration` | `.vscode/mcp.json` (workspace root) | `"servers"` | Shares the exact same VS Code MCP infrastructure as VS Code Native — same config files, same `"servers"` key, same `"type"` field requirement. Remote MCP endpoint: `https://api.githubcopilot.com/mcp`. |
| 12 | **Warp** (Terminal) | `~/.warp/.mcp.json` | `.warp/.mcp.json` (project root) | `"mcpServers"` | Also auto-reads `~/.claude.json` and `~/.codex/config.toml` from other agents when "Auto-spawn from third-party agents" is enabled. Always set `"working_directory"` explicitly when args use relative paths. Project-scoped servers require per-session approval. Built-in `/agent-add-mcp` command can write configs for you. Docs: [docs.warp.dev/features/warp-ai/mcp](https://docs.warp.dev/features/warp-ai/mcp) |
| 13 | **Gemini CLI** | `~/.gemini/settings.json` | `.gemini/settings.json` | `"mcpServers"` | **Do not use underscores in server alias names** — use hyphens instead (e.g., `my-server` not `my_server`); the tool FQN parser (`mcp_alias_tool`) silently breaks with underscores. Supports `$VAR`, `${VAR}`, and `${VAR:-default}` env var expansion. `"trust": true` bypasses all confirmation prompts. Configuration layers: system → user → project → env vars → CLI args. Docs: [gemini-cli docs](https://geminicli.com/docs/reference/configuration) |
| 14 | **Amazon Q Developer CLI** | `~/.aws/amazonq/mcp.json` (user-scoped) | `.amazonq/mcp.json` (workspace root) | `"mcpServers"` | MCP tools load **progressively in background** — use `/tools` to check status. Initialization timeout configurable: `q settings mcp.initTimeout <ms>`. Supports auto-approve / require-approval / dangerous tiers. No restart needed — servers load at next session start. Docs: [docs.aws.amazon.com/amazonq](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-mcp.html) |
| 15 | **Kiro IDE** (AWS) | `~/.kiro/settings/mcp.json` | `.kiro/settings/mcp.json` (workspace root) | `"mcpServers"` | MCP must be **enabled first**: Settings (`Cmd+,`) → search "MCP" → toggle on. Workspace config **overrides** user config (merged, workspace wins). `"autoApprove": ["*"]` skips all confirmation prompts. `${ENV_VAR}` expansion supported. OAuth (PKCE only, no `client_secret`). Commands: `Kiro: Open workspace MCP config (JSON)` / `Kiro: Open user MCP config (JSON)`. Docs: [kiro.dev/docs/mcp](https://kiro.dev/docs/mcp/) |
| 16 | **Goose** (AAIF / Block) | `~/.config/goose/config.yaml` | Not supported — uses MCP Roots for workspace context | `extensions:` (**YAML**, not JSON) | **Major outlier**: config is **YAML format**, not JSON. Key is `extensions:` not `mcpServers`. Add via `goose configure` → Add Extension, or `goose mcp <name>`. Scans extensions for known malware before activation. MCP Roots support: workspace-aware servers see the current working directory automatically. Docs: [block.github.io/goose](https://block.github.io/goose/docs/) |
| 17 | **OpenAI Codex CLI** | `~/.codex/config.toml` | `.codex/config.toml` (trusted projects only) | `[mcp_servers.<name>]` (**TOML**, not JSON) | **Major outlier**: config is **TOML format**, not JSON. Section header syntax: `[mcp_servers.my-server]`. Add via `codex mcp add <name> -- <cmd>`. Project `.codex/config.toml` only loads from **trusted** repos — untrusted is silently ignored. CLI and IDE extension share the same `~/.codex/config.toml`. `"required": true` causes session startup failure if server can't init. Warp also reads this file. Docs: [platform.openai.com/docs/codex](https://platform.openai.com/docs/codex) |
| 18 | **JetBrains AI** (IntelliJ / WebStorm / PyCharm) | Configured inside the IDE, not via a config file | Not applicable | Not applicable — JetBrains **exposes** an MCP server; it does not consume them | **Reversed role**: JetBrains is an MCP **server**, not a client. External agents (Claude Desktop, Cursor, Codex, etc.) connect *to* JetBrains to use IDE tools. Configure via Settings → Tools → MCP Server → Auto-Configure (click per external client). Available since IntelliJ IDEA 2025.2. Requires external client restart after configuration. Docs: [jetbrains.com/help/idea/mcp-server.html](https://www.jetbrains.com/help/idea/mcp-server.html) |
| 19 | **Antigravity** | `~/.antigravity/mcp.json` | Not documented | `"mcpServers"` | Create parent directory if it does not exist: `mkdir -p ~/.antigravity`. No public documentation available — treat as unverified. |
| 20 | **Other** | *User-provided* | *User-provided* | *User-provided* | Ask the user for the config file path. |

---

## Config File Schemas

### Standard schema — JSON (`mcpServers`)

Used by: Bob, Claude Code, Claude Desktop, Cursor, Windsurf, Continue, Cline, Roo Code, Warp, Gemini CLI, Amazon Q, Kiro, Antigravity

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "npx",
      "args": ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### Claude Code — extra required `"type"` field

```json
{
  "mcpServers": {
    "<server-name>": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### VS Code Native / GitHub Copilot — `"servers"` key + `"type"` field

```json
{
  "servers": {
    "<server-name>": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### Zed Editor — `"context_servers"` key

```json
{
  "context_servers": {
    "<server-name>": {
      "command": {
        "path": "npx",
        "args": ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"],
        "env": { "ENV_VAR": "value" }
      }
    }
  }
}
```

### Goose — YAML format (`extensions:`)

```yaml
extensions:
  <server-name>:
    type: stdio          # or "remote" for HTTP
    cmd: npx
    args: ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"]
    env:
      ENV_VAR: value
    timeout: 300
    enabled: true
```

### OpenAI Codex CLI — TOML format (`[mcp_servers.<name>]`)

```toml
[mcp_servers.<server-name>]
command = "npx"
args = ["-y", "-p", "/absolute/path/to/server.tgz", "<server-name>"]
env = { ENV_VAR = "value" }
startup_timeout_sec = 30
enabled = true
```

---

## Initialising an empty config file

When the JSON file does not exist yet:

```bash
# macOS/Linux
mkdir -p "$(dirname <MCP_CONFIG_FILE>)"
echo '{"mcpServers":{}}' > <MCP_CONFIG_FILE>

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path (Split-Path "<MCP_CONFIG_FILE>")
'{"mcpServers":{}}' | Out-File -FilePath "<MCP_CONFIG_FILE>" -Encoding utf8
```

Use `{"servers":{}}` for VS Code Native and GitHub Copilot, or `{"context_servers":{}}` for Zed.
Goose uses `goose configure` (not a manual file). Codex CLI uses `codex mcp add` (not a manual file).

---

## Verification notes

| Agent | Note |
|---|---|
| **Bob** | Global path corrected to `~/.bob/settings/mcp.json` (was `~/.bob/mcp.json`). No public documentation — sourced from IBM Bob team. |
| **Claude Code** | MCP registrations live in `~/.claude.json`, not `~/.claude/settings.json` (that file stores permissions/hooks). Confirmed via [Anthropic docs](https://docs.anthropic.com/en/docs/claude-code/settings). |
| **VS Code** | `"servers"` key confirmed (not `"mcpServers"`). Global path is profile-relative, best opened via command palette. Confirmed via [VS Code MCP docs](https://code.visualstudio.com/docs/copilot/chat/mcp-servers). |
| **Windsurf** | Path confirmed. Note: `docs.codeium.com/windsurf/mcp` is 404 — correct URL is `docs.windsurf.com/windsurf/cascade/mcp`. |
| **Zed** | `"context_servers"` key confirmed. Docs moved to `zed.dev/docs/ai/mcp.html`. |
| **Cline** | Extension ID `saoudrizwan.claude-dev` still valid; publisher brand is now `cline.bot`. |
| **Roo Code** | Extension ID `rooveterinaryinc.roo-cline` confirmed; publisher brand is now `roocode.com`. |
| **GitHub Copilot** | Shares VS Code MCP infrastructure — same files, same `"servers"` key. GitHub Docs URL for MCP is 404; correct source is VS Code docs. |
| **Warp** | MCP support confirmed via [Warp docs](https://docs.warp.dev/features/warp-ai/mcp). Cross-reads Claude Code and Codex CLI configs when toggle enabled. |
| **Gemini CLI** | Config confirmed via Gemini CLI docs. Critical gotcha: no underscores in server alias names. |
| **Amazon Q** | MCP support confirmed via [AWS docs](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-mcp.html). |
| **Kiro IDE** | MCP support confirmed via [Kiro docs](https://kiro.dev/docs/mcp/). Requires explicit enable toggle. |
| **Goose** | YAML format confirmed via Goose docs. Project moved from Block to AAIF. |
| **Codex CLI** | TOML format confirmed via OpenAI docs. Warp auto-reads `~/.codex/config.toml`. |
| **JetBrains** | Acts as MCP **server** (not client) — confirmed via [JetBrains docs](https://www.jetbrains.com/help/idea/mcp-server.html). Available since IDEA 2025.2. |
| **Antigravity** | No public documentation found — path based on community reports; treat as unverified. |

---

## Registration Procedure

Follow these steps when the user wants to register the generated MCP server in their AI coding assistant.

### R1 — Collect the Published Endpoint

First, check whether `PublishProjectToInteractGateway` (or any publish step) already returned a gateway URL earlier in this conversation. The response typically includes a gateway URL such as `https://api-n-kr20.example.ibmappdomain.cloud/<org>/<catalog>/<server-name>/1.0.0`.

**If a URL was returned by the publish tool**, use it automatically and confirm with the user:

> "I'll use `<extracted-url>` as the MCP endpoint — is that correct?"

Wait for confirmation before proceeding.

**If no URL was returned**, ask the user:

> "Please share the published gateway endpoint for your MCP server (e.g. `https://my-mcp-server.nanogw.example.com/1.0.0`)."

In either case, once the base URL is confirmed, validate that it starts with `http://` or `https://`. Strip any trailing `/`, then append `/mcp`:

```
PUBLISHED_MCP_ENDPOINT = <confirmed_url>/mcp
```

### R2 — Derive the Server Key

Use the MCPServer's `name` field (from the MCPServer YAML) as the config key: lowercase, spaces → hyphens, kebab-case as-is.

> **Gemini CLI**: never use underscores — replace with hyphens.

### R3 — Identify the Target Agent

Ask:

> "Which AI coding assistant are you using?"

Consult the **Per-Agent MCP Configuration** table above to determine:

| Variable | Meaning |
|---|---|
| `CONFIG_FILE` | Global (or workspace) config file path |
| `TOP_LEVEL_KEY` | Root key: `"mcpServers"`, `"servers"`, `"context_servers"`, `extensions:`, or TOML `[mcp_servers]` |
| `SCHEMA_VARIANT` | One of: `standard-json`, `claude-code-json`, `vscode-json`, `zed-json`, `goose-yaml`, `codex-toml` |

If the user selects **JetBrains AI**: explain it is an MCP *server*, not a client — external agents connect *to* it. Stop here.

If the user selects **Other**: ask for the config file path and top-level key name.

### R4 — Locate or Create the Config File

Check whether the file exists:

```bash
[ -f <CONFIG_FILE> ] && echo "EXISTS" || echo "NOT_FOUND"
```

If it does not exist, create it:

| Schema | Empty initialiser | How to create |
|---|---|---|
| `standard-json` / `claude-code-json` | `{"mcpServers":{}}` | `mkdir -p "$(dirname <CONFIG_FILE>)" && echo '{"mcpServers":{}}' > <CONFIG_FILE>` |
| `vscode-json` | `{"servers":{}}` | same pattern |
| `zed-json` | `{"context_servers":{}}` | same pattern |
| `goose-yaml` | — | use `goose configure` — do not write manually |
| `codex-toml` | — | use `codex mcp add` — do not write manually |

### R5 — Add the Server Entry

Read the current config. If the key already exists, ask the user whether to overwrite.

**`standard-json`** — Bob, Claude Desktop, Cursor, Windsurf, Continue, Cline, Roo Code, Warp, Gemini CLI, Amazon Q, Kiro, Antigravity:

```json
"<serverKey>": {
  "command": "npx",
  "args": ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"],
  "env": { "NODE_TLS_REJECT_UNAUTHORIZED": "0" },
  "disabled": false
}
```

**`claude-code-json`** — Claude Code (requires `"type"` field):

```json
"<serverKey>": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"],
  "env": { "NODE_TLS_REJECT_UNAUTHORIZED": "0" }
}
```

**`vscode-json`** — VS Code Native / GitHub Copilot (`"servers"` key + `"type"` field):

```json
"<serverKey>": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"],
  "env": { "NODE_TLS_REJECT_UNAUTHORIZED": "0" }
}
```

**`zed-json`** — Zed Editor (`"context_servers"` key, nested `command` object):

```json
"<serverKey>": {
  "command": {
    "path": "npx",
    "args": ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"],
    "env": { "NODE_TLS_REJECT_UNAUTHORIZED": "0" }
  }
}
```

**`goose-yaml`** — Goose (`extensions:` key, YAML):

```yaml
extensions:
  <serverKey>:
    type: stdio
    cmd: npx
    args: ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"]
    env:
      NODE_TLS_REJECT_UNAUTHORIZED: "0"
    timeout: 300
    enabled: true
```

Add via `goose configure` → Add Extension, or merge into `~/.config/goose/config.yaml`.

**`codex-toml`** — OpenAI Codex CLI (TOML):

```toml
[mcp_servers.<serverKey>]
command = "npx"
args = ["-y", "mcp-remote", "<PUBLISHED_MCP_ENDPOINT>"]
env = { NODE_TLS_REJECT_UNAUTHORIZED = "0" }
enabled = true
```

Add via `codex mcp add <serverKey> -- npx -y mcp-remote <PUBLISHED_MCP_ENDPOINT>`.

After writing a JSON file, validate:

```bash
cat <CONFIG_FILE> | python -m json.tool > /dev/null && echo "Valid JSON"
```

### R6 — Confirm and Show Next Steps

```
✓ MCP server registered in <CONFIG_FILE>

  Agent    : <chosen agent>
  Key      : <serverKey>
  Endpoint : <PUBLISHED_MCP_ENDPOINT>

Next steps:
  <agent-specific reload instruction — see table below>
```

| Agent | Reload instruction |
|---|---|
| Bob | Restart Bob or open a new session. |
| Claude Code | Open a new shell session and run `claude`. |
| Claude Desktop | Fully quit and relaunch the app. |
| VS Code / GitHub Copilot | Run `Developer: Reload Window` or restart VS Code. |
| Cursor | No restart needed — config hot-reloads. |
| Windsurf | Restart Windsurf. |
| Zed | Reload the editor after saving settings. |
| Cline / Roo Code | Prefer the extension panel; or restart VS Code. |
| Warp | Changes take effect at the next session start. |
| Gemini CLI | Open a new shell and run `gemini`. |
| Amazon Q | No restart needed — loads at next session start. |
| Kiro | Ensure MCP is enabled in Settings, then reload the window. |
| Goose | Run `goose configure` or restart Goose. |
| OpenAI Codex | Restart Codex CLI or open a new session. |
| Antigravity | Restart Antigravity. |
