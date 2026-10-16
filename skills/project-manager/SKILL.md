---
name: project-manager
description: Manage IBM API Connect / APIC project lifecycle — create, list, rename, update, delete projects via apic CLI. Triggers on project management operations for IBM API Connect or APIC.
---

# API Connect Project Manager

Manages IBM API Connect project lifecycle using the `apic` CLI.

## Prerequisites

Requires Node.js 24.

**Skip this entire section if `SESSION_CLI_VERIFIED=true` (set by any skill that already ran `apic schema list` this session).**

Run `apic schema list` once only if not yet verified. On success set `SESSION_CLI_VERIFIED=true` and proceed immediately. On `error: unknown command 'schema'` run `apic version --debug` — if _APIConnect toolkit client_ ask user to upgrade (**HARD STOP**). On `error: unknown command 'version'` or `command not found: apic` run `npm i -g @apistudio/apim-cli@latest` then retry. **HARD STOP** if still failing.

**Set `SESSION_CLI_VERIFIED=true` after first successful check so every subsequent skill invocation in this session skips the check entirely.**

## Execution Rules

**CRITICAL PERFORMANCE RULES — apply before everything else:**
1. **No pre-flight listing:** When a project name is provided, go directly to `apic create` — never run `apic list` first.
2. **Single command execution:** Run `apic create` with all flags in one command — do not split into multiple CLI calls.
3. **No confirmation prompts for creation:** Execute immediately when project name and optional params are known — do not ask "Shall I proceed?" before `apic create`.
4. **Return immediately:** As soon as `apic create` succeeds, return the project path to the calling skill. Do not summarise, list assets, or offer next steps unless the user directly requested them.

## Core Concepts

- `localDir` = workspace directory — always use `.` as the path
- **Fast-path project creation:** When invoked with a project name (or creating a new project), directly run `apic create <name> --localDir . ...` without executing `apic list` first.
- Project metadata: auto-generated `id`, optional `description` and `tags`, auto-managed `lastUpdated`
- Tags are comma-separated with no spaces: `"tag1,tag2"` not `"tag1, tag2"`
- ⚠️ **Use `--desc`, NOT `--description`** — `--description` is not a valid flag and will cause an error

## Commands

### List

```bash
apic list --localDir .                        # all projects
apic list --localDir . --json                 # JSON output
apic list --localDir . --tags "payment,api"   # filter by tags
```

### Create

```bash
apic create <name> --localDir . \
  --desc "My API description" \
  --tags "tag1,tag2"
```

- Name must be unique (CLI validates)
- ⚠️ **Never create a project folder manually** — always use `apic create`. The CLI registers the project in metadata and sets up the correct structure; a hand-created folder will not be recognised as a project.

### Update metadata / Rename

```bash
# Update description and/or tags
apic update <name> --localDir . \
  --desc "New description" \
  --tags "tag1,tag2"

# Rename (preserves project ID)
apic update <old-name> --localDir . --name <new-name>
```

### Delete

```bash
apic delete <name> --localDir .            # removes metadata + folder
apic delete <name> --localDir . --keepDir  # metadata only
```

Always confirm with the user before deleting.

## Return Contract

On completion, this skill returns the **absolute path** to the project directory:

```
<absolute-workspace-path>/<project-name>
```

Calling skills (e.g. `asset-manager`, `rest-to-mcp-generator`, `llm-provider-generator`) must capture this as `projectDir` and use it as the base for all subsequent file paths. Do not attempt to resolve it independently.

### Duplicate

No native duplicate command. Always create via CLI first, then copy files in:

```bash
# 1. Register the new project via CLI (never create the folder manually)
apic create <copy> --localDir . --desc "<same desc>" --tags "<same tags>"

# 2. Copy the contents of the original into the newly created project folder
cp -r ./<original>/. ./<copy>/
```

- ⚠️ **Create the project with `apic create` first** — do not copy folders first and register later. The CLI must always be the source of the project folder.

## Error Handling

The CLI reports errors clearly. Common cases:

| Error | Resolution |
|---|---|
| Project already exists | Choose a different name |
| Project not found | Run `apic list` to see available projects |
| Invalid `localDir` | Verify the path exists |
| Permission error | Check file/folder permissions |
| Tags format invalid | No spaces after commas: `"a,b"` not `"a, b"` |

If a command fails or behaves unexpectedly, consult the built-in help before anything else:

```bash
apic <command> -h   # help for a specific command (e.g. apic create -h)
apic -h             # general help and list of all commands
```
