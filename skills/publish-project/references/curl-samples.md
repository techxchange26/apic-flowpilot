# curl Samples Reference

Standalone curl examples used by the no-MCP fallback workflow and for manual debugging.

> **IDs only in URL paths.** All API endpoints require the numeric or UUID ID for org, catalog, and space — not the slug/name. After listing resources, store the `id` field from each response object.

> **`gateway_services=`** always takes the **`gateway_service_type`** value (e.g. `datapower-nano-gateway`, `wm-api-gateway`) — not the service instance name or human-readable title.

---

## API Endpoints

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Generate Token (password) | POST | `/api/token` |
| Generate Token (api_key) | POST | `/api/token` |
| List Organizations | GET | `/api/orgs` |
| List Catalogs | GET | `/api/orgs/{orgId}/catalogs` |
| List Gateway Services (Catalog) | GET | `/api/catalogs/{orgId}/{catalogId}/configured-gateway-services` |
| List Gateway Services (Space) | GET | `/api/spaces/{orgId}/{catalogId}/{spaceId}/configured-gateway-services` |
| List Spaces | GET | `/api/orgs/{orgId}/catalogs/{catalogId}/spaces` |
| Publish to Catalog | POST | `/api/catalogs/{orgId}/{catalogId}/publish-project?gateway_services={type}` |
| Publish to Space | POST | `/api/spaces/{orgId}/{catalogId}/{spaceId}/publish-project?gateway_services={type}` |

---

## Authentication

### Token — Username / Password

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

### Token — API Key

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

Extract `access_token` from the JSON response. **Never log or display the token value.**

---

## Discovery

### List Organizations

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

Store the `id` of the selected org as `ORG_ID`.

### List Catalogs

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs/${ORG_ID}/catalogs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

Store the `id` of the selected catalog as `CATALOG_ID`.

### List Gateway Services (Catalog level)

```bash
curl -k -X GET "${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/configured-gateway-services" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

Filter by `gateway_service_type` matching the project type. Store the type as `GATEWAY_SERVICE`.

### List Gateway Services (Space level)

```bash
curl -k -X GET "${APIM_BASE_URL}/api/spaces/${ORG_ID}/${CATALOG_ID}/${SPACE_ID}/configured-gateway-services" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

### List Spaces

```bash
curl -k -X GET "${APIM_BASE_URL}/api/orgs/${ORG_ID}/catalogs/${CATALOG_ID}/spaces" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json"
```

Store the `id` of the selected space as `SPACE_ID`.

---

## Publishing

### Publish to Catalog

```bash
# gateway_services= takes gateway_service_type, e.g. datapower-nano-gateway or wm-api-gateway
curl -k -X POST \
  "${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip"
```

### Publish to Catalog with optional parameters

```bash
curl -k -X POST \
  "${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}&skip_portal_services=true&migrate_subscriptions=true" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip" \
  -F "visibility=public"
```

### Publish to Space

```bash
curl -k -X POST \
  "${APIM_BASE_URL}/api/spaces/${ORG_ID}/${CATALOG_ID}/${SPACE_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip"
```

---

## Notes

- All URL path segments use IDs (not names/slugs) — extract the `id` field from each list response
- Password and API key are always read from environment variables — never entered directly
- `ACCESS_TOKEN` expires after ~1 hour; re-run the token call if you get a 401
- Use `-k` only for self-signed certificates in development environments
- `gateway_services=` takes the `gateway_service_type` value (`datapower-nano-gateway` or `wm-api-gateway`), not the service instance name
- Content-Type for the publish body is `multipart/form-data` — use `-F` with `type=application/zip`
- Spaces are optional — you can publish to catalog level or space level
- Auto-selection only applies when exactly one option is available
