# LLM Provider Generation

The LLM Provider Generation toolset manages LLM provider registration and proxy generation for governed access with `IBM DataPower Interact Gateway`.

**Key highlights**:
- Generation and management of LLM providers and proxies through several tools:
  - [ListLLMProviderTypes](#listllmprovidertypes): list the LLM provider types available for creation
  - [ListLLMProviderTypeModels](#listllmprovidertypemodels): discover models available for a given provider type *(12.1.1.3+ only)*
  - [ListLLMProviders](#listllmproviders): list existing LLM providers that have been created in the gateway *(12.1.1.3+ only)*
  - [ListLLMSecrets](./settings.md#listllmsecrets): list LLM secrets stored in the gateway *(12.1.1.3+ only)*
  - [LLMProviderGenerator](#llmprovidergenerator): create a new LLM Provider entry in the gateway settings (12.1.1.3+) or generate KIND documents (pre-12.1.1.3)
  - [LLMProxyGenerator](#llmproxygenerator): generate publishable KIND proxy documents from an existing LLM Provider *(12.1.1.3+ only)*

---

## ListLLMProviderTypes

This tool lists all LLM provider types that are available to be registered. On 12.1.1.3+, provider types are fetched from the live gateway endpoint. On earlier versions, the local registry is used.

Supported types include: `watsonx`, `openai`, `azure-openai`, `gemini`, and `custom` (OpenAI-compatible).

**Example prompts**
```
List LLM Provider types available for generation
```

```
What LLM Platforms can I connect to?
```

```
Are there LLM Provider types that I can use?
```

---

## ListLLMProviderTypeModels

> **Note**: This tool is only available in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

This tool discovers the models available for a given LLM provider type by connecting to the provider using the supplied credentials. Use it to identify model IDs before creating a provider or generating a proxy.

### Parameters

| Parameter | Required | Description |
| --------- | -------- | ----------- |
| `providerType` | Yes | Provider type (`watsonx`, `openai`, `azure-openai`, `gemini`, `custom`) |
| `apiKeySecret` | Yes | Name of the API key secret stored in the gateway (not the secret value itself) |
| `projectId` | No | Project ID (required for `watsonx` and `openai`) |
| `region` | No | Region (required for `watsonx`, e.g. `us-south`) |
| `orgId` | No | Organization ID (for `openai`) |
| `deploymentId` | No | Deployment ID (for `azure-openai`) |
| `resourceId` | No | Resource ID (for `azure-openai`) |
| `providerUrl` | No | Provider URL (for `custom`) |

**Example prompts**
```
List the available models for watsonx using secret watsonx-secret in region us-south with project 7u8c26f2-7e9b-40a5-9a6f-c31fge76bu06
```

```
What models are available for openai using secret openai-key?
```

```
Show me models for azure-openai with secret azure-secret, resourceId my-resource and deploymentId gpt4-deploy
```

---

## ListLLMProviders

> **Note**: This tool is only available in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

This tool lists the LLM Providers that have already been created in the gateway. Use the names returned here as input to `LLMProxyGenerator`.

**Example prompts**
```
List all created LLM Providers
```

```
What LLM Providers exist?
```

```
Show me the available LLM Providers
```

For more information see the [Registering LLM Providers for governed access with IBM DataPower Interact Gateway](https://ibmdocs-test.dcs.ibm.com/docs/en/v12saas_internal_test?topic=gateway-registering-llm-providers-governed-access).

---

## LLMProviderGenerator

**Behaviour varies by gateway version:**

- **12.1.1.3+**: Creates a new LLM Provider entry directly in the gateway settings (equivalent to configuring a provider in the gateway UI). This is the first step in the two-step provider → proxy workflow. No KIND files are produced at this stage. The `selectedModels` and `selectedOperations` parameters are only available in this mode.
- **Pre-12.1.1.3**: Generates KIND documents for the LLM Provider.

### Parameters — 12.1.1.3+ (Settings registration flow)

> **Note**: The following parameters and behaviour apply only in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

| Parameter | Required | Default | Description |
| --------- | -------- | ------- | ----------- |
| `platform` | Yes | - | Provider type (`watsonx`, `openai`, `azure-openai`, `gemini`, `custom`) |
| `xIbmProject` | Yes | `default-project` | Name or ID of the project (namespace) |
| `apiKeySecretName` | Yes | - | Name of the API key secret stored in the gateway |
| `connectionName` | No | `<platform>-connection` | Name for the new provider entry |
| `version` | No | `1.0.0` | Version of the provider |
| `region` | No | - | Region (required for `watsonx`, e.g. `us-south`) |
| `projectId` | No | - | Project ID (`watsonx` and `openai`) |
| `orgId` | No | - | Organization ID (`openai`) |
| `deploymentId` | No | - | Deployment ID (`azure-openai`) |
| `resourceId` | No | - | Resource ID (`azure-openai`) |
| `providerUrl` | No | - | Provider URL (`custom`) |
| `selectedModels` | No | `[]` (all) | Model IDs to register; leave empty to include all discovered models |
| `selectedOperations` | No | `[]` (all) | Operation names to register (e.g. `textChat`, `textGen`, `embeddings`); leave empty for all |

### Parameters — Pre-12.1.1.3 (KIND document generation)

| Parameter | Required | Default | Description |
| --------- | -------- | ------- | ----------- |
| `platform` | Yes | - | Provider type identifier |
| `xIbmProject` | Yes | - | Project name or ID |
| `apiKeySecretName` | Yes | - | Name of the API key secret |
| `connectionName` | No | `""` | Name of the connection being generated |
| `basePath` | No | `""` | Base path for the LLM provider API |
| `version` | No | `"1.0"` | Version of the LLM provider |
| `tags` | No | `[]` | Tags for categorizing the provider |
| `tlsClientProfile` | No | `"tls-client-profile-default:1.0.0"` | TLS client profile reference (`name:version`). Use [`ListTLSClientProfiles`](./settings.md#listtlsclientprofiles) to find available values. |
| `region` | No | - | Region (WatsonX only) |
| `projectId` | No | - | Project ID (WatsonX and OpenAI) |
| `orgId` | No | - | Organization ID (OpenAI only) |
| `opVersion` | No | - | Operation version (WatsonX and Azure OpenAI) |
| `deploymentId` | No | - | Deployment ID (Azure OpenAI only) |
| `resourceId` | No | - | Resource ID (Azure OpenAI only) |
| `providerUrl` | No | - | Provider URL (custom providers only) |
| `responseCaching` | No | `true` | Enable response caching |
| `cacheTTL` | No | `60` | Cache TTL in seconds |
| `maxTokens` | No | `1000` | Maximum tokens for rate limiting |
| `tokenTimeInterval` | No | `1` | Token rate limit interval in seconds |
| `maxRequests` | No | `1000` | Maximum requests for rate limiting |
| `requestTimeInterval` | No | `1` | Request rate limit interval in seconds |
| `intervalUnit` | No | `"seconds"` | Time unit for rate limit intervals |
| `exceedAction` | No | `"continue"` | Action when rate limits are exceeded |
| `errorHandlingEnabled` | No | `false` | Enable error handling |
| `errorHandlingType` | No | `"plain"` | Error handling type |
| `errorMessage` | No | `"An error occurred while processing your request."` | Custom error message |
| `errorCode` | No | `400` | HTTP error code |
| `telemetryEnabled` | No | `true` | Enable telemetry |
| `telemetryLogLevel` | No | `"default"` | Telemetry log level |

**Example prompts — 12.1.1.3+ Settings flow**
```
Create a watsonx provider called watson-prov in project test with api key secret watsonx-api-key in region us-south with projectId 123-456-789
```

```
Set up an openai provider for project dev with api key secret openai-key, orgId my-org and projectId proj-123 and only include the gpt-4o and gpt-4o-mini models
```

```
Register a custom OpenAI-compatible provider for project dev with providerUrl https://api.mistral.ai/ and api key secret mistral-key
```

**Example prompts — Pre-12.1.1.3 KIND generation**
```
Generate LLM Provider documents for watsonx in the project test with api key secret watsonx-api-key
```

```
Set up a gemini connection called dev-gemini-conn in project project-1 using api key secret gemini-api-key
```

```
Create an OpenAI LLM Provider for project dev with orgId my-org, projectId proj-123 and api key secret openai-api-key
```

```
I need an azure-openai wired up for the azure-project with deploymentId gpt-5-chat, resourceId nano-openai-test and the connection name azure-openai-conn and api key secret azure-secret
```

```
Set up a custom OpenAI-compatible provider for project dev with providerUrl https://api.custom-llm.com/v1, model llama-3-70b and api key secret custom-api-key
```

```
Set up a production-ready watsonx connection wx-prod-conn for project prod in region us-south with projectId 123-356-789, tag production, caching on with 600s TTL, rate limit 10000 tokens and 200 requests per minute, error handling enabled returning 429 with message "Rate limit exceeded on watsonx provider", default telemetry and api key secret watsonx-api-key
```

For more information see the [Registering LLM Providers for governed access with IBM DataPower Interact Gateway](https://ibmdocs-test.dcs.ibm.com/docs/en/v12saas_internal_test?topic=gateway-registering-llm-providers-governed-access).

---

## LLMProxyGenerator

> **Note**: This tool is only available in IBM DataPower Interact Gateway version 12.1.1.3 and greater.

This tool generates publishable KIND proxy documents from a provider that already exists in the gateway settings. Use [LLMProviderGenerator](#llmprovidergenerator) first to create the provider, then use this tool to generate the proxy documents that can be published.

### Parameters

| Parameter | Required | Default | Description |
| --------- | -------- | ------- | ----------- |
| `providerName` | Yes | - | Name of an existing LLM Provider in the gateway (from `ListLLMProviders`) |
| `xIbmProject` | Yes | `default-project` | Name or ID of the project |
| `providerVersion` | No | - | Match a specific version of the provider when multiple versions exist |
| `connectionName` | No | `<platform>-connection` | Name for the generated proxy connection |
| `basePath` | No | `""` | Base path for the proxy API |
| `version` | No | `1.0.0` | Version of the proxy |
| `tags` | No | `[]` | Tags for categorizing the proxy |
| `selectedModels` | No | `[]` (all) | Model IDs or display names to include; leave empty to include all models from the provider |

**Example prompts**
```
Generate LLM Proxy documents using the watsonx provider watson-prov in project test and create a new project called watson-proxy for it
```

```
Create an LLM Proxy called wx-conn for project my-project using provider watson-prov version 1.0.0 and create a new project called my-project-proxy for it
```

```
Set up a proxy for watson-prov in project ns-1 with only the granite model selected and create a new project called ns1-granite-proxy for it
```

**Note**: This tool generates KIND documents. Use the [`project-manager`](skills.md#project-manager) skill (triggered by `and create a new project called <name> for it`) to set up the studio project required for packaging and publishing the generated files.

**Next step**: Package and publish the generated files using the [Project Publish Tool](./publish_assets.md).

For more information see the [Registering LLM Providers for governed access with IBM DataPower Interact Gateway](https://ibmdocs-test.dcs.ibm.com/docs/en/v12saas_internal_test?topic=gateway-registering-llm-providers-governed-access).

