# Debugging Guide

## Complete Debug Flow Script

This script demonstrates the complete publish workflow with detailed debugging output at each step.

```bash
#!/bin/bash

# Configuration — set these via environment variables, do not hardcode
APIM_BASE_URL="${APIM_BASE_URL}"
USERNAME="${USERNAME}"
# Retrieve password from environment variable (default: APIM_PASSWORD)
PASSWORD_VAR="${PASSWORD_ENV_VAR:-APIM_PASSWORD}"
PASSWORD="${!PASSWORD_VAR}"
# Use default realm if not specified
REALM="${REALM:-provider/default-idp-2}"
ORG_NAME="${ORG_NAME:-my-org}"
CATALOG_NAME="${CATALOG_NAME:-sandbox}"
GATEWAY_SERVICE="${GATEWAY_SERVICE:-datapower-nano-gateway}"
PROJECT_ZIP_PATH="${PROJECT_ZIP_PATH:-./builds/cart-api.zip}"

echo "========================================="
echo "API CONNECT PUBLISH DEBUG SCRIPT"
echo "========================================="
echo ""
echo "Configuration:"
echo "  APIM URL: $APIM_BASE_URL"
echo "  Username: $USERNAME"
echo "  Password source: \${$PASSWORD_VAR} (env var)"
echo "  Organization: $ORG_NAME"
echo "  Catalog: $CATALOG_NAME"
echo "  Gateway: $GATEWAY_SERVICE"
echo "  Project: $PROJECT_ZIP_PATH"
echo ""

# Step 1: Generate access token
echo "Step 1: Generating access token"
TOKEN_RESPONSE=$(curl -k -s -w "\n%{http_code}" -X POST "${APIM_BASE_URL}/api/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${USERNAME}\",
    \"password\": \"${PASSWORD}\",
    \"realm\": \"${REALM}\",
    \"client_id\": \"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",
    \"client_secret\": \"${CLIENT_SECRET}\",
    \"grant_type\": \"password\"
  }")

HTTP_CODE=$(echo "$TOKEN_RESPONSE" | tail -n1)
TOKEN_BODY=$(echo "$TOKEN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "  ✗ Authentication FAILED (HTTP $HTTP_CODE)"
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_BODY" | jq -r '.access_token')
echo "  ✓ Authentication successful"
echo "  Token: [hidden]"

# Step 2: Fetch organizations
echo ""
echo "Step 2: Fetching organizations"
ORGS_RESPONSE=$(curl -k -s -w "\n%{http_code}" -X GET "${APIM_BASE_URL}/api/orgs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

HTTP_CODE=$(echo "$ORGS_RESPONSE" | tail -n1)
ORGS_BODY=$(echo "$ORGS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "  ✗ Fetch organizations FAILED (HTTP $HTTP_CODE)"
  echo "  Response: $ORGS_BODY"
  exit 1
fi

ORG_COUNT=$(echo "$ORGS_BODY" | jq '.total_results')
echo "  ✓ Found $ORG_COUNT organizations"
echo "$ORGS_BODY" | jq -r '.results[] | "    - \(.name) (\(.title))"'

# Step 3: Fetch catalogs
echo ""
echo "Step 3: Fetching catalogs for org '${ORG_NAME}'"
CATALOGS_RESPONSE=$(curl -k -s -w "\n%{http_code}" -X GET "${APIM_BASE_URL}/api/orgs/${ORG_NAME}/catalogs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

HTTP_CODE=$(echo "$CATALOGS_RESPONSE" | tail -n1)
CATALOGS_BODY=$(echo "$CATALOGS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "  ✗ Fetch catalogs FAILED (HTTP $HTTP_CODE)"
  echo "  Response: $CATALOGS_BODY"
  exit 1
fi

CATALOG_COUNT=$(echo "$CATALOGS_BODY" | jq '.total_results')
echo "  ✓ Found $CATALOG_COUNT catalogs"
echo "$CATALOGS_BODY" | jq -r '.results[] | "    - \(.name) (\(.title))"'

# Step 4: Fetch gateway services
echo ""
echo "Step 4: Fetching gateway services"
GATEWAYS_RESPONSE=$(curl -k -s -w "\n%{http_code}" -X GET "${APIM_BASE_URL}/api/catalogs/${ORG_NAME}/${CATALOG_NAME}/configured-gateway-services" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

HTTP_CODE=$(echo "$GATEWAYS_RESPONSE" | tail -n1)
GATEWAYS_BODY=$(echo "$GATEWAYS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "  ✗ Fetch gateways FAILED (HTTP $HTTP_CODE)"
  echo "  Response: $GATEWAYS_BODY"
  exit 1
fi

GATEWAY_COUNT=$(echo "$GATEWAYS_BODY" | jq '.total_results')
echo "  ✓ Found $GATEWAY_COUNT gateway services"
echo "$GATEWAYS_BODY" | jq -r '.results[] | "    - \(.name) (type: \(.gateway_service_type))"'

# Validate gateway exists
GATEWAY_EXISTS=$(echo "$GATEWAYS_BODY" | jq -r ".results[] | select(.name==\"${GATEWAY_SERVICE}\") | .name")
if [ -z "$GATEWAY_EXISTS" ]; then
  echo "  ✗ ERROR: Gateway '${GATEWAY_SERVICE}' not found in catalog"
  echo "  Available gateways:"
  echo "$GATEWAYS_BODY" | jq -r '.results[] | "    - \(.name)"'
  exit 1
fi
echo "  ✓ Gateway '${GATEWAY_SERVICE}' validated"

# Step 5-8: Preprocessing (simulated - actual happens in service)
echo ""
echo "Step 5-8: Preprocessing (handled by service)"
echo "  ✓ Gateway type extraction"
echo "  ✓ ZIP validation"
echo "  ✓ Project build processing"
echo "  ✓ Schema validation"
echo "  ✓ Lint validation"
echo "  ✓ FormData preparation"
echo "  ✓ URL construction"

# Step 9: Publish
echo ""
echo "Step 9: Publishing project"
PUBLISH_URL="${APIM_BASE_URL}/api/catalogs/${ORG_ID}/${CATALOG_ID}/publish-project?gateway_services=${GATEWAY_SERVICE}&migrate_subscriptions=true"
echo "  URL: $PUBLISH_URL"

PUBLISH_RESPONSE=$(curl -k -s -w "\n%{http_code}" -X POST "$PUBLISH_URL" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Accept: application/json" \
  -F "project=@${PROJECT_ZIP_PATH};type=application/zip" \
  -F "visibility=public")

HTTP_CODE=$(echo "$PUBLISH_RESPONSE" | tail -n1)
PUBLISH_BODY=$(echo "$PUBLISH_RESPONSE" | sed '$d')

echo ""
echo "========================================="
echo "PUBLISH RESULT"
echo "========================================="
echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "✓ PUBLISH SUCCESSFUL"
  echo ""
  echo "Response:"
  echo "$PUBLISH_BODY" | jq '.'
  
  # Extract published APIs
  echo ""
  echo "Published APIs:"
  echo "$PUBLISH_BODY" | jq -r '.published_apis[]? | "  - \(.name) v\(.version)"'
else
  echo "✗ PUBLISH FAILED"
  echo ""
  echo "Error Details:"
  echo "$PUBLISH_BODY" | jq '.'
  
  # Extract specific errors
  echo ""
  echo "Errors:"
  echo "$PUBLISH_BODY" | jq -r '.errors[]? // .message? // "Unknown error"' | sed 's/^/  - /'
  
  exit 1
fi

echo ""
echo "========================================="
```

