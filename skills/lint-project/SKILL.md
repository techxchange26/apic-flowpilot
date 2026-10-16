---
name: lint-project
description: Validate IBM API Connect / APIC projects using apic lint. Triggers on lint, validate, check for errors, analyze project for IBM API Connect or APIC.
---

# API Connect Lint Project Skill

Linting of IBM API Connect projects using `apic lint`.

**EXECUTE IMMEDIATELY — do not ask clarifying questions, do not load reference files, do not summarise what you are about to do. Parse the project name, build the command, run it.**

**`--localDir` is always `.` (current workspace directory) — never set it to the project name. Never ask the user for a path.**

```bash
# CORRECT — project name is a positional arg, --localDir is the workspace root
apic lint orders-api --localDir .
# WRONG — never use the project name as --localDir
apic lint --localDir orders-api
```

## Prerequisites

Requires Node.js 24. **Skip entirely if `SESSION_CLI_VERIFIED=true`.**

If not yet verified, run `apic schema list` once:

| Result | Action |
|--------|--------|
| Returns asset list | ✅ Set `SESSION_CLI_VERIFIED=true`, proceed immediately |
| `error: unknown command 'schema'` | Run `apic version --debug`; if _APIConnect toolkit client_, ask user to upgrade — **HARD STOP** until confirmed, then re-run |
| `error: unknown command 'version'` | `npm i -g @apistudio/apim-cli@latest`, then re-run |
| `command not found: apic` | `npm i -g @apistudio/apim-cli@latest`, then re-run |

**HARD STOP** if `apic schema list` still fails after remediation.

## CLI Command Reference

```bash
apic lint [projects] [options]
```

| Option | Description |
|--------|-------------|
| `projects` | Project name(s), comma-separated. Omit when using `--all` |
| `-l, --localDir <path>` | Workspace root containing project folders. **Always `.`** |
| `-a, --all` | Lint all projects in localDir |
| `-n, --names <apis>` | Specific API(s): `namespace:apiname:version` |
| `-d, --dependencies` | Include project dependencies (default: false) |
| `-f, --format <type>` | `JSON` or `TABLE` (default: TABLE) |

## Execution Flow

### Step 1: Parse request

Extract: project name(s) or `--all` flag, optional `--names`, dependencies flag, output format.

- `--localDir` is always `.` — even if the user mentions a folder name in passing.
- If `--names` namespace is missing, default to the **project name**; version defaults to `1.0`.
- Never ask the user for a path.

### Step 2: Construct command

| Pattern | Command |
|---------|---------|
| Single project | `apic lint <project> --localDir .` |
| Multiple projects | `apic lint <p1>,<p2> --localDir .` |
| All projects | `apic lint --all --localDir .` |
| Specific API | `apic lint <project> --names <ns:api:ver> --localDir .` |
| With dependencies | `apic lint <project> --localDir . --dependencies true` |
| JSON output | `apic lint <project> --localDir . --format JSON` |

Always append `2>&1` to capture both stdout and stderr.

**Never `cd` into the project directory.** Always stay at workspace root and pass the project name as a positional argument.

### Step 3: Execute and report

**Execution rules:**
- **Execute immediately:** Do NOT load external reference files, do NOT explain what you are about to do, do NOT ask for confirmation. Run `apic lint` as the very next action.
- **No pre-lint reads:** Never read `security-analysis.md`, `owasp-api-top10.md`, `policy-catalog.md`, or any reference file before or during linting. The `apic lint` CLI performs complete validation.
- **Run independent lint checks concurrently:** When linting multiple distinct projects or running lint alongside other independent checks, trigger them in parallel batches.

**Handling Lint Output:**
- **Zero errors, 0 or more warnings:** Proceed immediately to the build step (`apic build <project> --localDir .`). Do NOT over-analyze warnings or read reference docs unless the user explicitly requests warning remediation.
- **Lint errors (Exit code != 0 / Errors > 0):** **HARD STOP**. Display the error table, identify the root cause from the output, and fix the specific failing assets before re-linting.

**On failure / unexpected errors:**
- Parse error message and identify the root cause
- Check the error table below for known causes and fixes
- Offer to retry with corrected command

## Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `Command not found: apic` | CLI not installed | `npm i -g @apistudio/apim-cli@latest` (Node.js v24) |
| `Invalid local directory` | Path doesn't exist | Verify path; use `.` as default |
| `Project not found` | Name misspelled or missing | Run `apic list --localDir .` to see available projects |
| `Missing .api-studio-project file` | Not a valid project directory | Ensure project was created with `apic create` |
| `Validation failed` | Asset structure/schema errors | Review lint output; fix reported errors and re-lint |
| `Permission denied` | No read access | Check folder permissions |
| `API not found in project` | Wrong `namespace:name:version` | Verify with `apic list --localDir .` |
| `Invalid format specified` | Bad `--format` value | Use `--format JSON` or `--format TABLE` |
| `Node.js version mismatch` | Wrong Node.js version | Upgrade to Node.js 24 |
