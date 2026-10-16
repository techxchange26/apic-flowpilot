# Publishing and Inventory

## PublishProject

**Tool description**: This tool takes a zip file path that contains project assets for IDIG and publishes them to the IDIG platform.

**Tool Details**:
- This tool helps with the task of publishing project assets to the IDIG platform.

**Note**: This operation makes use of the [`build-project`](skills.md#build-project) skill to help in creating a build artifact zip file that can successfully be published. The skill is triggered automatically once a publish request is made and there is no pre-existing zip file for the project.

### Table 1. IDIG Parameters

| Parameter | Required | Description | Default |
| -------- | ------- | -------- | ------- |
| zipFilePath | Yes | The absolute file path to the .zip file to publish. | — |
| publishToPortal | No | Flag to indicate if the project should be published to the IDIG portal. | False |
| projectName | No | The name of the project to publish. | None |

**Sample Prompts**:

```text
Publish the project @my_project_assets.zip to IDIG
```

```text
Publish the project @my_project_assets.zip and publish to IDIG portal
```

For more information, see [Managing AI services using IBM DataPower Interact Gateway](https://www.ibm.com/docs/en/api-connect/cloud/12.1.0_saas?topic=managing-ai-services-using-datapower-interact-gateway).

---

## GetAIInventory

> **Note**: This tool is only available in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

**Tool description**: This tool retrieves the AI inventory, listing all deployed AI assets (such as MCP servers and LLM providers) along with their deployment status, diagnostics, and endpoints.

**Tool Details**:
- No parameters are required — the tool fetches the full inventory from the gateway automatically.
- Returns a table with one row per deployed asset.
- Useful for checking which assets are live, which have failed, and why.

### Response columns

| Column | Description |
| ------ | ----------- |
| Name | Asset name |
| Version | Asset version |
| Type | Asset type (`mcpServer` or `llmProvider`) |
| Status | Deployment status (`published`, `failed`, etc.) |
| Endpoint | Deployed endpoint URL (empty when not yet published) |
| Diagnostics | Diagnostic error messages when deployment failed |

**Sample Prompts**:

```text
Get AI inventory
```

```text
List all deployed AI assets
```

```text
Show AI inventory status
```

```text
What is the status of my deployed MCP servers and LLM providers?
```

```text
Are there any failed deployments in the AI inventory?
```
