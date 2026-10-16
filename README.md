# IBM API Connect — Flow Pilot Lab

> **IBM TechXchange 2026 · Hands-on Lab**

Welcome to the **Flow Pilot** lab repository. This repo contains everything you need to experience AI-assisted API development with IBM API Connect — MCP servers, agent skills, and a sample OpenAPI specification, all ready to use during the session.

---

## What is Flow Pilot?

Flow Pilot is the AI-assisted development experience built into IBM API Connect. It connects your AI coding assistant (IBM Bob, GitHub Copilot, Claude Code, and others) directly to your API Connect instance through the **Model Context Protocol (MCP)**, giving the agent live tools to create, publish, govern, and analyze APIs — entirely through natural language.

Instead of navigating the API Manager UI or writing `apic` CLI commands by hand, you describe what you want:

```
Convert the orders-spec.yaml into a fully configured MCP server and publish it to the sandbox catalog
```

…and Flow Pilot handles the rest.

---

## What's in This Repository

```
apic-flowpilot/
├── mcp-servers/          # Pre-built MCP server packages (.tgz + .mcpb installers)
│   ├── analytics/        # API usage, latency, and status analytics
│   ├── genai-spec/       # AI-powered OpenAPI generation and enhancement
│   ├── governance/       # Linting, rulesets, and governance scanning
│   ├── management/       # Catalogs, products, APIs, subscriptions
│   ├── ai-gateway-management/      # LLM providers, REST-to-MCP conversion (APIC-backed)
│   └── interact-gateway-onprem/    # Standalone DataPower Interact Gateway
│
├── skills/               # Agent skill packages (SKILL.md files + references)
│   ├── setup-agent-kit/        # One-command setup for all MCP servers and skills
│   ├── asset-manager/          # Create APIs, products, plans, policies, routes
│   ├── build-project/          # Build projects into deployable artifacts
│   ├── lint-project/           # Validate projects before build or publish
│   ├── publish-project/        # Publish to APIC catalogs or IDIG standalone
│   ├── test-generator/         # Generate and run API test suites from specs
│   ├── rest-to-mcp-generator/  # Convert an OpenAPI spec to MCP kind files
│   └── llm-provider-generator/ # Generate LLM provider KIND documents
│
└── orders-spec.yaml      # Sample Orders API spec (customers + orders endpoints)
```

---

## License

[Apache 2.0](LICENSE)
