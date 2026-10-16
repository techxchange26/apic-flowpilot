---
name: build-project
description: Build IBM API Connect / APIC projects using the apic CLI. Use this skill whenever the user mentions building projects, compiling APIs, creating build artifacts, preparing projects for deployment, or wants to build single/multiple API Connect projects. Triggers on any mention of IBM API Connect or API Connect (APIC) in the context of building, compiling, or preparing projects. Also triggers on phrases like "build the project", "build all projects in folder", "compile the API", "create build artifact", "prepare for publish" or "prepare for deployment".
---

# API Connect Build Project Skill

Builds IBM API Connect projects using `apic build`. Handles single, multiple, and all-project builds.

**`--localDir` is always `.` (current workspace directory) unless the user provides an explicit filesystem path. A folder name mentioned in passing (e.g. "in the test-api folder") is not a path — still use `.`. Never ask the user for a path.**

**Output defaults to `./builds/` unless the user specifies otherwise.**

## Prerequisites

Requires Node.js 24. **Skip the CLI check if a calling skill (e.g. `lint-project`) already verified it this session.**

If not yet verified, run `apic schema list` once:

| Result | Action |
|--------|--------|
| Returns asset list | ✅ Proceed |
| `error: unknown command 'schema'` | Run `apic version --debug`; if _APIConnect toolkit client_, ask user to upgrade — **HARD STOP** until confirmed, then re-run |
| `error: unknown command 'version'` | `npm i -g @apistudio/apim-cli@latest`, then re-run |
| `command not found: apic` | `npm i -g @apistudio/apim-cli@latest`, then re-run |

**HARD STOP** if `apic schema list` still fails after remediation.

## CLI Reference

```bash
apic build [projects] [options]
```

| Option | Description |
|--------|-------------|
| `projects` | Project name(s), comma-separated. Omit when using `--all` |
| `-l, --localDir <path>` | Root folder containing projects. **Default: `.`** |
| `-a, --all` | Build all projects in localDir |
| `-n, --names <apis>` | Specific API(s): `namespace:apiname:version` |
| `-o, --output <path>` | Output ZIP path. **Default: `./builds/`** |
| `-d, --debug` | Verbose debug output |

## Execution Flow

### Step 1: Parse Request

| Input | Rule |
|-------|------|
| Project name(s) | Extract from query; use `--all` if user says "all projects" |
| `--localDir` | Always `.` unless user gives an explicit path |
| `--names` namespace | Default to **project name** if missing |
| `--names` version | Default to `1.0` if missing |
| Output path | User-specified, else `./builds/` |
| Debug | Enable if user mentions debugging |

### Step 2: Lint Before Building

**Skip if `lint-project` was already run for the same project(s) in this session.** Otherwise run lint first:

**Named project(s):**
```bash
apic lint <project-name(s)> --localDir . --format TABLE
```

**All-projects build:**
```bash
apic lint --all --localDir . --format TABLE
```

- No errors → proceed
- Warnings only → display, proceed
- Errors → **HARD STOP**, display errors, exit

### Step 3: Build

```bash
# Single project
apic build <project> --localDir . --output ./builds/<project>.zip

# Multiple projects
apic build <p1>,<p2> --localDir . --output ./builds/

# All projects
apic build --all --localDir . --output ./builds/

# Specific API
apic build <project> --names <namespace:api:version> --localDir . --output ./builds/<project>.zip

# Debug
apic build <project> --localDir . --output ./builds/<project>.zip --debug
```

### Step 4: Report Results

**Success:** confirm completion, report output path, suggest next steps (lint → build → publish).

**Failure:** parse error, identify root cause, provide fix, offer retry.

## Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `Command not found: apic` | CLI not installed | `npm i -g @apistudio/apim-cli@latest` (Node.js v24) |
| `Invalid local directory` | Path doesn't exist | Verify path contains valid projects |
| `Project not found` | Name misspelled | Run `apic list --localDir .` to see available projects |
| `Build validation failed` | Project structure issues | Fix validation errors reported by lint |
| `Permission denied` | No write access to output dir | Check permissions or change output path |
| `API not found in project` | Wrong `namespace:name:version` | Verify with `apic lint` |

## Notes

- Build artifacts are ZIP files. Existing output files are overwritten without warning.
- `--names` format: `namespace:apiname:version` — defaults: namespace = project name, version = `1.0`
- For `--all` builds, use `apic lint --all --localDir .` first; one failure stops the entire build
- Add `--debug` for detailed validation steps, file processing info, and error stack traces
