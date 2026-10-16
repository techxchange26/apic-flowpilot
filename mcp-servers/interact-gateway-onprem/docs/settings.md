# Gateway Settings

Tools for inspecting gateway configuration such as TLS client profiles and LLM secrets.

- [ListTLSClientProfiles](#listtlsclientprofiles)
- [ListLLMSecrets](#listllmsecrets)

---

## ListTLSClientProfiles

**Tool description**: This tool lists the TLS client profiles currently present on the gateway. Use the `profile` value (formatted as `name:version`) as input to the `tlsClientProfile` parameter when generating LLM Provider KIND documents.

**Parameters**

| Parameter | Required | Description | Default |
| --------- | -------- | ----------- | ------- |
| `catalog` | No (non-standalone only) | Name or ID of the catalog to list profiles from. Not used in standalone mode. | `sandbox` |

**Sample Prompts**:

```text
List TLS client profiles
```

```text
Get TLS client profiles
```

```text
What TLS client profiles are available?
```

---

## ListLLMSecrets

> **Note**: This tool is only available in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

**Tool description**: This tool lists the LLM secrets currently stored in the gateway. Use the `name` value as the `apiKeySecretName` parameter when creating a new LLM Provider with `LLMProviderGenerator`.

No parameters are required — the tool fetches all LLM secrets automatically.

### Response columns

| Column | Description |
| ------ | ----------- |
| Name | Name of the LLM secret (use this as `apiKeySecretName`) |
| Provider | The provider associated with the secret |
| Created | How long ago the secret was created |

**Sample Prompts**:

```text
List LLM secrets
```

```text
Get LLM secrets
```

```text
What LLM secrets are available on the stack?
```
