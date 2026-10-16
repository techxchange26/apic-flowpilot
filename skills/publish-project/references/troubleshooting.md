# Troubleshooting Guide

## Common Issues and Solutions

### Issue: "Invalid credentials"
**Solution**: Verify username, realm, and the environment variable holding the password are correct (check `PASSWORD_ENV_VAR`, default `APIM_PASSWORD`). Check if user account is active.

### Issue: "User does not have 'Manage APIs' privilege"
**Solution**: Contact APIM administrator to grant "Manage APIs" privilege to the user.

### Issue: "Gateway service not found"
**Solution**: Verify gateway service exists in the target catalog. Check gateway service name spelling.

### Issue: "Project package is invalid"
**Solution**: Ensure project is built successfully. Verify ZIP file is not corrupted.

### Issue: "Connection refused"
**Solution**: Verify APIM URL is correct and accessible. Check network connectivity and firewall rules.

### Issue: "Token expired"
**Solution**: Re-authenticate to generate a new access token.

### Issue: "ZIP validation failed"
**Solution**: Check that the project ZIP contains all required files including gateways.json. Rebuild the project if necessary.

### Issue: "Schema validation failed"
**Solution**: Review the schema validation errors and fix the OpenAPI/AsyncAPI specifications in your project. Common issues include missing required fields, invalid data types, or incorrect references.

### Issue: "Lint validation failed"
**Solution**: Review the linting errors and warnings. Fix critical errors in your API specifications. Warnings can often be ignored but should be addressed for best practices.

### Issue: TLS client profile not found / TLS client profile mismatch

**Symptoms**: The publish call fails with an error referencing a TLS client profile — for example:
- `tls-client-profile not found`
- `tls-client-profile mismatch`
- `TLS client profile '<name>' does not exist`
- `Invalid TLS client profile`

**Cause**: The catalog has not been configured with a TLS client profile, or the profile referenced in the project does not match the one configured in the catalog settings.

**Solution**: Ask the user to configure the TLS client profile in the API Manager:

1. Log in to the **API Manager**.
2. In the left navigation, click **Manage**.
3. Open the target **Catalog**.
4. Go to **Catalog Settings** → **TLS Client Profile**.
5. Select or create a TLS client profile that matches what the project expects, then save.
6. Once configured, retry the publish.

> **Tell the user:** _"The publish failed because a TLS client profile is missing or mismatched for this catalog. Please go to API Manager → Manage → [your catalog] → Catalog Settings → TLS Client Profile and configure the correct profile, then retry."_

## Error Handling Best Practices

1. **Validate Early**: Check project file exists before starting workflow
2. **Clear Messages**: Provide specific error messages with actionable fixes
3. **Retry Logic**: Implement retry for transient network failures
4. **Token Refresh**: Handle token expiration gracefully (re-authenticate)
5. **User Guidance**: Offer step-by-step guidance for fixing common errors
6. **Logging**: Log all API calls and responses for troubleshooting
7. **Preprocessing Validation**: Show detailed output for each preprocessing step
8. **Debug Mode**: Enable verbose logging to track each step of the publish process

## Security Considerations

1. **Credential Handling**: Never log, display, or output passwords anywhere — not in the chat response, not in debug output. Always read the password from an environment variable (`PASSWORD_ENV_VAR`, defaulting to `APIM_PASSWORD`); never prompt the user to enter a password directly.
2. **Token Handling**: Never log, display, or output access tokens or bearer tokens anywhere — not in the chat response, not in debug output. Store tokens in memory only and reference them via `${ACCESS_TOKEN}`.
3. **HTTPS Only**: Always use HTTPS for APIM communications
4. **Token Expiration**: Tokens typically expire after 1 hour
5. **Least Privilege**: Ensure user has only necessary permissions