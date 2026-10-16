# scripts

Helper scripts for packaging and distributing this repository.

---

## createPackage.sh

Builds a distributable `.zip` archive for one of three release modes.

### Usage

```bash
# With a mode argument (non-interactive)
./scripts/createPackage.sh idig
./scripts/createPackage.sh apic
./scripts/createPackage.sh all

# Without an argument (interactive prompt — idig and apic only)
./scripts/createPackage.sh
```

### Modes

| Mode | Output filename | Included mcp-servers | Excluded skills |
|------|----------------|----------------------|-----------------|
| `idig` | `Interact_Gateway_Flow_Pilot.zip` | `ai-gateway-management`, `interact-gateway-onprem` | `llm-provider-generator`, `rest-to-mcp-generator` |
| `apic` | `IBM_API_Connect_Flow_Pilot.zip` | All except `ai-gateway-management` and `interact-gateway-onprem` | `llm-provider-generator`, `rest-to-mcp-generator` |
| `all` | `IBM_API_Connect_Flow_Pilot.zip` | All MCP servers | `llm-provider-generator`, `rest-to-mcp-generator` |

> **Note:** `all` is only available as a CLI argument; the interactive prompt does not offer it.

### What is always included (all modes)

- `Licenses/` — full directory
- `mcp-servers/README.md`
- `skills/README.md`
- `README.md`
- `skills.sh.json`

### Output location

Zips are written to the `packages/` folder at the repo root. This folder is git-ignored. Any existing zip with the same name is overwritten on each run.

### Prerequisites

- `bash` 4+
- `zip` (standard on macOS and most Linux distros)

### Making the script executable

If needed, run once:

```bash
chmod +x scripts/createPackage.sh
```
