# MCP Servers

MCP (Model Context Protocol) servers expose IBM API Connect and IDIG platform capabilities as structured tools that AI agents can call directly — no manual API wrangling needed. Each server wraps a domain (management, analytics, governance, IDIG) and registers its tools with your MCP client so they appear alongside your agent's built-in capabilities.

> For installation overview and compatible agents see the [README](../README.md).

---

## Supported MCP Clients

These servers can be integrated with any MCP-compatible client. Tested with:

[![IBM BOB](svg/ibm-bob.badge.svg)](https://www.ibm.com/products/bob) [![Visual Studio Code](https://custom-icon-badges.demolab.com/badge/Visual%20Studio%20Code-0078d7.svg?logo=vsc&logoColor=white)](https://code.visualstudio.com/) [![Claude Desktop](https://img.shields.io/badge/Claude_Desktop-D97757?logo=claude&logoColor=fff)](https://claude.ai/download)

---

## Available Servers

| Server | Description | Folder |
|---|---|---|
| `apic-analytics-mcp-server` | API usage, latency, status, and user analytics | [analytics](analytics/) |
| `apic-governance-mcp-server` | API linting, ruleset management, and governance scanning | [governance](governance/) |
| `apic-management-mcp-server` | Management operations — catalogs, products, APIs, subscriptions, consumer orgs | [management](management/) |
| `apic-genai-spec-mcp-server` | AI-powered management tools for OpenAPI generation and enhancement | [genai-spec](genai-spec/) |
| `ai-gateway-management-mcp-server` | IDIG tools for LLM provider management, REST-to-MCP conversion, and publishing (APIC-backed) | [ai-gateway-management](ai-gateway-management/) |
| `interact-gateway-onprem-mcp-server` | IDIG tools for standalone on-premises deployments | [interact-gateway-onprem](interact-gateway-onprem/) |

---

## ✅ Prerequisites

- Existing API Connect v10 or v12 instance (SaaS or on-prem), with:
  - Your _`provider organization`_ name
  - An _`API key`_ for your instance
  - _`Client ID`_ and _`Client Secret`_ configured on your instance
  - _`APIC Platform Endpoint`_ and _`APIC Management Endpoint`_ URLs
- _`npm package`_ `.tgz` file **or** the _`.mcpb`_ installer (found in each service folder above)
- Node.js ≥ 20 and npm

---

## 📝 Setup

### Automated Setup — any agent (Recommended)

Use the **`setup-agent-kit`** skill. It works with any supported coding assistant — Bob, Claude Code, Cursor, Windsurf, GitHub Copilot, Antigravity, and others. It handles server discovery, credential collection, config file generation, and skills installation in one guided flow.

**Step 1:** Install the skill:

```bash
/setup-agent-kit
```

**Step 2:** Run it in your agent's chat:

```
Set up APIC AI assets
```

The skill will ask which agent you're using, which IBM product (APIC or IDIG standalone), let you select which MCP servers to install, collect credentials one at a time, write the correct MCP config file for your agent, and verify the installation.

Restart your agent after the skill completes to load the newly configured MCP servers.

> Full skill reference: [`skills/setup-agent-kit/SKILL.md`](../skills/setup-agent-kit/SKILL.md)

---

### Claude Desktop — Extension Install (`.mcpb`)

Claude Desktop supports installation via `.mcpb` extension files — no config editing needed.

1. Locate the `.mcpb` file in the relevant service folder, e.g. `analytics/apic-analytics-mcp-server-x.x.x.mcpb`
2. Double-click the `.mcpb` file — Claude Desktop opens and starts the setup wizard
3. Enter the credential details from the [Prerequisites](#-prerequisites) section above
4. Click **Save** / **Install**, then **enable** the extension (Claude sets it disabled by default)

Once installed, the API Connect tools will be available in your Claude Desktop conversations.

---

### Manual Setup

If you prefer to configure without a skill:

1. Pick the `mcp.bob.json` or `mcp.vscode.json` template from the relevant service folder
2. Fill in your APIC credentials and the absolute path to the `.tgz` file
3. Merge the JSON block into your agent's MCP config file:
   - **Bob**: `.bob/settings/mcp.json`
   - **VS Code / GitHub Copilot**: `.vscode/mcp.json`
   - **Claude Code**: `.claude/mcp.json`
   - **Cursor / Windsurf**: `~/.cursor/mcp.json` / `~/.windsurf/mcp.json`
4. Restart your agent to load the new servers

---

## 📄 Debug Logs

MCP servers write `INFO` level logs to a daily rotating file in `~/apic-mcp/logs/` by default:

| Platform | Log location |
|---|---|
| macOS / Linux | `~/apic-mcp/logs/apic-mcp-YYYY-MM-DD.log` |
| Windows | `%USERPROFILE%\apic-mcp\logs\apic-mcp-YYYY-MM-DD.log` |

The log directory is created automatically. Up to 14 days of logs are retained.

To enable `DEBUG` level logs, add `LOG_LEVEL` to the server's `env` block in your MCP config:

```json
"apic-analytics-mcp-server": {
  "command": "npx",
  "args": ["-y", "-p", "/path/to/apic-analytics-mcp-server-0.0.1.tgz", "apic-analytics-mcp-server"],
  "env": {
    "LOG_LEVEL": "debug"
  }
}
```

---

## 🛠️ Available Tools Reference

| Service | Documentation |
|---|---|
| Analytics | [Analytics tools doc](https://www.ibm.com/docs/en/api-connect/software/12.1.0?topic=tools-analytics) |
| Management | [Management tools doc](https://www.ibm.com/docs/en/api-connect/software/12.1.0?topic=tools-api-connect-task) |
| IDIG | [IDIG README](interact-gateway-onprem/README.md) |
