# Skills

AI agent skills for IBM API Connect and IBM DataPower Interact Gateway.

> For installation, MCP server setup, compatible agents, and prerequisites see the [README](../README.md).

---

## What Are Skills?

Skills are reusable capability packages that give AI agents procedural knowledge for specific tasks. When you install a skill, your agent gains structured instructions for performing complex multi-step workflows — so instead of figuring out the right `apic` CLI flags or REST API calls yourself, you describe what you want in plain language and the agent handles it.

```
You  → "Build my orders-api project and publish it to the sandbox catalog"
Agent → reads build-project + publish-project skills
Agent → executes the correct CLI commands and REST API calls automatically
```

Each skill lives in its own folder as a `SKILL.md` file, optionally with bundled reference files and scripts. Skills are loaded into your agent's context on demand — only when the task matches.

---

## Available Skills

### Project Lifecycle

| Skill | Description |
|---|---|
| [project-manager](project-manager/SKILL.md) | Create, list, rename, update, and delete API Connect projects using the `apic` CLI |
| [build-project](build-project/SKILL.md) | Build projects into deployable `.zip` artifacts |
| [lint-project](lint-project/SKILL.md) | Validate projects with static analysis before build or publish |
| [publish-project](publish-project/SKILL.md) | Publish built projects to APIC catalogs or IDIG standalone via MCP tools or curl |

### Asset Authoring

| Skill | Description |
|---|---|
| [asset-manager](asset-manager/SKILL.md) | Create and manage APIs, Products, Plans, Policies, and Routes; OWASP hardening; gateway-type conversion |

### Testing

| Skill | Description |
|---|---|
| [test-generator](test-generator/SKILL.md) | Generate and execute API test suites from OpenAPI specifications |

### MCP Integration

| Skill | Description |
|---|---|
| [rest-to-mcp-generator](rest-to-mcp-generator/SKILL.md) | Convert a REST OpenAPI spec into a complete set of MCP kind files |
| [operation-selector](operation-selector/SKILL.md) | Supporting skill — select OpenAPI operations during MCP generation (invoked automatically by `rest-to-mcp-generator`) |
| [setup-mcp-asset](setup-mcp-asset/SKILL.md) | Register a published and subscribed MCP asset into your agent — reads `subscriptions/*-creds.json` and writes the MCP server config entry automatically |

### Setup & Onboarding

| Skill | Description |
|---|---|
| [setup-agent-kit](setup-agent-kit/SKILL.md) | Install and configure all APIC AI assets — MCP servers and agent skills — in any supported coding assistant |
