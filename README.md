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

⚠️ **IMPORTANT: Rate Limits** - The free API tier allows **100 requests/day**. See [Rate Limiting](#rate-limiting) below.

### Recommended: Run Core Tests Only (Safe for Daily Use)
```bash
npm run test:core
```
This runs ~36 tests while avoiding rate-limited tests. **Safe for daily development.**

### Run All Tests (⚠️ Uses 100+ API requests)
```bash
npm test
```

### Run Specific Test Suites
```bash
# Core tests only (excludes rate-limited tests)
npm run test:core

# Functional tests only (excludes security tests)
npm run test:functional

# Security tests only
npm run test:security

# All rate-limited tests
npm run test:rate-limited

# All non-skipped tests
npm run test:all
```

### Run with Tags (Advanced)
```bash
# Run all tests except those requiring API key
npm test -- --tags "not @skip"

# Run only localisation tests
npm test -- --tags "@localization"

# Run only known bug tests
npm test -- --tags "@bug"

# Run all tests except rate-limited and skipped
npm test -- --tags "not @rate_limited and not @skip"
```

## Test Execution Results

### Full Test Suite (After Consolidation)
```
~46 scenarios (46 passed)
~180 steps (180 passed)
~75-85 API calls
```

### Core Tests Only (Recommended for Daily Use)
```bash
npm run test:core
```
```
~36 scenarios (36 passed)
~140 steps (140 passed)
~50-60 API calls
```

> **Note:** Test counts are approximate due to Scenario Outlines which expand based on examples. The full suite now stays comfortably within the 100 requests/day limit.

### Consolidation Benefits
- **13 fewer scenarios** while maintaining identical coverage
- **Stays within rate limits** - ~75-85 API calls instead of 100+
- **More maintainable** - Related tests grouped with Scenario Outlines
- See [TEST_CONSOLIDATION.md](./TEST_CONSOLIDATION.md) for details

## Test Coverage

The test suite is organized into **Functional Testing** and **Security Testing** sections for better maintainability.

### Functional Testing

#### 1. Basic Functionality (6 scenarios)
- Common names, lowercase, UPPERCASE
- Multiple name examples (John, Maria, Wei, Mohammed)
- Uncommon/rare names
- Response structure validation

#### 2. Input Validation & Edge Cases (9 scenarios)
- Missing/empty name parameter
- Single character names
- Very long names (52+ characters)
- Numeric characters (Test123)
- Special characters (@!£$%^&)
- Whitespace variations (leading, trailing, multiple, only spaces)
- Invalid UTF-8 byte sequences (@bug)

#### 3. Character Encoding & Internationalization (1 scenario outline, 4 examples)
- Accented characters (José)
- Umlauts (Müller)
- Cyrillic (Дмитрий)
- Chinese (李明)

#### 4. Name Parsing & Formatting (5 scenarios)
- Hyphenated names (Jean-Pierre)
- Apostrophes (O'Brien, D'Angelo)
- Full names (first and last)
- Multi-part names (Maria Elena Garcia)

#### 5. Localization & Country-Specific Predictions (7 scenarios) @localization
- Country codes (US, GB, AU, CA)
- Invalid country codes
- Case-insensitive country codes
- Localized vs non-localized predictions

#### 6. Batch Requests (7 scenarios)
- Multiple names (3 names)
- Up to 10 names (@rate_limited)
- 11 names - exceeds limit (@rate_limited)
- Duplicate names (@rate_limited)
- Batch with country localization

#### 7. Performance & Reliability (3 scenarios)
- Response time < 2000ms
- Count field validation
- Consistency/idempotency

### Security Testing

#### 1. Injection Attacks (2 scenario outlines, 6 examples) @security @rate_limited
- SQL injection (2 examples)
- XSS attempts (2 examples)
- Command injection (1 example)
- Path traversal (1 example)

#### 2. Parameter Manipulation (2 scenarios) @parameter_validation
- Duplicate parameters (@rate_limited)
- Case-sensitive parameter names

#### 3. Authentication & Authorization (7 scenarios) @skip
- Valid/invalid API keys
- Expired subscriptions
- Rate limiting
- Rate limit headers

### Non-Functional Tests
- Response time validation (< 2000ms)
- Consistency of results for repeated requests
- Response structure validation

### Test Organization

Tests are organized into two main sections:

**FUNCTIONAL TESTING** - Verifies API features work correctly:
1. Basic Functionality
2. Input Validation & Edge Cases
3. Character Encoding & Internationalization
4. Name Parsing & Formatting
5. Localization & Country-Specific Predictions
6. Batch Requests
7. Performance & Reliability

**SECURITY TESTING** - Verifies API handles malicious input safely:
1. Injection Attacks (SQL, XSS, Command, Path Traversal)
2. Parameter Manipulation & Validation
3. Authentication & Authorization

This organization makes it easy to:
- Run only functional tests: `npm test -- --tags "not @security and not @skip"`
- Run only security tests: `npm run test:security`
- Navigate and maintain the test suite

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
2. Specifically using: `?name=test%C0%C1%FF`
   - `%C0` - Invalid UTF-8 start byte (overlong encoding)
   - `%C1` - Invalid UTF-8 start byte (overlong encoding)  
   - `%FF` - Never valid in UTF-8
3. Observe the HTTP status code in the response

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

⚠️ **CRITICAL:** The Agify.io API has strict rate limits:
- **Free tier:** 100 requests per day
- **Full test suite (after consolidation):** ~75-85 requests ✅
- **Core test suite:** ~50-60 requests ✅

### Test Consolidation

The test suite has been optimized to stay within rate limits by consolidating similar tests:
- **International characters:** 4 tests → 1 Scenario Outline (4 examples)
- **Whitespace handling:** 5 tests → 1 Scenario Outline (5 examples)
- **Security tests:** 6 tests → 2 Scenario Outlines (6 examples total)
- **Single character names:** 2 tests → 1 test
- **Apostrophes:** 2 tests → 1 Scenario Outline (2 examples)

**Total saved:** 13 API calls while maintaining identical coverage.

See [TEST_CONSOLIDATION.md](./TEST_CONSOLIDATION.md) for full details.

### Managing Rate Limits

**For Daily Development (Recommended):**
```bash
npm run test:core  # Runs ~36 tests, excludes rate-limited tests
```

**When You Hit Rate Limits:**
- You'll see **429 (Too Many Requests)** errors
- Wait 24 hours for quota reset
- Or use a paid API key for higher limits

**Test Organization:**
- Tests likely to hit limits are tagged with `@rate_limited`
- These include: batch tests, security tests, parameter validation
- Run them selectively when you have quota available

**Available Test Commands:**
| Command | Scenarios | API Calls | Frequency |
|---------|-----------|-----------|----------|
| `npm run test:core` | ~36 | ~50-60 | Daily ✅ |
| `npm run test:security` | 2 | ~6 | Weekly |
| `npm run test:rate-limited` | ~10 | ~15 | As needed |
| `npm test` | ~46 | ~75-85 | Anytime ✅ |

### Using an API Key

With a paid API key, you get higher rate limits:

```bash
# Set API key
export AGIFY_API_KEY="your_key"  # Linux/Mac
$env:AGIFY_API_KEY="your_key"   # Windows PowerShell

# Run full suite
npm run test:all
```

For detailed rate limit management strategies, see [RATE_LIMIT_MANAGEMENT.md](./RATE_LIMIT_MANAGEMENT.md)

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

## Additional Documentation

For detailed information on specific topics, see these guides:

### Test Suite Organization & Strategy
- **[TEST_REORGANIZATION.md](./TEST_REORGANIZATION.md)** - Complete guide to the functional/security test structure
- **[TEST_CONSOLIDATION.md](./TEST_CONSOLIDATION.md)** - How we reduced from 59 to 46 scenarios while maintaining coverage
- **[TEST_NAMING_REVIEW.md](./TEST_NAMING_REVIEW.md)** - Review of test naming conventions and improvements

### Operational Guides  
- **[RATE_LIMIT_MANAGEMENT.md](./RATE_LIMIT_MANAGEMENT.md)** - Comprehensive guide to managing API rate limits
- **[SECURITY_TEST_FINDINGS.md](./SECURITY_TEST_FINDINGS.md)** - Security test results and API security assessment
- **[HIGH_PRIORITY_TEST_ADDITIONS.md](./HIGH_PRIORITY_TEST_ADDITIONS.md)** - Summary of high-priority tests added to the suite

### Quick Reference
| Document | Purpose |
|----------|----------|
| TEST_REORGANIZATION.md | Understanding test structure |
| TEST_CONSOLIDATION.md | How consolidation works |
| RATE_LIMIT_MANAGEMENT.md | Managing daily API quota |
| SECURITY_TEST_FINDINGS.md | Security assessment results |
| TEST_NAMING_REVIEW.md | Test naming best practices |
| HIGH_PRIORITY_TEST_ADDITIONS.md | What high-priority tests cover |

## Notes

- Tests validate API functionality, not data accuracy (as per requirements)
- All tests are API-based, no UI/browser testing
- Written in TypeScript using Cucumber BDD framework
