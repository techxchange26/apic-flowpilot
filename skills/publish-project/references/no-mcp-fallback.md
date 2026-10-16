# No-MCP Fallback — Full curl Workflow

Use this workflow when `PublishProjectToInteractGateway` (via `ai-gateway-management-mcp-server`) is unavailable, or when the user is publishing to a different APIM URL that is not configured in the MCP server.

> **IDs only in URL paths.** After each list call, extract the `id` field from the response — use that ID in all subsequent URLs, not the name or slug.

> **Credential security.** Never ask for raw password or API key values — only the name of the environment variable that holds them.

---

## Step F1: Gather Base URL and Credentials

Ask the user for the APIM base URL if not already known (e.g. from the MCP config):

| Field | Default |
|-------|---------|
| APIM Base URL | — (required, e.g. `https://api-manager.example.com`) |

Then ask which authentication method to use:

**Option A — Username / Password**

| Field | Default |
|-------|---------|
| Username | — (required) |
| Password env var name | `APIM_PASSWORD` |
| Realm | `provider/default-idp-2` |

If the env var is not set yet:
```bash
export APIM_PASSWORD="your-password"   # add to ~/.zshrc or ~/.bashrc, then source it
```

**Option B — API Key**

| Field | Default |
|-------|---------|
| API key env var name | `APIM_API_KEY` |

If the env var is not set yet:
```bash
export APIM_API_KEY="your-api-key"   # add to ~/.zshrc or ~/.bashrc, then source it
```

---

## Step F2: Authenticate

**Option A — Username / Password:**

```bash
PASSWORD_VAR="${PASSWORD_ENV_VAR:-APIM_PASSWORD}"
PASSWORD="${!PASSWORD_VAR}"
REALM="${REALM:-provider/default-idp-2}"

curl -k -X POST "${APIM_BASE_URL}/api/token" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"username\": \"${USERNAME}\",
    \"password\": \"${PASSWORD}\",
    \"realm\": \"${REALM}\",
    \"client_id\": \"599b7aef-8841-4ee2-88a0-84d49c4d6ff2\",
    \"client_secret\": \"0ea28423-e73b-47d4-b40e-ddb45c48bb0c\",
    \"grant_type\": \"password\"
  }"
```

**Option B — API Key:**

```bash
API_KEY_VAR="${API_KEY_ENV_VAR:-APIM_API_KEY}"
API_KEY="${!API_KEY_VAR}"

curl -k -X POST "${APIM_BASE_URL}/api/token" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"api_key\": \"${API_KEY}\",
    \"client_id\": \"599b7aef-8841-4ee2-88a0-84d49c4d6ff2\",
    \"client_secret\": \"0ea28423-e73b-47d4-b40e-ddb45c48bb0c\",
    \"grant_type\": \"api_key\"
  }"
```

Extract `access_token` from the response. **Never log, display, or output the token.**

---

## Step F3: Select Organization

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

- If exactly one org is returned, auto-select it.
- If multiple, present them (show `name` / `title`) and ask the user to select.
- Store the `id` of the selected org as `ORG_ID`.

---

## Step F4: Select Catalog

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs/${ORG_ID}/catalogs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

- Present all catalogs (show `name` / `title`).
- If only one, auto-select.
- Store the `id` of the selected catalog as `CATALOG_ID`.

---

## Step F5: Fetch Gateway Services

```bash
curl -k -X GET "${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/configured-gateway-services" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

Apply the Gateway Matching Rule from the main skill:
- Filter by `gateway_service_type` matching the project type (`datapower-nano-gateway` or `wm-api-gateway`).
- Only consider services in `ready` state.
- One match → auto-select. Multiple → ask. None → **HARD STOP**.
- Store `GATEWAY_SERVICE` = the `gateway_service_type` (e.g. `datapower-nano-gateway`).

---

## Step F6: Select Space (Optional)

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs/${ORG_ID}/catalogs/${CATALOG_ID}/spaces" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

- No spaces → proceed to catalog-level publish.
- Spaces present → offer them (show `name` / `title`) plus "None (publish to catalog level)".
- Store the `id` of the selected space as `SPACE_ID`.

---

## Step F7: Configure Optional Publish Settings

Only prompt if the user asks or wants to change defaults:

| Query parameter | Description | Default |
|----------------|-------------|---------|
| `skip_portal_services` | Skip portal service configuration | `false` |
| `migrate_subscriptions` | Preserve existing subscriptions when republishing | `true` |
| `visibility` (form field) | `public` / `authenticated` / `custom` | project default |

---

## Step F8: Publish

**Publish to Catalog (no space):**

```bash
curl -k -X POST \
  "${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}&migrate_subscriptions=true" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip"
```

**Publish to Space:**

```bash
curl -k -X POST \
  "${APIM_BASE_URL}/api/spaces/${ORG_ID}/${CATALOG_ID}/${SPACE_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}&migrate_subscriptions=true" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip"
```

Append optional params as needed: `&skip_portal_services=true`. Add `-F "visibility=public"` if overriding visibility.

On success (200/201), display the published API names and gateway URLs.
On 401 → re-authenticate (Step F2) and retry once.
