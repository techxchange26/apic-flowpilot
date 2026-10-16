# wm_APIKey_Petstore

## Overview

This project contains a APIKey protected Petstore API with inovke and logging policy.

## Assets Included

This sample contains the following assets:

### API Definitions

- **PetstoreAPI_APIKey.yml** - API asset
- **PetstoreAPI-spec.json** - API specifications

### Policies

- **wM_PolicySequence.yml** - Policy asset of webMethods API Gateway
- **wM_Invoke.yml** - Invoke/Routing policy
- **wM_Log.yml** - Logging policy
- **wM_APIKey.yml** - IAM Policy

### Tests

- **Sanity_Test.yml** - Sanity test for the PetstoreAPI
- **Basic_Assertion.yml** - Default assertions checking the status code, message and response time.
- **Default_Environment.yml** - An environment file with a variable for referring API Key.

## Getting Started

1. Import the Sample
2. Publish to a catalog containing webMethods API Gateway
3. Go to Manage -> Catalog and create a consumer org, application and a subscription for the API.
4. The clientId of the application will be the APIKey for invoking this API
5. For validation, use Tryout or run the tests present under the tests fodler.
6. For Tryout, pass the APIKey in the header with the header name "x-Gateway-APIKey"
7. For executing the tests, replace the "apikey" variable value in the environment file under tests with the key from the created application.
