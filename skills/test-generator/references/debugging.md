# Test Failure Debugging

Use this reference whenever `apic test` produces a failure. Work through the decision tree below **before** proposing any YAML change.

## Step 1 — Read the raw output

The `apic test` CLI output has three possible shapes:

```
# Shape A — per-assertion detail (most common)
✗  POST /pet  →  201-created
   FAILED: Validate response status code
     expected: 200  (integer)
     actual:   201
   PASSED: Validate content type

# Shape B — execution error (no assertions ran)
Error: connect ECONNREFUSED 127.0.0.1:9090

# Shape C — HTTP error from backend (assertions may or may not run)
HTTP 500 Internal Server Error
```

If the output is **entirely empty or unparseable**, do not guess. Ask the user to paste the raw CLI output before doing anything else.

---

## Step 2 — Classify the failure

Work through this tree in order. Stop at the first match.

### Class 1 — Connection / Network failure
**Indicators:** `ECONNREFUSED`, `ETIMEDOUT`, `ENOTFOUND`, `getaddrinfo`, `connection refused`, `read timeout`

**What it means:** The test runner could not reach the endpoint at all. No assertions ran.

**Action:**
- Do **not** edit any YAML file.
- Report the error to the user verbatim.
- Ask: _"The connection failed — please verify that the API is deployed and reachable at `<endpoint>`. Is the gateway running?"_
- If after the user confirms the gateway is up the error persists, ask them to run `curl -v <endpoint>` and share the output.

---

### Class 2 — Backend server error
**Indicators:** HTTP `5xx` response code in the output (500, 502, 503, 504)

**What it means:** The gateway or backend returned an error. The API is reachable but broken server-side.

**Action:**
- Do **not** edit any YAML file.
- Report the 5xx status to the user.
- Ask: _"The API returned a `<5xx>` — this is a server-side error, not an assertion problem. Please check the backend logs."_
- Only revisit assertion files if the user confirms the backend is healthy and the 5xx is unexpected.

---

### Class 3 — Authentication failure
**Indicators:** HTTP `401 Unauthorized` or `403 Forbidden` in the output

**What it means:** A credential is missing, expired, or wrong. This can be a bearer token, an API key, or a client ID/secret pair (for APIs with `extract-identity`, `authenticate`, or `authorize` policies).

**Action:**
- Do **not** edit assertion files.
- Check which auth mechanism the project uses, then ask accordingly:
  - **Bearer token / API key:** _"The API returned `<401/403>` — please verify the token you passed with `--env bearer_token=<value>` is valid and has not expired."_
  - **Client credentials (Extract Identity / Authenticate / Authorize / IAM):** _"The API returned `<401/403>` — please verify the `client_id` you passed is correct (visible in API Manager under your application). Note: the `client_secret` is shown only once at application creation and cannot be retrieved from the UI — please check the value you have saved."_
- If the user confirms credentials are correct but still seeing 401/403, check:
  - Bearer auth: the Authorization header in the test file uses `Bearer ${bearer_token}` (not a hardcoded value).
  - Client credentials: the test file includes both `X-IBM-Client-Id: ${client_id}` and `X-IBM-Client-Secret: ${client_secret}` headers on every request.

---

### Class 4 — Assertion value mismatch
**Indicators:** Output shows `FAILED: <assertion name>` with an `expected` vs `actual` diff

**What it means:** The test ran successfully, but the response did not match what the assertion expected. This is a generated-file bug.

**How to identify which file:** The failing assertion name matches an entry in one of the `tests/assertions/` files. Cross-reference the assertion name to the file.

**Common sub-cases:**

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `expected: 200 (string)` vs `actual: 200 (integer)` | `responseStatus` value was quoted | Remove quotes: `value: 200` |
| `expected: 201` vs `actual: 200` | Wrong status code in assertion | Update `value:` to match the actual status the API returns |
| `expected: application/json` vs `actual: application/json; charset=utf-8` | Content-type includes charset | Change `action: equals` to `action: include` |
| `haveProperty` fails on a field that exists | Property path is embedded in `key` instead of `value` | Move property name to `value:`, keep parent path in `key:` |
| Schema validation fails | Schema in assertion is out of sync with spec | Re-extract schema from `components.schemas` in the OpenAPI spec |

**Action:**
- Identify the specific assertion file and assertion name.
- Show the before/after YAML diff.
- Wait for user approval before saving.

---

### Class 5 — Reference resolution failure
**Indicators:** `Could not resolve ref`, `assertion not found`, `namespace:name:version not found`

**What it means:** A `$ref` in the test file points to an assertion or environment file that does not exist or has a different `namespace:name:version` than what is referenced.

**How to diagnose:**
```bash
# Check what $refs the test file uses
grep -n '\$ref' tests/<api-name>-test.yaml

# Check what assertion files actually exist
ls tests/assertions/

# Check the metadata of each assertion file
grep -n 'name:\|namespace:\|version:' tests/assertions/*.yml
```

**Action:**
- If the file exists but the `$ref` is wrong, correct the `$ref` in the test file (show diff, wait for approval).
- If the file does not exist, generate the missing assertion file.

---

### Class 6 — Unknown / mixed failures
**Indicators:** Multiple failure types in the same run, or output does not match any class above

**Action:**
- List each failing assertion separately.
- For each one, apply the classification above individually.
- If you cannot determine the class, quote the raw output line and ask the user what they expect the behaviour to be — do not guess.

---

## Quick reference — what not to do

| Situation | Wrong response | Correct response |
|-----------|---------------|-----------------|
| `ECONNREFUSED` | Edit `responseStatus` from `200` to `500` | Report connection failure, ask user to verify deployment |
| HTTP 500 from backend | Add a `500-server-error` assertion | Report server error, ask user to check backend logs |
| 401 Unauthorized | Edit assertion to expect 401 | Ask user to verify auth token |
| After 3 retries, still timing out | Keep retrying | Stop, report to user |
