# Agify.io API Test Suite

BDD test suite for the [agify.io](https://agify.io) API using Cucumber and TypeScript.

**Author:** Anton Hasselmyr
**Purpose:** Kaluza QA Engineer Technical Assessment

## Requirements

- Node.js v25.2.1
- npm v10.9.2

## Installation

```bash
npm install
```

## Running Tests

⚠️ **IMPORTANT:** The free API tier has a 100 requests/day limit.

### For Development & Daily Testing (Recommended)
```bash
# Run core tests - excludes rate-limited tests (~36 scenarios, ~50 API calls)
npm run test:core
```
**Use this for:** Daily development, practicing demo, verifying functionality

### For Complete Validation (Use When Fresh Quota Available)
```bash
# Run all tests - includes rate-limited security & batch tests (~46 scenarios, ~75-85 API calls)
npm test
```
**Use this for:** Final validation when you have 100 requests available

### Test Suites
```bash
npm run test:functional    # Functional tests only
npm run test:security      # Security tests only
npm run test:core          # Excludes rate-limited tests
npm run test:all           # All tests except @skip
```

### Filter by Tags
```bash
npm test -- --tags @localization
npm test -- --tags @security
npm test -- --tags "not @skip"
```

### Generate HTML Report
```bash
npm run test:report

# Report will be created at: reports/cucumber-report.html
# Open in browser to view detailed results
```

## Test Coverage

The test suite is organized into **Functional Testing** and **Security Testing** sections.

### Functional Testing (~37 scenarios)

**Basic Functionality**
- Common names (lowercase, UPPERCASE, multiple examples)
- Uncommon/rare names
- Response structure validation

**Input Validation & Edge Cases**
- Missing name parameter (422)
- Empty or whitespace-only name parameter (422)
- Single character names
- Very long names (52+ characters)
- Numeric and special characters
- Whitespace handling (leading, trailing, multiple)
- Invalid UTF-8 byte sequences

**Character Encoding**
- International characters (accented, umlauts, Cyrillic, Chinese)
- Name formatting (hyphens, apostrophes, full names)

**Localization**
- Country-specific predictions (US, GB, AU, CA)
- Invalid country codes
- Case-insensitive handling

**Batch Requests**
- Multiple names (3-10 names)
- Limit testing (11 names - exceeds documented limit)
- Duplicate name handling
- Batch with country localization

**Performance**
- Response time validation (< 2000ms)
- Consistency checks (idempotency)

### Security Testing (~9 scenarios)

**Injection Attacks**
- SQL injection (2 variations)
- XSS attacks (script tags, javascript protocol)
- Command injection
- Path traversal

**Parameter Validation**
- Duplicate parameters
- Case-sensitive parameter names

**Authentication** (@skip - requires API key)
- API key validation
- Rate limiting
- Expired subscriptions

## Issues Found

### CRITICAL: API Currently Unreachable
**Status:** Blocking - Tests cannot execute  
**Issue:** agify.io API is not responding to requests (connection timeout)  
**Impact:** All tests fail at runtime, preventing demonstration of test execution  

**Current Workaround:** Background connectivity check disabled  
**Recommended Fix:** 
- Wait for API to become available
- Implement mock responses for demo purposes
- Use local API stub server

**Test Results:** `npm run test:core` - 47 scenarios fail due to connectivity  
**Last Verified:** API unreachable from current environment

### BUG: Invalid UTF-8 Returns Wrong Status Code

**Severity:** Medium  
**Issue:** API returns `400` instead of documented `422` for invalid UTF-8 bytes

**Test:**
```
Scenario: Request with invalid UTF-8 byte sequences
  When I request name "test%C0%C1%FF"
  Then status should be 422  # Documented behavior
  # Actual: 400 (contract violation)
```

**Impact:** Clients relying on documented behavior may not handle this error correctly.

**Tagged with:** `@bug` for filtering during CI runs

### BUG: Empty or Whitespace-Only Name Returns 200

**Severity:** Medium  
**Issue:** API returns `200` for empty (`name=`) and whitespace-only (`name=   `) values, but documentation indicates invalid `name` should return `422`.

**Tests:**
```
Scenario: Request with empty name parameter
  When I request age prediction for name ""
  Then the response status should be 422

Scenario: Request with whitespace-only name parameter
  When I request age prediction for name "   "
  Then the response status should be 422
```

**Impact:** Clients relying on documented validation rules may not detect invalid input.

**Tagged with:** `@bug` for filtering during CI runs

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

## API Client Usage

```typescript
// Single name
await client.getAgePrediction('Michael');

// With country localization
await client.getAgePredictionWithCountry('Michael', 'US');

// Batch request
await client.getBatchAgePredictions(['Michael', 'Sarah', 'David']);
```

## Rate Limiting

**Free tier:** 100 requests per day  
**Test suite:** ~75-85 API calls for full suite

Tests are tagged with `@rate_limited` for flexible execution:
- Core tests exclude rate-limited tests for daily development
- Security tests are rate-limited (6 scenarios)
- Some batch tests are rate-limited (3 scenarios)

## Dependencies

- `@cucumber/cucumber` - BDD framework
- `axios` - HTTP client
- `typescript` - Type safety
- `ts-node` - TypeScript execution

## Notes

- Tests validate API functionality, not data accuracy
- Written in TypeScript using Cucumber BDD framework
- All tests are API-based (no UI/browser testing)