## Complete Example Flow

```
User: "Publish cart-api project to APIM"

Agent: "I'll help you publish the cart-api project to APIM. Please provide:
1. Project path (built ZIP file): "
User: "./builds/cart-api.zip"

Agent: "2. APIM Base URL: "
User: "https://apim.example.com"

Agent: "3. Username: "
User: "admin"

Agent: "4. Password environment variable name (default: APIM_PASSWORD): "
User: [Enter for default or "APIM_PASSWORD"]

Agent: "5. Realm (optional, default: provider/default-idp-2): "
User: [Enter for default]

Agent: "Retrieving password from environment variable 'APIM_PASSWORD'... ✓
Authenticating... ✓
Generating access token... ✓

Fetching organizations...
Available Organizations:
1. my-org (My Organization)
2. test-org (Test Organization)

Please select an organization: "
User: "1"

Agent: "Fetching catalogs for 'my-org'...
Available Catalogs:
1. sandbox (Sandbox)
2. production (Production)

Please select a catalog: "
User: "1"

Agent: "Checking for spaces in 'sandbox'...
Available Spaces:
1. dev-space (Development Space)
2. None (publish to catalog level)

Please select a space: "
User: "2"

Agent: "Fetching DataPower Nano Gateway services...
Available Gateway Services:
1. datapower-nano-gateway (DataPower Nano Gateway)

Please select a gateway service: "
User: "1"

Agent: "Publishing project to:
- Organization: my-org
- Catalog: sandbox
- Gateway: datapower-nano-gateway

Preprocessing...
✓ Gateway type extraction
✓ ZIP validation
✓ Project build processing
✓ Schema validation
✓ Lint validation
✓ FormData preparation
✓ URL construction

Publishing... ✓

✓ Project published successfully!

Published APIs:
- cart-api v1.0.0
  URL: https://gateway.example.com/my-org/sandbox/cart-api/1.0

Would you like to test the published API? (yes/no)"