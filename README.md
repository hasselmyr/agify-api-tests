# Agify.io API Test Suite

BDD test suite for the [agify.io](https://agify.io) API using Cucumber and TypeScript.

**Author:** Anton  
**Purpose:** Kaluza QA Engineer Technical Assessment

## Requirements

- Node.js v25.2.1
- npm v10.9.2

## Installation

```bash
npm install
```

## Running Tests

```bash
npm test
```

### Run with Tags

```bash
# Run all tests except those requiring API key
npm test -- --tags "not @skip"

# Run only localisation tests
npm test -- --tags "@localization"

# Run only known bug tests
npm test -- --tags "@bug"

# Run all tests except known bugs
npm test -- --tags "not @bug and not @skip"
```

## Test Execution Results

### All Tests
```
38 scenarios (1 failed, 37 passed)
167 steps (1 failed, 1 skipped, 165 passed)
0m08.732s
```

### Excluding Known Bugs (`--tags "not @bug and not @skip"`)
```
37 scenarios (37 passed)
163 steps (163 passed)
```

> **Note:** The single failing test is intentional — it documents a bug where the API behaviour does not match the documented contract. See [Issues Found](#issues-found) for details.

## Test Coverage

### Functional Tests
| Category | Scenarios | Description |
|----------|-----------|-------------|
| Basic Requests | 8 | Common names, lowercase, response structure |
| Internationalisation | 6 | Accented characters, umlauts, Cyrillic, Chinese |
| Name Parsing | 4 | Hyphenated, full names, multi-part names |
| Edge Cases | 5 | Empty name, very long names, numeric characters, rare names |
| Batch Requests | 6 | Multiple names, up to 10 names, with localisation |
| Localisation | 6 | Country codes, invalid codes, case sensitivity |
| Error Handling | 3 | Missing parameter (422), invalid parameter (422) |

### Non-Functional Tests
- Response time validation (< 2000ms)
- Consistency of results for repeated requests
- Response structure validation

### Authentication Tests (@skip)
These tests require an API key and are skipped by default:
- Valid/invalid API key handling (401)
- Expired subscription (402)
- Rate limiting (429)
- Rate limit headers

## Error Code Coverage

| Code | Description | Status |
|------|-------------|--------|
| 200 | Success | ✅ Tested |
| 401 | Invalid API key | ✅ Tested (@skip) |
| 402 | Subscription inactive | ✅ Tested (@skip) |
| 422 | Missing 'name' parameter | ✅ Tested |
| 422 | Invalid 'name' parameter | ⚠️ **API Bug** (see below) |
| 429 | Request limit reached | ✅ Tested (@skip) |
| 429 | Batch limit too low | ✅ Tested (@skip) |

## Issues Found

### BUG-001: Invalid Name Parameter Returns Wrong HTTP Status Code

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **Endpoint** | `GET https://api.agify.io?name=<invalid_utf8>` |
| **Documentation** | https://agify.io/documentation#responses |
| **Tag** | `@bug` |

**Steps to Reproduce:**
1. Send a GET request to `https://api.agify.io` with invalid UTF-8 bytes in the name parameter
2. Observe the HTTP status code in the response

**Expected Result (per documentation):**
```
HTTP/1.1 422 Unprocessable Content
{ "error": "Invalid 'name' parameter" }
```

**Actual Result:**
```
HTTP/1.1 400 Bad Request
{ "error": "Invalid 'name' parameter" }
```

**Analysis:**
- The error message is correct, but the HTTP status code violates the documented API contract
- Clients implementing error handling based on the documentation would not catch this error correctly
- This is a contract violation that could cause integration issues

**Test Approach:**
- Test is written to expect the **documented behaviour** (422)
- Test intentionally fails to flag this as a regression/bug
- Tagged with `@bug` so it can be filtered during CI runs if needed

**Recommendation:**
Report to agify.io team requesting either:
1. Update the API to return 422 as documented, or
2. Update the documentation to reflect the actual 400 response

### Observation: Empty Name Parameter Behaviour

**Request:** `GET https://api.agify.io?name=`

**Expected:** Based on the "Missing 'name' parameter" error, one might expect an error for empty strings.

**Actual:** Returns 200 with a valid response structure (empty name is treated as valid input).

**Impact:** This is not necessarily a bug, but the behaviour is undocumented. The API accepts empty strings as valid input.

## Project Structure

```
agify-api-tests/
├── features/
│   ├── agify.feature          # BDD scenarios
│   └── support/
│       ├── steps/
│       │   └── agify.steps.ts # Step definitions
│       └── world.ts           # Test context
├── src/
│   └── api/
│       └── agifyClient.ts     # API client
├── package.json
├── tsconfig.json
└── README.md
```

## API Client

The `AgifyClient` class provides methods for all API operations:

```typescript
// Single name
await client.getAgePrediction('Michael');

// With country localisation
await client.getAgePredictionWithCountry('Michael', 'US');

// Batch request
await client.getBatchAgePredictions(['Michael', 'Sarah', 'David']);

// With authentication
await client.getAgePredictionWithAuth('Michael', apiKey);
```

## Rate Limiting

The free tier allows 100 requests/day. Tests are organised with tags to manage this:

- Run `npm test -- --tags "not @skip"` to stay within limits (~31 requests)
- Use an API key for unlimited testing

## Running Authentication Tests

```bash
# Set API key
export AGIFY_API_KEY="your_key"  # Linux/Mac
$env:AGIFY_API_KEY="your_key"   # Windows PowerShell

# Run auth tests
npm test -- --tags "@skip"
```

## Dependencies

- `@cucumber/cucumber` - BDD framework
- `axios` - HTTP client
- `typescript` - Type safety
- `ts-node` - TypeScript execution

## Notes

- Tests validate API functionality, not data accuracy (as per requirements)
- All tests are API-based, no UI/browser testing
- Written in TypeScript using Cucumber BDD framework
